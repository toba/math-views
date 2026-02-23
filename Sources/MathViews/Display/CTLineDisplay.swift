public import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A display that renders a single `CTLine` — a Core Text object representing one line of styled text.
///
/// Core Text's `CTLine` is created from an `NSAttributedString` and handles glyph selection,
/// shaping, and drawing. `CTLineDisplay` uses it to render sequences of characters
/// (variables, numbers, operators) as a single run of text.
public final class CTLineDisplay: Display {
    /// The CTLine being displayed
    public var line: CTLine!
    /// The attributed string used to generate the CTLineRef. Note setting this does not reset the dimensions of
    /// the display. So set only when
    var attributedString: NSAttributedString? {
        didSet { line = CTLineCreateWithAttributedString(attributedString!) }
    }

    /// An array of MathAtoms that this CTLine displays. Used for indexing back into the MathList
    public fileprivate(set) var atoms = [MathAtom]()

    init(
        attributedString: NSAttributedString?,
        position: CGPoint,
        range: Range<Int>,
        font _: FontInstance?,
        atoms: [MathAtom],
    ) {
        super.init()
        self.position = position
        self.attributedString = attributedString
        line = CTLineCreateWithAttributedString(attributedString!)
        self.range = range
        self.atoms = atoms
        // Use glyph path bounds for ascent/descent — typographic bounds reflect the font,
        // not the actual glyphs drawn. For width, take the max of advance width and visual
        // extent so italic/accented glyphs that overhang their advance aren't clipped.
        let typographicWidth = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        if bounds.isNull {
            ascent = 0
            descent = 0
            width = typographicWidth
        } else {
            ascent = max(0, bounds.maxY)
            descent = max(0, -bounds.minY)
            width = max(typographicWidth, bounds.maxX)
        }
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
