public import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// The Downshift protocol allows an Display to be shifted down by a given amount.
protocol DownShift {
    var shiftDown: CGFloat { get set }
}

// MARK: - Display

/// The base class for rendering a math equation.
public class Display: @unchecked Sendable {
    init() {}

    /// Draws itself in the given graphics context.
    public func draw(_ context: CGContext) {
        if localBackgroundColor != nil {
            context.saveGState()
            context.setBlendMode(.normal)
            context.setFillColor(localBackgroundColor!.cgColor)
            context.fill(displayBounds())
            context.restoreGState()
        }
    }

    /// Gets the bounding rectangle for the Display
    func displayBounds() -> CGRect {
        CGRect(
            x:
            position.x, y: position.y - descent, width: width,
            height: ascent + descent,
        )
    }

    /// The distance from the axis to the top of the display
    public var ascent: CGFloat = 0
    /// The distance from the axis to the bottom of the display
    public var descent: CGFloat = 0
    /// The width of the display
    public var width: CGFloat = 0
    /// Position of the display with respect to the parent view or display.
    var position = CGPoint.zero
    /// The range of characters supported by this item
    public var range = 0 ..< 0
    /// Whether the display has a subscript/superscript following it.
    public var hasScript: Bool = false
    /// The text color for this display
    var textColor: PlatformColor?
    /// The local color, if the color was mutated local with the color command
    var localTextColor: PlatformColor?
    /// The background color for this display
    var localBackgroundColor: PlatformColor?
}

/// Special class to be inherited from that implements the DownShift protocol
class DisplayDS: Display, DownShift {
    var shiftDown: CGFloat = 0
}

// MARK: - CTLineDisplay

/// A rendering of a single CTLine as an Display
public final class CTLineDisplay: Display {
    /// The CTLine being displayed
    public var line: CTLine!
    /// The attributed string used to generate the CTLineRef. Note setting this does not reset the dimensions of
    /// the display. So set only when
    var attributedString: NSAttributedString? {
        didSet {
            line = CTLineCreateWithAttributedString(attributedString!)
        }
    }

    /// An array of MathAtoms that this CTLine displays. Used for indexing back into the MathList
    public fileprivate(set) var atoms = [MathAtom]()

    init(
        withString attrString: NSAttributedString?,
        position: CGPoint,
        range: Range<Int>,
        font _: FontInstance?,
        atoms: [MathAtom],
    ) {
        super.init()
        self.position = position
        attributedString = attrString
        line = CTLineCreateWithAttributedString(attrString!)
        self.range = range
        self.atoms = atoms
        // We can't use typographic bounds here as the ascent and descent returned are for the font and not for the line.
        // CRITICAL FIX for accented character clipping:
        // Use the MAXIMUM of typographic width and visual width to account for glyph overhang.
        // - Typographic width = advance width (how far the cursor moves)
        // - Visual width = actual glyph extent (CGRectGetMaxX of glyph path bounds)
        // Some glyphs (especially italic/oblique accented characters) extend beyond their advance width.
        // Using max() ensures we account for overhang while maintaining proper spacing for normal glyphs.
        let typographicWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        ascent = max(0, bounds.maxY)
        descent = max(0, -bounds.minY)
        // Use the maximum of visual and typographic width to handle both:
        // 1. Overhanging glyphs (visual > typographic) - prevents clipping
        // 2. Normal glyphs (typographic >= visual) - maintains correct spacing
        let visualWidth = bounds.maxX
        width = max(typographicWidth, visualWidth)
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            guard let attrStr = attributedString?.mutableCopy() as? NSMutableAttributedString
            else { return }
            let foregroundColor = NSAttributedString.Key(kCTForegroundColorAttributeName as String)
            attrStr.addAttribute(
                foregroundColor, value: self.textColor!.cgColor,
                range: NSRange(location: 0, length: attrStr.length),
            )
            attributedString = attrStr
        }
    }

    override public func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()

        context.textPosition = position
        CTLineDraw(line, context)

        context.restoreGState()
    }
}

// MARK: - MathListDisplay

/// A MathListDisplay is a rendered form of MathList in one line.
/// It can render itself using the draw method.
public final class MathListDisplay: Display {
    ///     The type of position for a line, i.e. subscript/superscript or regular.
    public enum LinePosition: Int {
        /// Regular
        case regular
        /// Positioned at a subscript
        case ssubscript
        /// Positioned at a superscript
        case superscript
    }

