import CoreText
import Foundation
import CoreGraphics

extension Typesetter {
    // MARK: - Radicals

    /// Minimum vertical gap between the top of the radicand and the radical overbar.
    func radicalVerticalGap() -> CGFloat {
        if style == .display {
            return styleFont.mathTable!.radicalDisplayStyleVerticalGap
        } else {
            return styleFont.mathTable!.radicalVerticalGap
        }
    }

    /// Finds or constructs a radical sign (√) glyph tall enough to cover `radicalHeight`.
    func radicalGlyph(height radicalHeight: CGFloat) -> ShiftableDisplay? {
        var glyphAscent = CGFloat(0)
        var glyphDescent = CGFloat(0)
        var glyphWidth = CGFloat(0)

        let radicalGlyph = findGlyphForCharacterAtIndex(
            "\u{221A}".startIndex, inString: "\u{221A}",
        )
        let glyph = findGlyph(
            radicalGlyph, withHeight: radicalHeight, glyphAscent: &glyphAscent,
            glyphDescent: &glyphDescent, glyphWidth: &glyphWidth,
        )

        var glyphDisplay: ShiftableDisplay?
        if glyphAscent + glyphDescent < radicalHeight {
            // the glyphs is not as large as required. A glyph needs to be constructed using the extenders.
            glyphDisplay = constructGlyph(radicalGlyph, height: radicalHeight)
        }

        if glyphDisplay == nil {
            // No constructed display so use the glyph we got.
            glyphDisplay = GlyphDisplay(glyph: glyph, range: 0 ..< 0, font: styleFont)
            glyphDisplay!.ascent = glyphAscent
            glyphDisplay!.descent = glyphDescent
            glyphDisplay!.width = glyphWidth
        }
        return glyphDisplay
    }

    /// Builds a ``RadicalDisplay`` by typesetting the radicand, selecting an appropriately
    /// sized radical glyph, and positioning the overbar. The degree (if any) is set separately
    /// via ``RadicalDisplay/setDegree(_:fontMetrics:)``.
    func makeRadical(_ radicand: MathList?, range: Range<Int>) -> RadicalDisplay? {
        let innerDisplay = Typesetter.makeLineDisplay(
            for: radicand, font: font, style: style, cramped: true,
        )!
        var clearance = radicalVerticalGap()
        let radicalRuleThickness = styleFont.mathTable!.radicalRuleThickness
        let radicalHeight =
            innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness

        let glyph = radicalGlyph(height: radicalHeight)!

        // Note this is a departure from Latex. Latex assumes that glyphAscent == thickness.
        // Open type math makes no such assumption, and ascent and descent are independent of the thickness.
        // Latex computes delta as descent - (h(inner) + d(inner) + clearance)
        // but since we may not have ascent == thickness, we modify the delta calculation slightly.
        // If the font designer followes Latex conventions, it will be identical.
        let delta =
            (glyph.descent + glyph.ascent)
                - (innerDisplay.ascent + innerDisplay.descent + clearance + radicalRuleThickness)
        if delta > 0 {
            clearance += delta / 2 // increase the clearance to center the radicand inside the sign.
        }

        // we need to shift the radical glyph up, to coincide with the baseline of inner.
        // The new ascent of the radical glyph should be thickness + adjusted clearance + h(inner)
        let radicalAscent = radicalRuleThickness + clearance + innerDisplay.ascent
        let shiftUp =
            radicalAscent
                - glyph
                .ascent // Note: if the font designer followed latex conventions, this is the same as glyphAscent == thickness.
        glyph.shiftDown = -shiftUp

        let radical = RadicalDisplay(
            radicand: innerDisplay, glyph: glyph, position: currentPosition, range: range,
        )
        radical.ascent = radicalAscent + styleFont.mathTable!.radicalExtraAscender
        radical.topKern = styleFont.mathTable!.radicalExtraAscender
        radical.lineThickness = radicalRuleThickness
        // Note: Until we have radical construction from parts, it is possible that glyphAscent+glyphDescent is less
        // than the requested height of the glyph (i.e. radicalHeight), so in the case the innerDisplay has a larger
        // descent we use the innerDisplay's descent.
        radical.descent = max(glyph.ascent + glyph.descent - radicalAscent, innerDisplay.descent)
        radical.width = glyph.width + innerDisplay.width
        return radical
    }
}
