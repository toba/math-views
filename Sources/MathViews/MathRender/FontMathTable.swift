import CoreText
import Foundation

struct GlyphPart {
    /// The glyph that represents this part
    var glyph: CGGlyph!

    /// Full advance width/height for this part, in the direction of the extension in points.
    var fullAdvance: CGFloat = 0

    /// Advance width/ height of the straight bar connector material at the beginning of the glyph in points.
    var startConnectorLength: CGFloat = 0

    /// Advance width/ height of the straight bar connector material at the end of the glyph in points.
    var endConnectorLength: CGFloat = 0

    /// If this part is an extender. If set, the part can be skipped or repeated.
    var isExtender: Bool = false
}

/// This class represents the Math table of an open type font.
///
/// The math table is documented here: https://www.microsoft.com/typography/otspec/math.htm
///
/// How the constants in this class affect the display is documented here:
/// http://www.tug.org/TUGboat/tb30-1/tb94vieth.pdf
///
/// Note: We don't parse the math table from the open type font. Rather we parse it
/// in python and convert it to a .plist file which is easily consumed by this class.
/// This approach is preferable to spending an inordinate amount of time figuring out
/// how to parse the returned NSData object using the open type rules.
///
/// Remark: This class is not meant to be used outside of this library.
final class FontMathTable {
    let mathFont: MathFont
    let fontSize: CGFloat
    let unitsPerEm: UInt
    private let _mathTable: [String: Any]

    private let kConstants = "constants"

    /// MU unit in points
    var muUnit: CGFloat { fontSize / 18 }

    func fontUnitsToPt(_ fontUnits: Int) -> CGFloat {
        CGFloat(fontUnits) * fontSize / CGFloat(unitsPerEm)
    }

    init(mathFont: MathFont, size: CGFloat, unitsPerEm: UInt) {
        self.mathFont = mathFont
        fontSize = size
        self.unitsPerEm = unitsPerEm
        _mathTable = mathFont.rawMathTable()
    }

    func constantFromTable(_ name: String) -> CGFloat {
        guard let constants = _mathTable[kConstants] as? [String: Any],
              let val = constants[name] as? Int
        else {
            return .zero
        }
        return fontUnitsToPt(val)
    }

    func percentFromTable(_ percentName: String) -> CGFloat {
        guard let consts = _mathTable[kConstants] as? [String: Any],
              let val = consts[percentName] as? Int
        else {
            return .zero
        }
        return CGFloat(val) / 100
    }

    // MARK: - Fractions

    /// Math Font Metrics from the opentype specification

    var fractionNumeratorDisplayStyleShiftUp: CGFloat {
        constantFromTable("FractionNumeratorDisplayStyleShiftUp")
    }

    var fractionNumeratorShiftUp: CGFloat { constantFromTable("FractionNumeratorShiftUp") }
    var fractionDenominatorDisplayStyleShiftDown: CGFloat {
        constantFromTable("FractionDenominatorDisplayStyleShiftDown")
    }

    var fractionDenominatorShiftDown: CGFloat { constantFromTable("FractionDenominatorShiftDown") }
    var fractionNumeratorDisplayStyleGapMin: CGFloat {
        constantFromTable("FractionNumDisplayStyleGapMin")
    }

    var fractionNumeratorGapMin: CGFloat { constantFromTable("FractionNumeratorGapMin") }
    var fractionDenominatorDisplayStyleGapMin: CGFloat {
        constantFromTable("FractionDenomDisplayStyleGapMin")
    }

    var fractionDenominatorGapMin: CGFloat { constantFromTable("FractionDenominatorGapMin") }
    var fractionRuleThickness: CGFloat { constantFromTable("FractionRuleThickness") }
    var skewedFractionHorizontalGap: CGFloat { constantFromTable("SkewedFractionHorizontalGap") }
    var skewedFractionVerticalGap: CGFloat { constantFromTable("SkewedFractionVerticalGap") }

    // MARK: - Non-standard

    var fractionDelimiterSize: CGFloat { 1.01 * fontSize }
    var fractionDelimiterDisplayStyleSize: CGFloat { 2.39 * fontSize }

    // MARK: - Stacks

    var stackTopDisplayStyleShiftUp: CGFloat { constantFromTable("StackTopDisplayStyleShiftUp") }
    var stackTopShiftUp: CGFloat { constantFromTable("StackTopShiftUp") }
    var stackDisplayStyleGapMin: CGFloat { constantFromTable("StackDisplayStyleGapMin") }
    var stackGapMin: CGFloat { constantFromTable("StackGapMin") }
    var stackBottomDisplayStyleShiftDown: CGFloat {
        constantFromTable("StackBottomDisplayStyleShiftDown")
    }

    var stackBottomShiftDown: CGFloat { constantFromTable("StackBottomShiftDown") }