    /// Where the line is positioned
    public var type: LinePosition = .regular
    /// An array of displays which are positioned relative to the position of the
    /// the current display.
    public fileprivate(set) var subDisplays = [Display]()
    /// If a subscript or superscript this denotes the location in the parent MathList. For a
    /// regular list this is NSNotFound
    public var index: Int = 0

    init(withDisplays displays: [Display], range: Range<Int>) {
        super.init()
        subDisplays = displays
        position = CGPoint.zero
        type = .regular
        index = NSNotFound
        self.range = range
        recomputeDimensions()
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            for displayAtom in subDisplays {
                if displayAtom.localTextColor == nil {
                    displayAtom.textColor = newValue
                } else {
                    displayAtom.textColor = displayAtom.localTextColor
                }
            }
        }
    }

    override public func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: position.x, y: position.y)
        context.textPosition = CGPoint.zero

        // draw each atom separately
        for displayAtom in subDisplays {
            displayAtom.draw(context)
        }

        context.restoreGState()
    }

    func recomputeDimensions() {
        var max_ascent: CGFloat = 0
        var max_descent: CGFloat = 0
        var max_width: CGFloat = 0
        for atom in subDisplays {
            let ascent = max(0, atom.position.y + atom.ascent)
            if ascent > max_ascent {
                max_ascent = ascent
            }

            let descent = max(0, 0 - (atom.position.y - atom.descent))
            if descent > max_descent {
                max_descent = descent
            }
            let width = atom.width + atom.position.x
            if width > max_width {
                max_width = width
            }
        }
        ascent = max_ascent
        descent = max_descent
        width = max_width
    }
}

// MARK: - FractionDisplay

/// Rendering of an Fraction as an Display
public final class FractionDisplay: Display {
    /// A display representing the numerator of the fraction. Its position is relative
    /// to the parent and is not treated as a sub-display.
    public fileprivate(set) var numerator: MathListDisplay?
    /// A display representing the denominator of the fraction. Its position is relative
    /// to the parent is not treated as a sub-display.
    public fileprivate(set) var denominator: MathListDisplay?

    var numeratorUp: CGFloat = 0 { didSet { updateNumeratorPosition() } }
    var denominatorDown: CGFloat = 0 { didSet { updateDenominatorPosition() } }
    var linePosition: CGFloat = 0
    var lineThickness: CGFloat = 0

    init(
        withNumerator numerator: MathListDisplay?,
        denominator: MathListDisplay?,
        position: CGPoint,
        range: Range<Int>,
    ) {
        super.init()
        self.numerator = numerator
        self.denominator = denominator
        self.position = position

        if range.isEmpty {
            self.range = range.lowerBound ..< (range.lowerBound + 1)
        } else {
            self.range = range
            assert(
                self.range.count == 1,
                "Fraction range length not 1 - range (\(range.lowerBound), \(range.count))",
            )
        }
    }

    override public var ascent: CGFloat {
        get { (numerator?.ascent ?? 0) + numeratorUp }
        set { super.ascent = newValue }
    }

    override public var descent: CGFloat {
        get { (denominator?.descent ?? 0) + denominatorDown }
        set { super.descent = newValue }
    }

    override public var width: CGFloat {
        get { max(numerator?.width ?? 0, denominator?.width ?? 0) }
        set { super.width = newValue }
    }

    func updateDenominatorPosition() {
        guard denominator != nil else { return }
        denominator!.position = CGPoint(
            x:
            position.x + (width - denominator!.width) / 2,
            y:
            position.y - denominatorDown,
        )
    }

    func updateNumeratorPosition() {
        guard numerator != nil else { return }
        numerator!.position = CGPoint(
            x:
            position.x + (width - numerator!.width) / 2, y: position.y + numeratorUp,
        )
    }

    override var position: CGPoint {
        get { super.position }
        set {
            super.position = newValue
            updateDenominatorPosition()
            updateNumeratorPosition()
        }
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            numerator?.textColor = newValue
            denominator?.textColor = newValue
        }
    }

    override public func draw(_ context: CGContext) {
        super.draw(context)
        numerator?.draw(context)
        denominator?.draw(context)

        context.saveGState()

        // draw the horizontal line
        // Note: line thickness of 0 draws the thinnest possible line - we want no line so check for 0s
        if lineThickness > 0 {
            context.setStrokeColor(textColor?.cgColor ?? PlatformColor.black.cgColor)
            context.setLineWidth(lineThickness)
            context.move(to: CGPoint(x: position.x, y: position.y + linePosition))
            context.addLine(
                to: CGPoint(x: position.x + width, y: position.y + linePosition),
            )
            context.strokePath()
        }

        context.restoreGState()
    }
}

