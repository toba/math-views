import CoreText
import Foundation
import CoreGraphics

extension Typesetter {
    /// Multiplier for the minimum gap in ruleless fractions (atop, binom, choose).
    /// Uses 1.5× the standard stack gap for better visual separation.
    private static let rulelessFractionGapMultiplier: CGFloat = 1.5

    // MARK: - Fractions

    /// Returns the vertical shift for the numerator baseline above the fraction axis.
    /// Uses display-style or text-style OpenType MATH metrics depending on the current style,
    /// and stack metrics when the fraction has no rule (e.g. `\atop`, `\binom`).
    func numeratorShiftUp(_ hasRule: Bool) -> CGFloat {
        if hasRule {
            if style == .display {
                return styleFont.mathTable!.fractionNumeratorDisplayStyleShiftUp
            } else {
                return styleFont.mathTable!.fractionNumeratorShiftUp
            }
        } else {
            if style == .display {
                return styleFont.mathTable!.stackTopDisplayStyleShiftUp
            } else {
                return styleFont.mathTable!.stackTopShiftUp
            }
        }
    }

    /// Minimum gap between the numerator's bottom edge and the fraction rule's top edge.
    func numeratorGapMin() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.fractionNumeratorDisplayStyleGapMin
        } else {
            return styleFont.mathTable!.fractionNumeratorGapMin
        }
    }

    /// Returns the vertical shift for the denominator baseline below the fraction axis.
    /// Mirrors ``numeratorShiftUp(_:)`` for the bottom half of the fraction.
    func denominatorShiftDown(_ hasRule: Bool) -> CGFloat {
        if hasRule {
            if style == .display {
                return styleFont.mathTable!.fractionDenominatorDisplayStyleShiftDown
            } else {
                return styleFont.mathTable!.fractionDenominatorShiftDown
            }
        } else {
            if style == .display {
                return styleFont.mathTable!.stackBottomDisplayStyleShiftDown
            } else {
                return styleFont.mathTable!.stackBottomShiftDown
            }
        }
    }

    /// Minimum gap between the fraction rule's bottom edge and the denominator's top edge.
    func denominatorGapMin() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.fractionDenominatorDisplayStyleGapMin
        } else {
            return styleFont.mathTable!.fractionDenominatorGapMin
        }
    }

    /// Minimum vertical gap between numerator and denominator for rule-less fractions
    /// (`\atop`, `\binom`, `\choose`).
    func stackGapMin() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.stackDisplayStyleGapMin
        } else {
            return styleFont.mathTable!.stackGapMin
        }
    }

    /// Target height for delimiters surrounding a delimited fraction (e.g. `\binom`).
    func fractionDelimiterHeight() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.fractionDelimiterDisplayStyleSize
        } else {
            return styleFont.mathTable!.fractionDelimiterSize
        }
    }

    /// Returns the line style to use for fraction numerator/denominator content.
    func fractionStyle() -> LineStyle {
        // Keep fractions at the same style level instead of incrementing.
        // This ensures that fraction numerators/denominators have the same
        // font size as regular text, preventing them from appearing too small
        // in inline mode or when nested.
        style
    }

    /// Builds a ``FractionDisplay`` from a ``Fraction`` atom, positioning the numerator
    /// and denominator according to OpenType MATH metrics and TeX rules.
    func makeFraction(_ fraction: Fraction?) -> Display? {
        guard let fraction else { return nil }

        // lay out the parts of the fraction
        let numeratorStyle: LineStyle
        let denominatorStyle: LineStyle

        if fraction.isContinuedFraction {
            // Continued fractions always use display style
            numeratorStyle = .display
            denominatorStyle = .display
        } else {
            // Regular fractions use adaptive style
            let fractionStyle = fractionStyle
            numeratorStyle = fractionStyle()
            denominatorStyle = fractionStyle()
        }

        let numeratorDisplay = Typesetter.makeLineDisplay(
            for: fraction.numerator, font: font, style: numeratorStyle, cramped: false,
        )
        let denominatorDisplay = Typesetter.makeLineDisplay(
            for: fraction.denominator, font: font, style: denominatorStyle, cramped: true,
        )

        // Handle empty numerator or denominator by creating empty displays
        let resolvedNumerator = numeratorDisplay ?? MathListDisplay(displays: [], range: 0 ..< 0)
        let resolvedDenominator = denominatorDisplay ?? MathListDisplay(
            displays: [],
            range: 0 ..< 0,
        )

        // determine the location of the numerator
        var numeratorShiftUp = numeratorShiftUp(fraction.hasRule)
        var denominatorShiftDown = denominatorShiftDown(fraction.hasRule)
        let barLocation = styleFont.mathTable!.axisHeight
        let barThickness = fraction.hasRule ? styleFont.mathTable!.fractionRuleThickness : 0

        if fraction.hasRule {
            // This is the difference between the lowest edge of the numerator and the top edge of the fraction bar
            let distanceFromNumeratorToBar =
                (numeratorShiftUp - resolvedNumerator.descent) - (barLocation + barThickness / 2)
            // The distance should at least be displayGap
            let minNumeratorGap = numeratorGapMin
            if distanceFromNumeratorToBar < minNumeratorGap() {
                // This makes the distance between the bottom of the numerator and the top edge of the fraction bar
                // at least minNumeratorGap.
                numeratorShiftUp += (minNumeratorGap() - distanceFromNumeratorToBar)
            }

            // Do the same for the denominator
            // This is the difference between the top edge of the denominator and the bottom edge of the fraction bar
            let distanceFromDenominatorToBar =
                (barLocation - barThickness / 2) -
                (resolvedDenominator.ascent - denominatorShiftDown)
            // The distance should at least be denominator gap
            let minDenominatorGap = denominatorGapMin
            if distanceFromDenominatorToBar < minDenominatorGap() {
                // This makes the distance between the top of the denominator and the bottom of the fraction bar to be exactly
                // minDenominatorGap
                denominatorShiftDown += (minDenominatorGap() - distanceFromDenominatorToBar)
            }
        } else {
            // This is the distance between the numerator and the denominator
            let clearance =
                (numeratorShiftUp - resolvedNumerator.descent)
                    - (resolvedDenominator.ascent - denominatorShiftDown)
            // This is the minimum clearance between the numerator and denominator.
            // For ruleless fractions (like binom, choose, atop), use 1.5x the standard gap
            // for better visual separation, following TeX's approach for binomial coefficients
            let minGap = stackGapMin() * Self.rulelessFractionGapMultiplier
            if clearance < minGap {
                numeratorShiftUp += (minGap - clearance) / 2
                denominatorShiftDown += (minGap - clearance) / 2
            }
        }

        let display = FractionDisplay(
            numerator: resolvedNumerator, denominator: resolvedDenominator,
            position: currentPosition,
            range: fraction.indexRange,
        )

        display.numeratorUp = numeratorShiftUp
        display.denominatorDown = denominatorShiftDown
        display.lineThickness = barThickness
        display.linePosition = barLocation
        if fraction.leftDelimiter.isEmpty, fraction.rightDelimiter.isEmpty {
            return display
        } else {
            return addDelimitersToFractionDisplay(display, forFraction: fraction)
        }
    }

    /// Wraps a fraction display in left/right delimiter glyphs (e.g. parentheses for `\binom`).
    func addDelimitersToFractionDisplay(_ display: FractionDisplay, forFraction frac: Fraction)
        -> Display
    {
        assert(
            !frac.leftDelimiter.isEmpty || !frac.rightDelimiter.isEmpty,
            "Fraction should have delimiters to call this function",
        )

        var innerElements = [Display]()
        let glyphHeight = fractionDelimiterHeight
        var position = CGPoint.zero
        if !frac.leftDelimiter.isEmpty {
            if let leftGlyph = findGlyphForBoundary(frac.leftDelimiter, withHeight: glyphHeight()) {
                leftGlyph.position = position
                position.x += leftGlyph.width
                innerElements.append(leftGlyph)
            }
        }

        display.position = position
        position.x += display.width
        innerElements.append(display)

        if !frac.rightDelimiter.isEmpty {
            if let rightGlyph = findGlyphForBoundary(
                frac.rightDelimiter,
                withHeight: glyphHeight(),
            ) {
                rightGlyph.position = position
                position.x += rightGlyph.width
                innerElements.append(rightGlyph)
            }
        }
        let innerDisplay = MathListDisplay(displays: innerElements, range: frac.indexRange)
        innerDisplay.position = currentPosition
        return innerDisplay
    }
}