    var stretchStackBottomShiftDown: CGFloat { constantFromTable("StretchStackBottomShiftDown") }
    var stretchStackGapAboveMin: CGFloat { constantFromTable("StretchStackGapAboveMin") }
    var stretchStackGapBelowMin: CGFloat { constantFromTable("StretchStackGapBelowMin") }
    var stretchStackTopShiftUp: CGFloat { constantFromTable("StretchStackTopShiftUp") }

    // MARK: - super/sub scripts

    var superscriptShiftUp: CGFloat { constantFromTable("SuperscriptShiftUp") }
    var superscriptShiftUpCramped: CGFloat { constantFromTable("SuperscriptShiftUpCramped") }
    var subscriptShiftDown: CGFloat { constantFromTable("SubscriptShiftDown") }
    var superscriptBaselineDropMax: CGFloat { constantFromTable("SuperscriptBaselineDropMax") }
    var subscriptBaselineDropMin: CGFloat { constantFromTable("SubscriptBaselineDropMin") }
    var superscriptBottomMin: CGFloat { constantFromTable("SuperscriptBottomMin") }
    var subscriptTopMax: CGFloat { constantFromTable("SubscriptTopMax") }
    var subSuperscriptGapMin: CGFloat { constantFromTable("SubSuperscriptGapMin") }
    var superscriptBottomMaxWithSubscript: CGFloat {
        constantFromTable("SuperscriptBottomMaxWithSubscript")
    }

    var spaceAfterScript: CGFloat { constantFromTable("SpaceAfterScript") }

    // MARK: - radicals

    var radicalExtraAscender: CGFloat { constantFromTable("RadicalExtraAscender") }
    var radicalRuleThickness: CGFloat { constantFromTable("RadicalRuleThickness") }
    var radicalDisplayStyleVerticalGap: CGFloat {
        constantFromTable("RadicalDisplayStyleVerticalGap")
    }

    var radicalVerticalGap: CGFloat { constantFromTable("RadicalVerticalGap") }
    var radicalKernBeforeDegree: CGFloat { constantFromTable("RadicalKernBeforeDegree") }
    var radicalKernAfterDegree: CGFloat { constantFromTable("RadicalKernAfterDegree") }
    var radicalDegreeBottomRaisePercent: CGFloat {
        percentFromTable("RadicalDegreeBottomRaisePercent")
    }

    // MARK: - Limits

    var upperLimitBaselineRiseMin: CGFloat { constantFromTable("UpperLimitBaselineRiseMin") }
    var upperLimitGapMin: CGFloat { constantFromTable("UpperLimitGapMin") }
    var lowerLimitGapMin: CGFloat { constantFromTable("LowerLimitGapMin") }
    var lowerLimitBaselineDropMin: CGFloat { constantFromTable("LowerLimitBaselineDropMin") }
    var limitExtraAscenderDescender: CGFloat { 0 }

    // MARK: - Underline

    var underbarVerticalGap: CGFloat { constantFromTable("UnderbarVerticalGap") }
    var underbarRuleThickness: CGFloat { constantFromTable("UnderbarRuleThickness") }
    var underbarExtraDescender: CGFloat { constantFromTable("UnderbarExtraDescender") }

    // MARK: - Overline

    var overbarVerticalGap: CGFloat { constantFromTable("OverbarVerticalGap") }
    var overbarRuleThickness: CGFloat { constantFromTable("OverbarRuleThickness") }
    var overbarExtraAscender: CGFloat { constantFromTable("OverbarExtraAscender") }

    // MARK: - Constants

    var axisHeight: CGFloat { constantFromTable("AxisHeight") }
    var scriptScaleDown: CGFloat { percentFromTable("ScriptPercentScaleDown") }
    var scriptScriptScaleDown: CGFloat { percentFromTable("ScriptScriptPercentScaleDown") }
    var mathLeading: CGFloat { constantFromTable("MathLeading") }
    var delimitedSubFormulaMinHeight: CGFloat { constantFromTable("DelimitedSubFormulaMinHeight") }

    // MARK: - Accent

    var accentBaseHeight: CGFloat { constantFromTable("AccentBaseHeight") }
    var flattenedAccentBaseHeight: CGFloat { constantFromTable("FlattenedAccentBaseHeight") }

    // MARK: - Variants

    private let kVertVariants = "v_variants"
    private let kHorizVariants = "h_variants"

    /// Returns an Array of all the vertical variants of the glyph if any. If
    /// there are no variants for the glyph, the array contains the given glyph.
    func verticalVariants(for glyph: CGGlyph) -> [CGGlyph] {
        guard let variants = _mathTable[kVertVariants] as? [String: Any] else { return [] }
        return self.variants(for: glyph, in: variants)
    }

    /// Returns an Array of all the horizontal variants of the glyph if any. If
    /// there are no variants for the glyph, the array contains the given glyph.
    func horizontalVariants(for glyph: CGGlyph) -> [CGGlyph] {
        guard let variants = _mathTable[kHorizVariants] as? [String: Any] else { return [] }
        return self.variants(for: glyph, in: variants)
    }