// MARK: - RadicalDisplay

/// Rendering of an Radical as an Display
final class RadicalDisplay: Display {
    /// A display representing the radicand of the radical. Its position is relative
    /// to the parent is not treated as a sub-display.
    fileprivate(set) var radicand: MathListDisplay?
    /// A display representing the degree of the radical. Its position is relative
    /// to the parent is not treated as a sub-display.
    fileprivate(set) var degree: MathListDisplay?

    override var position: CGPoint {
        get { super.position }
        set {
            super.position = newValue
            updateRadicandPosition()
        }
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            radicand?.textColor = newValue
            degree?.textColor = newValue
        }
    }

    private var _radicalGlyph: Display?
    private var _radicalShift: CGFloat = 0

    var topKern: CGFloat = 0
    var lineThickness: CGFloat = 0

    init(
        withRadicand radicand: MathListDisplay?,
        glyph: Display,
        position: CGPoint,
        range: Range<Int>,
    ) {
        super.init()
        self.radicand = radicand
        _radicalGlyph = glyph
        _radicalShift = 0

        self.position = position
        self.range = range
    }

    func setDegree(_ degree: MathListDisplay?, fontMetrics: FontMathTable?) {
        // sets up the degree of the radical
        var kernBefore = fontMetrics!.radicalKernBeforeDegree
        let kernAfter = fontMetrics!.radicalKernAfterDegree
        let raise = fontMetrics!.radicalDegreeBottomRaisePercent * (ascent - descent)

        // The layout is:
        // kernBefore, raise, degree, kernAfter, radical
        self.degree = degree

        // the radical is now shifted by kernBefore + degree.width + kernAfter
        _radicalShift = kernBefore + degree!.width + kernAfter
        if _radicalShift < 0 {
            // we can't have the radical shift backwards, so instead we increase the kernBefore such
            // that _radicalShift will be 0.
            kernBefore -= _radicalShift
            _radicalShift = 0
        }

        // Note: position of degree is relative to parent.
        self.degree!.position = CGPoint(x: position.x + kernBefore, y: position.y + raise)
        // Update the width by the _radicalShift
        width = _radicalShift + _radicalGlyph!.width + radicand!.width
        // update the position of the radicand
        updateRadicandPosition()
    }

    func updateRadicandPosition() {
        // The position of the radicand includes the position of the RadicalDisplay
        // This is to make the positioning of the radical consistent with fractions and
        // have the cursor position finding algorithm work correctly.
        // move the radicand by the width of the radical sign
        radicand!.position = CGPoint(
            x:
            position.x + _radicalShift + _radicalGlyph!.width, y: position.y,
        )
    }

    override func draw(_ context: CGContext) {
        super.draw(context)

        // draw the radicand & degree at its position
        radicand?.draw(context)
        degree?.draw(context)

        context.saveGState()
        let color = textColor?.cgColor ?? PlatformColor.black.cgColor
        context.setStrokeColor(color)
        context.setFillColor(color)

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: position.x + _radicalShift, y: position.y)
        context.textPosition = CGPoint.zero

        // Draw the glyph.
        _radicalGlyph?.draw(context)

        // Draw the VBOX
        // for the kern of, we don't need to draw anything.
        let heightFromTop = topKern

        // draw the horizontal line with the given thickness
        let lineStart = CGPoint(
            x:
            _radicalGlyph!.width,
            y: ascent - heightFromTop - lineThickness /
                2,
        ) // subtract half the line thickness to center the line
        let lineEnd = CGPoint(x: lineStart.x + radicand!.width, y: lineStart.y)
        context.setLineWidth(lineThickness)
        context.setLineCap(.round)
        context.move(to: lineStart)
        context.addLine(to: lineEnd)
        context.strokePath()

        context.restoreGState()
    }
}

// MARK: - GlyphDisplay

