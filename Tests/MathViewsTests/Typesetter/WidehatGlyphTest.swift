import Testing
import CoreText
@testable import MathViews
import Foundation
import CoreGraphics

struct WidehatGlyphTest {
    let font: FontInstance

    init() {
        font = MathFont.termes.fontInstance(size: 20)
    }

    @Test func widehatGlyphAvailability() {
        // Test what glyphs are available for widehat (circumflex accent)
        print("\n=== Widehat Glyph Analysis ===")

        let circumflexChar = "\u{0302}" // COMBINING CIRCUMFLEX ACCENT
        let baseGlyph = font.glyph(named: circumflexChar)
        let glyphName = font.glyphName(for: baseGlyph)

        print("Base circumflex character: U+0302")
        print("  Glyph ID: \(baseGlyph)")
        print("  Glyph name: \(glyphName)")

        // Check for horizontal variants
        if let mathTable = font.mathTable {
            let variants = mathTable.horizontalVariants(for: baseGlyph)
            print("  Found \(variants.count) horizontal variant(s)")

            for (index, variantGlyph) in variants.enumerated() {
                let variantName = font.glyphName(for: variantGlyph)

                var glyph = variantGlyph
                var advances = CGSize.zero
                CTFontGetAdvancesForGlyphs(font.coreTextFont, .horizontal, &glyph, &advances, 1)

                print(
                    "    [\(index)] \(variantName): width = \(String(format: "%.2f", advances.width))",
                )
            }
        }

        // Try named glyphs
        print("\nNamed glyph lookup:")
        let namedGlyphs = [
            "uni0302",
            "circumflex",
            "asciicircum",
        ]

        for name in namedGlyphs {
            let glyph = font.glyph(named: name)
            if glyph != 0 {
                let actualName = font.glyphName(for: glyph)
                print("  \(name) -> \(actualName) (glyph \(glyph))")
            } else {
                print("  \(name) -> NOT FOUND")
            }
        }
    }

    @Test func widetildeGlyphAvailability() {
        // Test what glyphs are available for widetilde
        print("\n=== Widetilde Glyph Analysis ===")

        let tildeChar = "\u{0303}" // COMBINING TILDE
        let baseGlyph = font.glyph(named: tildeChar)
        let glyphName = font.glyphName(for: baseGlyph)

        print("Base tilde character: U+0303")
        print("  Glyph ID: \(baseGlyph)")
        print("  Glyph name: \(glyphName)")

        // Check for horizontal variants
        if let mathTable = font.mathTable {
            let variants = mathTable.horizontalVariants(for: baseGlyph)
            print("  Found \(variants.count) horizontal variant(s)")

            for (index, variantGlyph) in variants.enumerated() {
                let variantName = font.glyphName(for: variantGlyph)

                var glyph = variantGlyph
                var advances = CGSize.zero
                CTFontGetAdvancesForGlyphs(font.coreTextFont, .horizontal, &glyph, &advances, 1)

                print(
                    "    [\(index)] \(variantName): width = \(String(format: "%.2f", advances.width))",
                )
            }
        }

        // Try named glyphs
        print("\nNamed glyph lookup:")
        let namedGlyphs = [
            "uni0303",
            "tilde",
            "asciitilde",
        ]

        for name in namedGlyphs {
            let glyph = font.glyph(named: name)
            if glyph != 0 {
                let actualName = font.glyphName(for: glyph)
                print("  \(name) -> \(actualName) (glyph \(glyph))")
            } else {
                print("  \(name) -> NOT FOUND")
            }
        }
    }

    @Test func currentWidehatBehavior() {
        // Test current behavior of \widehat vs \hat
        print("\n=== Current Widehat Behavior ===")

        let testCases = [
            ("\\hat{x}", "Single char hat"),
            ("\\widehat{x}", "Single char widehat"),
            ("\\hat{ABC}", "Multi-char hat"),
            ("\\widehat{ABC}", "Multi-char widehat"),
        ]

        for (latex, description) in testCases {
            let mathList = MathListBuilder.build(fromString: latex)
            let display = Typesetter.makeLineDisplay(for: mathList, font: font, style: .display)

            if let display,
               let accentDisp = display.subDisplays.first as? AccentDisplay,
               let accentee = accentDisp.accentee,
               let accent = accentDisp.accent
            {
                let coverage = accent.width / accentee.width * 100
                print("\n\(description): \(latex)")
                print("  Content width: \(String(format: "%.2f", accentee.width))")
                print("  Accent width: \(String(format: "%.2f", accent.width))")
                print("  Coverage: \(String(format: "%.1f", coverage))%")
            }
        }
    }
}