    func variants(for glyph: CGGlyph, in variants: [String: Any]) -> [CGGlyph] {
        let font = mathFont.fontInstance(size: fontSize)
        let glyphName = font.glyphName(for: glyph)

        guard let variantGlyphs = variants[glyphName] as? [String], !variantGlyphs.isEmpty else {
            let glyph = font.glyph(named: glyphName)
            return [glyph]
        }
        var glyphArray = [CGGlyph]()
        for glyphVariantName in variantGlyphs {
            let variantGlyph = font.glyph(named: glyphVariantName)
            glyphArray.append(variantGlyph)
        }
        return glyphArray
    }

    /// Returns a larger vertical variant of the given glyph if any.
    /// If there is no larger version, this returns the current glyph.
    ///
    /// - Parameter glyph: The glyph to find a larger variant for
    /// - Parameter forDisplayStyle: If true, selects the largest appropriate variant for display style.
    ///                             If false, selects the next larger variant (incremental sizing).
    /// - Returns: A larger glyph variant, or the original glyph if no variants exist
    func largerGlyph(_ glyph: CGGlyph, displayStyle: Bool = false) -> CGGlyph {
        let font = mathFont.fontInstance(size: fontSize)
        let glyphName = font.glyphName(for: glyph)

        guard let variants = _mathTable[kVertVariants] as? [String: Any],
              let variantGlyphs = variants[glyphName] as? [String], !variantGlyphs.isEmpty
        else {
            return glyph
        }

        if displayStyle {
            let count = variantGlyphs.count

            let targetIndex: Int
            if count <= 2 {
                targetIndex = count - 1
            } else if count <= 4 {
                targetIndex = count - 2
            } else {
                targetIndex = min(count - 2, Int(Double(count) * 0.6))
            }

            let glyphVariantName = variantGlyphs[targetIndex]
            return font.glyph(named: glyphVariantName)
        } else {
            for glyphVariantName in variantGlyphs where glyphVariantName != glyphName {
                return font.glyph(named: glyphVariantName)
            }
        }

        return glyph
    }

    // MARK: - Italic Correction

    private let kItalic = "italic"

    /// Returns the italic correction for the given glyph if any. If there
    /// isn't any this returns 0.
    func italicCorrection(for glyph: CGGlyph) -> CGFloat {
        let font = mathFont.fontInstance(size: fontSize)
        let glyphName = font.glyphName(for: glyph)

        guard let italics = _mathTable[kItalic] as? [String: Any],
              let val = italics[glyphName] as? Int
        else {
            return .zero
        }
        return fontUnitsToPt(val)
    }

    // MARK: - Accents

    private let kAccents = "accents"

    /// Returns the adjustment to the top accent for the given glyph if any.
    /// If there isn't any this returns the center of the advance width.
    func topAccentAdjustment(for glyph: CGGlyph) -> CGFloat {
        let font = mathFont.fontInstance(size: fontSize)
        let glyphName = font.glyphName(for: glyph)

        guard let accents = _mathTable[kAccents] as? [String: Any],
              let val = accents[glyphName] as? Int
        else {
            var glyph = glyph
            var advances = CGSize.zero
            CTFontGetAdvancesForGlyphs(font.ctFont, .horizontal, &glyph, &advances, 1)
            return advances.width / 2
        }
        return fontUnitsToPt(val)
    }

    // MARK: - Glyph Construction

    /// Minimum overlap of connecting glyphs during glyph construction
    var minConnectorOverlap: CGFloat { constantFromTable("MinConnectorOverlap") }

    private let kVertAssembly = "v_assembly"
    private let kAssemblyParts = "parts"

    /// Returns an array of the glyph parts to be used for constructing vertical variants
    /// of this glyph. If there is no glyph assembly defined, returns an empty array.
    func verticalGlyphAssembly(for glyph: CGGlyph) -> [GlyphPart] {
        let font = mathFont.fontInstance(size: fontSize)
        let glyphName = font.glyphName(for: glyph)

        guard let assemblyTable = _mathTable[kVertAssembly] as? [String: Any],
              let assemblyInfo = assemblyTable[glyphName] as? [String: Any],
              let parts = assemblyInfo[kAssemblyParts] as? [[String: Any]]
        else {
            return []
        }

        var rv = [GlyphPart]()
        for partInfo in parts {
            guard let adv = partInfo["advance"] as? Int,
                  let end = partInfo["endConnector"] as? Int,
                  let start = partInfo["startConnector"] as? Int,
                  let ext = partInfo["extender"] as? Int,
                  let glyphName = partInfo["glyph"] as? String
            else { continue }
            let fullAdvance = fontUnitsToPt(adv)
            let endConnectorLength = fontUnitsToPt(end)
            let startConnectorLength = fontUnitsToPt(start)
            let isExtender = ext != 0
            let glyph = font.glyph(named: glyphName)
            let part = GlyphPart(
                glyph: glyph, fullAdvance: fullAdvance,
                startConnectorLength: startConnectorLength,
                endConnectorLength: endConnectorLength,
                isExtender: isExtender,
            )
            rv.append(part)
        }
        return rv
    }
}
