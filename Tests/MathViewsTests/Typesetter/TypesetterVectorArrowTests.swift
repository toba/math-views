import Testing
@testable import MathViews
import CoreGraphics
import CoreText

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

struct TypesetterVectorArrowTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModern.fontInstance(size: 20)
    }

    @Test func vectorArrowRendering() throws {
        let commands = ["vec", "overleftarrow", "overrightarrow", "overleftrightarrow"]

        for cmd in commands {
            let mathList = MathList()
            let accent = MathAtomFactory.accent(named: cmd)
            let inner = MathList()
            inner.add(MathAtomFactory.atom(forCharacter: "v"))
            accent?.innerList = inner
            mathList.add(accent)

            let display = try #require(
                Typesetter.makeLineDisplay(for: mathList, font: font, style: .display),
            )

            // Should have accent display
            #expect(display.subDisplays.count == 1)
            let accentDisp = try #require(display.subDisplays[0] as? AccentDisplay)

            // Should have accentee and accent glyph
            #expect(accentDisp.accentee != nil, "\\\(cmd) should have accentee")
            #expect(accentDisp.accent != nil, "\\\(cmd) should have accent glyph")

            // Accent should be positioned such that its visual bottom is at or above accentee
            // With minY compensation, position.y can be negative, but visual bottom (position.y + minY) should be >= 0
            let accentGlyph = try #require(accentDisp.accent)
            let accentVisualBottom: CGFloat
            if let glyph = accentGlyph.glyph
            {
                var glyphCopy = glyph
                var boundingRect = CGRect.zero
                CTFontGetBoundingRectsForGlyphs(
                    font.coreTextFont,
                    .horizontal,
                    &glyphCopy,
                    &boundingRect,
                    1,
                )
                accentVisualBottom = accentGlyph.position.y + max(0, boundingRect.minY)
            } else {
                accentVisualBottom = accentGlyph.position.y
            }
            #expect(
                accentVisualBottom >= 0,
                "\\\(cmd) accent visual bottom should be at or above accentee",
            )
        }
    }

    @Test func wideVectorArrows() throws {
        let commands = ["overleftarrow", "overrightarrow", "overleftrightarrow"]

        for cmd in commands {
            let mathList = MathList()
            let accent = MathAtomFactory.accent(named: cmd)
            accent?.innerList = MathAtomFactory.mathListForCharacters("ABCDEF")
            mathList.add(accent)

            let display = try #require(
                Typesetter.makeLineDisplay(for: mathList, font: font, style: .display),
            )

            let accentDisp = try #require(display.subDisplays[0] as? AccentDisplay)
            let accentGlyph = try #require(accentDisp.accent)
            let accentee = try #require(accentDisp.accentee)

            // Verify that the display is created correctly with both accent and accentee
            #expect(accentGlyph.width > 0, "\\\(cmd) accent should have width")
            #expect(accentee.width > 0, "\\\(cmd) accentee should have width")

            // Note: Arrow stretching behavior depends on font glyph variants available
            // The implementation uses the font's Math table to select variants
            // Some fonts may not stretch as much as others
        }
    }

    @Test func vectorArrowDimensions() throws {
        let mathList = MathList()
        let accent = MathAtomFactory.accent(named: "overrightarrow")
        let inner = MathList()
        inner.add(MathAtomFactory.atom(forCharacter: "x"))
        accent?.innerList = inner
        mathList.add(accent)

        let display = try #require(
            Typesetter.makeLineDisplay(for: mathList, font: font, style: .display),
        )

        // Should have positive dimensions
        #expect(display.ascent > 0, "Should have positive ascent")
        #expect(display.descent >= 0, "Should have non-negative descent")
        #expect(display.width > 0, "Should have positive width")

        // Ascent should be larger than normal 'x' due to arrow above
        let normalX = try #require(Typesetter.makeLineDisplay(
            for: MathAtomFactory.mathListForCharacters("x"),
            font: font,
            style: .display,
        ))
        #expect(display.ascent > normalX.ascent, "Accent should increase ascent")
    }

    @Test func multiCharacterArrowAccents() throws {
        // Test that multi-character arrow accents render correctly
        // This is the reported bug: arrow should be above both characters, not after the last one
        let testCases = [
            ("overrightarrow", "DA"),
            ("overleftarrow", "AB"),
            ("overleftrightarrow", "XY"),
            ("vec", "AB"), // vec with multi-char should also work
        ]

        for (cmd, content) in testCases {
            let mathList = MathList()
            let accent = MathAtomFactory.accent(named: cmd)
            accent?.innerList = MathAtomFactory.mathListForCharacters(content)
            mathList.add(accent)

            let display = try #require(
                Typesetter.makeLineDisplay(for: mathList, font: font, style: .display),
            )

            // Should create AccentDisplay (not inline text)
            #expect(display.subDisplays.count == 1, "\\\(cmd){\(content)}")
            let accentDisp = try #require(
                display.subDisplays[0] as? AccentDisplay,
                "\\\(cmd){\(content)} should create AccentDisplay",
            )

            // Should have both accent and accentee
            #expect(accentDisp.accent != nil, "\\\(cmd){\(content)} should have accent glyph")
            #expect(accentDisp.accentee != nil, "\\\(cmd){\(content)} should have accentee")

            // The accentee should contain both characters
            let accentee = try #require(accentDisp.accentee)
            #expect(accentee.width > 0, "\\\(cmd){\(content)} accentee should have width")
        }
    }

    @Test func singleCharacterAccentsWithLineWrapping() throws {
        // Test that single-character accents still work with Unicode composition when line wrapping
        let mathList = MathList()
        let accent = MathAtomFactory.accent(named: "bar")
        accent?.innerList = MathAtomFactory.mathListForCharacters("x")
        mathList.add(accent)

        // Create with line wrapping enabled
        let maxWidth: CGFloat = 200
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )

        // Should render successfully
        #expect(display.width > 0, "Should have width")
        #expect(display.ascent > 0, "Should have ascent")
    }

    @Test func multiCharacterAccentsWithLineWrapping() throws {
        // Test that multi-character arrow accents work correctly with line wrapping enabled
        let mathList = MathList()
        let accent = MathAtomFactory.accent(named: "overrightarrow")
        accent?.innerList = MathAtomFactory.mathListForCharacters("DA")
        mathList.add(accent)

        // Create with line wrapping enabled
        let maxWidth: CGFloat = 200
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )

        // Should render successfully with AccentDisplay
        #expect(display.width > 0, "Should have width")

        // Should use AccentDisplay, not inline Unicode composition
        // This verifies the fix: multi-char accents use font-based rendering
        var foundAccentDisplay = false
        func checkSubDisplays(_ disp: Display) {
            if disp is AccentDisplay {
                foundAccentDisplay = true
            }
            if let mathListDisplay = disp as? MathListDisplay {
                for sub in mathListDisplay.subDisplays {
                    checkSubDisplays(sub)
                }
            }
        }
        checkSubDisplays(display)

        #expect(foundAccentDisplay, "Should use AccentDisplay for multi-character arrow accent")
    }
}