/// Rendering a glyph as a display
final class GlyphDisplay: DisplayDS {
    var glyph: CGGlyph!
    var font: FontInstance?
    /// Horizontal scale factor for stretching glyphs (1.0 = no scaling)
    var scaleX: CGFloat = 1.0

    init(withGlpyh glyph: CGGlyph, range: Range<Int>, font: FontInstance?) {
        super.init()
        self.font = font
        self.glyph = glyph

        position = CGPoint.zero
        self.range = range
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()

        context.setFillColor(textColor?.cgColor ?? PlatformColor.black.cgColor)

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: position.x, y: position.y - shiftDown)

        // Apply horizontal scaling if needed (for stretchy arrows)
        if scaleX != 1.0 {
            context.scaleBy(x: scaleX, y: 1.0)
        }

        context.textPosition = CGPoint.zero

        var pos = CGPoint.zero
        CTFontDrawGlyphs(font!.ctFont, &glyph, &pos, 1, context)

        context.restoreGState()
    }

    override var ascent: CGFloat {
        get { super.ascent - shiftDown }
        set { super.ascent = newValue }
    }

    override var descent: CGFloat {
        get { super.descent + shiftDown }
        set { super.descent = newValue }
    }
}

// MARK: - GlyphConstructionDisplay

final class GlyphConstructionDisplay: DisplayDS {
    var glyphs = [CGGlyph]()
    var positions = [CGPoint]()
    var font: FontInstance?
    var numGlyphs: Int = 0

    init(withGlyphs glyphs: [CGGlyph], offsets: [CGFloat], font: FontInstance?) {
        super.init()
        assert(glyphs.count == offsets.count, "Glyphs and offsets need to match")
        numGlyphs = glyphs.count
        self.glyphs = glyphs
        positions = offsets.map { CGPoint(x: 0, y: $0) }
        self.font = font
        position = CGPoint.zero
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()

        context.setFillColor(textColor?.cgColor ?? PlatformColor.black.cgColor)

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: position.x, y: position.y - shiftDown)
        context.textPosition = CGPoint.zero

        // Draw the glyphs.
        CTFontDrawGlyphs(font!.ctFont, glyphs, positions, numGlyphs, context)

        context.restoreGState()
    }

    override var ascent: CGFloat {
        get { super.ascent - shiftDown }
        set { super.ascent = newValue }
    }

    override var descent: CGFloat {
        get { super.descent + shiftDown }
        set { super.descent = newValue }
    }
}

// MARK: - LargeOpLimitsDisplay

/// Rendering a large operator with limits as an Display
final class LargeOpLimitsDisplay: Display {
    /// A display representing the upper limit of the large operator. Its position is relative
    /// to the parent is not treated as a sub-display.
    var upperLimit: MathListDisplay?
    /// A display representing the lower limit of the large operator. Its position is relative
    /// to the parent is not treated as a sub-display.
    var lowerLimit: MathListDisplay?

    var limitShift: CGFloat = 0
    var upperLimitGap: CGFloat = 0 { didSet { updateUpperLimitPosition() } }
    var lowerLimitGap: CGFloat = 0 { didSet { updateLowerLimitPosition() } }
    var extraPadding: CGFloat = 0

    var nucleus: Display?

    init(
        withNucleus nucleus: Display?,
        upperLimit: MathListDisplay?,
        lowerLimit: MathListDisplay?,
        limitShift: CGFloat,
        extraPadding: CGFloat,
    ) {
        super.init()
        self.upperLimit = upperLimit
        self.lowerLimit = lowerLimit
        self.nucleus = nucleus

        var maxWidth = max(nucleus!.width, upperLimit?.width ?? 0)
        maxWidth = max(maxWidth, lowerLimit?.width ?? 0)

        self.limitShift = limitShift
        upperLimitGap = 0
        lowerLimitGap = 0
        self.extraPadding = extraPadding // corresponds to \xi_13 in TeX
        width = maxWidth
    }

    override var ascent: CGFloat {
        get {
            if upperLimit != nil {
                return nucleus!.ascent + extraPadding + upperLimit!.ascent + upperLimitGap
                    + upperLimit!.descent
            } else {
                return nucleus!.ascent
            }
        }
        set { super.ascent = newValue }
    }

    override var descent: CGFloat {
        get {
            if lowerLimit != nil {
                return nucleus!.descent + extraPadding + lowerLimitGap + lowerLimit!.descent
                    + lowerLimit!.ascent
            } else {
                return nucleus!.descent
            }
        }
        set { super.descent = newValue }
    }

