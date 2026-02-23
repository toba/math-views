public import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A display for a ``Fraction`` atom, rendering numerator and denominator with an optional rule line.
///
/// The positioning uses TeX conventions: `numeratorUp` is the distance from the baseline
/// to the numerator's baseline (positive = upward), and `denominatorDown` is the distance
/// from the baseline to the denominator's baseline (positive = downward).
public final class FractionDisplay: Display {
    /// The rendered numerator, positioned above the fraction line.
    public fileprivate(set) var numerator: MathListDisplay?
    /// The rendered denominator, positioned below the fraction line.
    public fileprivate(set) var denominator: MathListDisplay?

    /// Distance from the fraction's baseline to the numerator's baseline (upward).
    var numeratorUp: CGFloat = 0 { didSet { updateNumeratorPosition() } }
    /// Distance from the fraction's baseline to the denominator's baseline (downward).
    var denominatorDown: CGFloat = 0 { didSet { updateDenominatorPosition() } }
    var linePosition: CGFloat = 0
    var lineThickness: CGFloat = 0

    init(
        numerator: MathListDisplay?,
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
