import CoreGraphics
import CoreText
import Foundation

extension Typesetter {
    // MARK: - Fractions

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

    func numeratorGapMin() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.fractionNumeratorDisplayStyleGapMin
        } else {
            return styleFont.mathTable!.fractionNumeratorGapMin
        }
    }

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

    func denominatorGapMin() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.fractionDenominatorDisplayStyleGapMin
        } else {
            return styleFont.mathTable!.fractionDenominatorGapMin
        }
    }

    func stackGapMin() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.stackDisplayStyleGapMin
        } else {
            return styleFont.mathTable!.stackGapMin
        }
    }

    func fractionDelimiterHeight() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.fractionDelimiterDisplayStyleSize
        } else {
            return styleFont.mathTable!.fractionDelimiterSize
        }
    }

    func fractionStyle() -> LineStyle {
        // Keep fractions at the same style level instead of incrementing.
        // This ensures that fraction numerators/denominators have the same
        // font size as regular text, preventing them from appearing too small
        // in inline mode or when nested.
        style
    }

    func makeFraction(_ frac: Fraction?) -> Display? {
        guard let frac else { return nil }

        // lay out the parts of the fraction
        let numeratorStyle: LineStyle
        let denominatorStyle: LineStyle

        if frac.isContinuedFraction {
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
            for: frac.numerator, font: font, style: numeratorStyle, cramped: false,
        )
        let denominatorDisplay = Typesetter.makeLineDisplay(
            for: frac.denominator, font: font, style: denominatorStyle, cramped: true,
        )

        // Handle empty numerator or denominator by creating empty displays
        let numDisplay = numeratorDisplay ?? MathListDisplay(displays: [], range: 0 ..< 0)
        let denomDisplay = denominatorDisplay ?? MathListDisplay(displays: [], range: 0 ..< 0)

        // determine the location of the numerator
        var numeratorShiftUp = numeratorShiftUp(frac.hasRule)
        var denominatorShiftDown = denominatorShiftDown(frac.hasRule)
        let barLocation = styleFont.mathTable!.axisHeight
        let barThickness = frac.hasRule ? styleFont.mathTable!.fractionRuleThickness : 0

        if frac.hasRule {
            // This is the difference between the lowest edge of the numerator and the top edge of the fraction bar
            let distanceFromNumeratorToBar =
                (numeratorShiftUp - numDisplay.descent) - (barLocation + barThickness / 2)
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
                (barLocation - barThickness / 2) - (denomDisplay.ascent - denominatorShiftDown)
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
                (numeratorShiftUp - numDisplay.descent) -
                (denomDisplay.ascent - denominatorShiftDown)
            // This is the minimum clearance between the numerator and denominator.
            // For ruleless fractions (like binom, choose, atop), use 1.5x the standard gap
            // for better visual separation, following TeX's approach for binomial coefficients
            let minGap = stackGapMin() * 1.5
            if clearance < minGap {
                numeratorShiftUp += (minGap - clearance) / 2
                denominatorShiftDown += (minGap - clearance) / 2
            }
        }

        let display = FractionDisplay(
            numerator: numDisplay, denominator: denomDisplay, position: currentPosition,
            range: frac.indexRange,
        )

        display.numeratorUp = numeratorShiftUp
        display.denominatorDown = denominatorShiftDown
        display.lineThickness = barThickness
        display.linePosition = barLocation
        if frac.leftDelimiter.isEmpty, frac.rightDelimiter.isEmpty {
            return display
        } else {
            return addDelimitersToFractionDisplay(display, forFraction: frac)
        }
    }

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
            if let rightGlyph = findGlyphForBoundary(frac.rightDelimiter, withHeight: glyphHeight())
            {
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