    override var position: CGPoint {
        get { super.position }
        set {
            super.position = newValue
            updateLowerLimitPosition()
            updateUpperLimitPosition()
            updateNucleusPosition()
        }
    }

    func updateLowerLimitPosition() {
        if lowerLimit != nil {
            // The position of the lower limit includes the position of the LargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to below the nucleus leaving a gap of _lowerLimitGap and subtract
            // the ascent to to get the baseline. Also center and shift it to the left by _limitShift.
            lowerLimit!.position = CGPoint(
                x:
                position.x - limitShift + (width - lowerLimit!.width) / 2,
                y:
                position.y - nucleus!.descent - lowerLimitGap - lowerLimit!.ascent,
            )
        }
    }

    func updateUpperLimitPosition() {
        if upperLimit != nil {
            // The position of the upper limit includes the position of the LargeOpLimitsDisplay
            // This is to make the positioning of the radical consistent with fractions and radicals
            // Move the starting point to above the nucleus leaving a gap of _upperLimitGap and add
            // the descent to to get the baseline. Also center and shift it to the right by _limitShift.
            upperLimit!.position = CGPoint(
                x:
                position.x + limitShift + (width - upperLimit!.width) / 2,
                y:
                position.y + nucleus!.ascent + upperLimitGap + upperLimit!.descent,
            )
        }
    }

    func updateNucleusPosition() {
        // Center the nucleus
        nucleus?.position = CGPoint(
            x:
            position.x + (width - nucleus!.width) / 2, y: position.y,
        )
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            upperLimit?.textColor = newValue
            lowerLimit?.textColor = newValue
            nucleus?.textColor = newValue
        }
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        // Draw the elements.
        upperLimit?.draw(context)
        lowerLimit?.draw(context)
        nucleus?.draw(context)
    }
}

// MARK: - LineDisplay

/// Rendering of an list with an overline or underline
final class LineDisplay: Display {
    /// A display representing the inner list that is underlined. Its position is relative
    /// to the parent is not treated as a sub-display.
    var inner: MathListDisplay?
    var lineShiftUp: CGFloat = 0
    var lineThickness: CGFloat = 0

    init(withInner inner: MathListDisplay?, position: CGPoint, range: Range<Int>) {
        super.init()
        self.inner = inner

        self.position = position
        self.range = range
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            inner?.textColor = newValue
        }
    }

    override var position: CGPoint {
        get { super.position }
        set {
            super.position = newValue
            updateInnerPosition()
        }
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        inner?.draw(context)

        context.saveGState()

        context.setStrokeColor(textColor?.cgColor ?? PlatformColor.black.cgColor)

        // draw the horizontal line
        let lineStart = CGPoint(x: position.x, y: position.y + lineShiftUp)
        let lineEnd = CGPoint(x: lineStart.x + inner!.width, y: lineStart.y)
        context.setLineWidth(lineThickness)
        context.move(to: lineStart)
        context.addLine(to: lineEnd)
        context.strokePath()

        context.restoreGState()
    }

    func updateInnerPosition() {
        inner?.position = CGPoint(x: position.x, y: position.y)
    }
}

// MARK: - AccentDisplay

/// Rendering an accent as a display
final class AccentDisplay: Display {
    /// A display representing the inner list that is accented. Its position is relative
    /// to the parent is not treated as a sub-display.
    var accentee: MathListDisplay?

    /// A display representing the accent. Its position is relative to the current display.
    var accent: GlyphDisplay?

    init(withAccent glyph: GlyphDisplay?, accentee: MathListDisplay?, range: Range<Int>) {
        super.init()
        accent = glyph
        self.accentee = accentee
        self.accentee?.position = CGPoint.zero
        self.range = range
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            accentee?.textColor = newValue
            accent?.textColor = newValue
        }
    }

    override var position: CGPoint {
        get { super.position }
        set {
            super.position = newValue
            updateAccenteePosition()
        }
    }

    func updateAccenteePosition() {
        accentee?.position = CGPoint(x: position.x, y: position.y)
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        accentee?.draw(context)

        context.saveGState()
        context.translateBy(x: position.x, y: position.y)
        context.textPosition = CGPoint.zero

        accent?.draw(context)

        context.restoreGState()
    }
}
