import Testing
@testable import MathViews
import CoreGraphics

/// Tests for correct rendering of accented i and j characters.
/// When an accent is placed over 'i' or 'j', the dot should be removed
/// (using dotless variants imath/jmath) to avoid double dots.
struct DotlessIJAccentTests {
    let font: FontInstance

    init() {
        font = MathFont.termesFont.fontInstance(size: 20)
    }

    // MARK: - Accented i Tests

    @Test func circumflexOverI() {
        // Test that î (i with circumflex) uses the base dotless i character
        // that can be properly styled (roman in text mode, italic in math mode)
        let unicodeLatex = "î"

        let unicodeMathList = MathListBuilder.build(fromString: unicodeLatex)

        #expect(unicodeMathList != nil, "Unicode î should parse")
        #expect(unicodeMathList?.atoms.count == 1, "Should have exactly 1 atom")

        guard let unicodeAccent = unicodeMathList?.atoms.first as? Accent else {
            Issue.record("Should be Accent atom")
            return
        }

        guard let unicodeInner = unicodeAccent.innerList?.atoms.first else {
            Issue.record("Accent should have inner list")
            return
        }

        // The nucleus should be the base dotless i (U+0131) which can be styled
        let dotlessI = "\u{0131}" // Latin Small Letter Dotless I
        #expect(
            unicodeInner.nucleus == dotlessI,
            "Unicode î should use base dotless i (U+0131), got '\(unicodeInner.nucleus)'",
        )
    }

    @Test func explicitImathStillWorks() {
        // Test that explicit \hat{\imath} still works and uses the mathematical italic dotless i
        let explicitLatex = "\\hat{\\imath}"
        let explicitMathList = MathListBuilder.build(fromString: explicitLatex)

        #expect(explicitMathList != nil, "\\hat{\\imath} should parse")

        guard let explicitAccent = explicitMathList?.atoms.first as? Accent,
              let explicitInner = explicitAccent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        // Explicit \imath uses the mathematical italic dotless i (U+1D6A4)
        let mathItalicDotlessI = "\u{0001D6A4}"
        #expect(
            explicitInner.nucleus == mathItalicDotlessI,
            "\\imath should use mathematical italic dotless i (U+1D6A4)",
        )
    }

    @Test func dieresisOverI() {
        // Test that ï (i with dieresis/umlaut) uses base dotless i
        let unicodeLatex = "ï"
        let unicodeMathList = MathListBuilder.build(fromString: unicodeLatex)

        #expect(unicodeMathList != nil, "Unicode ï should parse")

        guard let unicodeAccent = unicodeMathList?.atoms.first as? Accent,
              let unicodeInner = unicodeAccent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        let dotlessI = "\u{0131}" // Latin Small Letter Dotless I
        #expect(
            unicodeInner.nucleus == dotlessI,
            "Unicode ï should use base dotless i (U+0131), got '\(unicodeInner.nucleus)'",
        )
    }

    @Test func acuteOverI() {
        // Test that í (i with acute) uses base dotless i
        let unicodeLatex = "í"
        let unicodeMathList = MathListBuilder.build(fromString: unicodeLatex)

        guard let unicodeAccent = unicodeMathList?.atoms.first as? Accent,
              let unicodeInner = unicodeAccent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        let dotlessI = "\u{0131}" // Latin Small Letter Dotless I
        #expect(
            unicodeInner.nucleus == dotlessI,
            "Unicode í should use base dotless i (U+0131), got '\(unicodeInner.nucleus)'",
        )
    }

    @Test func graveOverI() {
        // Test that ì (i with grave) uses dotless i
        let unicodeLatex = "ì"

        let unicodeMathList = MathListBuilder.build(fromString: unicodeLatex)

        guard let unicodeAccent = unicodeMathList?.atoms.first as? Accent,
              let unicodeInner = unicodeAccent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        let dotlessI = "\u{0131}" // Latin Small Letter Dotless I
        #expect(
            unicodeInner.nucleus == dotlessI,
            "Unicode ì should use dotless i (\\imath), got '\(unicodeInner.nucleus)'",
        )
    }

    // MARK: - Accented j Tests

    @Test func circumflexOverJ() {
        // Test that ĵ (j with circumflex) uses dotless j
        let unicodeLatex = "ĵ"
        let unicodeMathList = MathListBuilder.build(fromString: unicodeLatex)

        #expect(unicodeMathList != nil, "Unicode ĵ should parse")
        #expect(unicodeMathList?.atoms.count == 1, "Should have exactly 1 atom")

        guard let unicodeAccent = unicodeMathList?.atoms.first as? Accent else {
            Issue.record("Should be Accent atom")
            return
        }

        guard let unicodeInner = unicodeAccent.innerList?.atoms.first else {
            Issue.record("Accent should have inner list")
            return
        }

        // The nucleus should be the base dotless j (U+0237) which can be styled
        let dotlessJ = "\u{0237}" // Latin Small Letter Dotless J
        #expect(
            unicodeInner.nucleus == dotlessJ,
            "Unicode ĵ should use base dotless j (U+0237), got '\(unicodeInner.nucleus)'",
        )
    }

    @Test func textModeAccentedJ() {
        // Test that ĵ in text mode uses dotless j with roman font style
        let latex = "\\text{ĵ}"
        let mathList = MathListBuilder.build(fromString: latex)

        #expect(mathList != nil, "\\text{ĵ} should parse")

        // Helper to recursively find accents
        func findAccents(in list: MathList?) -> [Accent] {
            var accents: [Accent] = []
            for atom in list?.atoms ?? [] {
                if let accent = atom as? Accent {
                    accents.append(accent)
                }
                if let inner = atom as? Inner {
                    accents.append(contentsOf: findAccents(in: inner.innerList))
                }
            }
            return accents
        }

        let accents = findAccents(in: mathList)
        #expect(accents.count == 1, "Should find 1 accent")

        if let accent = accents.first, let inner = accent.innerList?.atoms.first {
            let dotlessJ = "\u{0237}"
            #expect(
                inner.nucleus == dotlessJ,
                "Should use base dotless j",
            )
            #expect(
                inner.fontStyle == .roman,
                "In \\text{}, should have roman style, got \(inner.fontStyle)",
            )
        }
    }

    @Test func accentedJRendersCorrectly() {
        // Test that ĵ renders without crashing
        let latex = "ĵ"
        let mathList = MathListBuilder.build(fromString: latex)
        let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

        #expect(display != nil, "ĵ should render successfully")
    }

    // MARK: - Uppercase I Tests (should NOT use dotless variant)

    @Test func circumflexOverUppercaseI() {
        // Uppercase I does not have a dot, so it should remain as I
        let unicodeLatex = "Î"

        let unicodeMathList = MathListBuilder.build(fromString: unicodeLatex)

        guard let unicodeAccent = unicodeMathList?.atoms.first as? Accent,
              let unicodeInner = unicodeAccent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        #expect(
            unicodeInner.nucleus == "I",
            "Uppercase Î should use regular I, got '\(unicodeInner.nucleus)'",
        )
    }

    // MARK: - Visual Rendering Tests

    @Test func accentedIRendersWithoutDoubleDot() {
        // Verify that the rendered output doesn't have a double dot
        let latex = "î"
        let mathList = MathListBuilder.build(fromString: latex)
        let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

        #expect(display != nil, "î should render successfully")

        // The display should have exactly one accent display
        guard let accentDisplay = display?.subDisplays.first as? AccentDisplay else {
            Issue.record("Should have an AccentDisplay")
            return
        }

        // Verify the accentee exists
        #expect(
            accentDisplay.accentee != nil,
            "Accent should have an accentee (the base character)",
        )
        #expect(accentDisplay.accent != nil, "Accent should have an accent glyph")
    }

    @Test func multipleAccentedICharacters() {
        // Test a string with multiple accented i characters
        let latex = "îïíì"
        let mathList = MathListBuilder.build(fromString: latex)

        #expect(mathList != nil, "Multiple accented i chars should parse")
        #expect(mathList?.atoms.count == 4, "Should have 4 atoms")

        let dotlessI = "\u{0131}" // Latin Small Letter Dotless I
        for (index, atom) in (mathList?.atoms ?? []).enumerated() {
            guard let accent = atom as? Accent,
                  let inner = accent.innerList?.atoms.first
            else {
                Issue.record("Atom \(index) should be an accent with inner list")
                continue
            }
            #expect(
                inner.nucleus == dotlessI,
                "Atom \(index) should use dotless i, got '\(inner.nucleus)'",
            )
        }
    }

    // MARK: - Regression Tests

    @Test func explicitHatIStillUsesRegularI() {
        // When user explicitly writes \hat{i}, it should still use regular 'i'
        // Only Unicode accented characters should convert to dotless
        let latex = "\\hat{i}"
        let mathList = MathListBuilder.build(fromString: latex)

        guard let accent = mathList?.atoms.first as? Accent,
              let inner = accent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        // Explicit \hat{i} should keep the regular 'i'
        #expect(
            inner.nucleus == "i",
            "Explicit \\hat{i} should use regular 'i', got '\(inner.nucleus)'",
        )
    }

    struct AccentedCharCase: Sendable, CustomTestStringConvertible {
        let unicode: String
        let expectedBase: String
        var testDescription: String { "\(unicode) -> \(expectedBase)" }

        static let otherAccented: [AccentedCharCase] = [
            AccentedCharCase(unicode: "é", expectedBase: "e"),
            AccentedCharCase(unicode: "ñ", expectedBase: "n"),
            AccentedCharCase(unicode: "ü", expectedBase: "u"),
            AccentedCharCase(unicode: "â", expectedBase: "a"),
            AccentedCharCase(unicode: "ô", expectedBase: "o"),
        ]

        static let uppercaseAccented: [AccentedCharCase] = [
            AccentedCharCase(unicode: "Î", expectedBase: "I"), // circumflex
            AccentedCharCase(unicode: "Ï", expectedBase: "I"), // dieresis
            AccentedCharCase(unicode: "Í", expectedBase: "I"), // acute
            AccentedCharCase(unicode: "Ì", expectedBase: "I"), // grave
        ]
    }

    @Test(arguments: AccentedCharCase.otherAccented)
    func otherAccentedCharactersStillWork(_ testCase: AccentedCharCase) {
        // Verify that other accented characters (not i/j) still work correctly
        let mathList = MathListBuilder.build(fromString: testCase.unicode)

        guard let accent = mathList?.atoms.first as? Accent,
              let inner = accent.innerList?.atoms.first
        else {
            Issue.record("\(testCase.unicode) should parse as accent with inner list")
            return
        }

        #expect(
            inner.nucleus == testCase.expectedBase,
            "\(testCase.unicode) should have base '\(testCase.expectedBase)', got '\(inner.nucleus)'",
        )
    }

    @Test func latexRoundTripConversion() {
        // Test that Unicode î converts to LaTeX properly
        let unicodeLatex = "î"
        let mathList = MathListBuilder.build(fromString: unicodeLatex)

        // Convert back to LaTeX
        let latexOutput = MathListBuilder.mathListToString(mathList)

        // The output should contain \hat with the dotless i character (U+0131)
        #expect(
            latexOutput.contains("hat"),
            "LaTeX output should contain 'hat', got '\(latexOutput)'",
        )
        // The base character should be the dotless i (either as raw char or command)
        let dotlessI = "\u{0131}"
        #expect(
            latexOutput.contains(dotlessI) || latexOutput.contains("dotlessi"),
            "LaTeX output should contain dotless i, got '\(latexOutput)'",
        )
    }

    @Test func textModeAccentedI() {
        // Test that accented i in text mode renders successfully and uses dotless i
        // with the correct font style (roman, not italic)
        let latex = "\\text{naïve}"
        let mathList = MathListBuilder.build(fromString: latex)

        #expect(mathList != nil, "\\text{naïve} should parse")

        // Helper function to recursively find accent atoms
        func findAccents(in list: MathList?) -> [Accent] {
            var accents: [Accent] = []
            for atom in list?.atoms ?? [] {
                if let accent = atom as? Accent {
                    accents.append(accent)
                }
                if let inner = atom as? Inner {
                    accents.append(contentsOf: findAccents(in: inner.innerList))
                }
            }
            return accents
        }

        let accents = findAccents(in: mathList)

        // Should find exactly one accent (the ï)
        #expect(accents.count == 1, "Should find exactly 1 accent atom in \\text{naïve}")

        if let accent = accents.first, let inner = accent.innerList?.atoms.first {
            // The accent should use dotless i
            let dotlessI = "\u{0131}" // Latin Small Letter Dotless I
            #expect(
                inner.nucleus == dotlessI,
                "Accented i in text mode should use dotless i, got '\(inner.nucleus)'",
            )

            // CRITICAL: The inner atom should have roman font style in text mode,
            // not defaultStyle (which renders as italic in math mode)
            #expect(
                inner.fontStyle == .roman,
                "Dotless i in \\text{} should have roman font style, got \(inner.fontStyle)",
            )
        }
    }

    @Test(arguments: AccentedCharCase.uppercaseAccented)
    func uppercaseAccentedCharsNotAffected(_ testCase: AccentedCharCase) {
        // All uppercase accented characters should NOT use dotless variants
        let mathList = MathListBuilder.build(fromString: testCase.unicode)

        guard let accent = mathList?.atoms.first as? Accent,
              let inner = accent.innerList?.atoms.first
        else {
            Issue.record("\(testCase.unicode) should parse as accent with inner list")
            return
        }

        #expect(
            inner.nucleus == testCase.expectedBase,
            "\(testCase.unicode) should have base '\(testCase.expectedBase)', got '\(inner.nucleus)'",
        )
    }

    @Test func mixedExpressionWithAccentedI() {
        // Test a more complex expression mixing regular and accented characters
        let latex = "x + î = y"
        let mathList = MathListBuilder.build(fromString: latex)

        #expect(mathList != nil, "Mixed expression should parse")

        // Find the accent (should be the 3rd atom: x, +, î, =, y)
        var foundAccent = false
        let dotlessI = "\u{0131}" // Latin Small Letter Dotless I
        for atom in mathList?.atoms ?? [] {
            if let accent = atom as? Accent {
                foundAccent = true
                if let inner = accent.innerList?.atoms.first {
                    #expect(
                        inner.nucleus == dotlessI,
                        "Accented i in expression should use dotless i",
                    )
                }
            }
        }
        #expect(foundAccent, "Should find an accent in mixed expression")
    }

    // MARK: - Font Style Tests for All Accented Characters

    @Test func textModeOtherAccentedCharactersFontStyle() {
        // Test that other accented characters (not i/j) preserve font style in text mode
        // These use regular ASCII base characters which should be styled correctly
        let latex = "\\text{naïve café résumé}"
        let mathList = MathListBuilder.build(fromString: latex)

        #expect(mathList != nil, "Text with accented chars should parse")

        // Helper to recursively find all accents
        func findAccents(in list: MathList?) -> [Accent] {
            var accents: [Accent] = []
            for atom in list?.atoms ?? [] {
                if let accent = atom as? Accent {
                    accents.append(accent)
                }
                if let inner = atom as? Inner {
                    accents.append(contentsOf: findAccents(in: inner.innerList))
                }
            }
            return accents
        }

        let accents = findAccents(in: mathList)

        // Should find accents for ï, é (twice), é
        #expect(
            accents.count >= 3,
            "Should find at least 3 accents in '\\text{naïve café résumé}'",
        )

        // Check that all accents have roman font style in text mode
        for accent in accents {
            if let inner = accent.innerList?.atoms.first {
                #expect(
                    inner.fontStyle == .roman,
                    "Accent inner atom should have roman style in \\text{}, got \(inner.fontStyle) for '\(inner.nucleus)'",
                )
            }
        }
    }

    @Test func mathModeAccentedCharactersFontStyle() {
        // In math mode (default), accented characters should have default style
        // which renders as italic for letters
        let latex = "é" // Just é in math mode
        let mathList = MathListBuilder.build(fromString: latex)

        guard let accent = mathList?.atoms.first as? Accent,
              let inner = accent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        // In math mode without explicit font command, atoms have defaultStyle
        // The actual rendering will italicize it
        #expect(
            inner.fontStyle == .defaultStyle,
            "In math mode, accent inner should have defaultStyle",
        )
        #expect(
            inner.nucleus == "e",
            "Base character should be 'e'",
        )
    }

    @Test func boldAccentedCharacters() {
        // Test accented characters in bold mode
        let latex = "\\mathbf{é}"
        let mathList = MathListBuilder.build(fromString: latex)

        guard let accent = mathList?.atoms.first as? Accent,
              let inner = accent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        #expect(
            inner.fontStyle == .bold,
            "In \\mathbf{}, accent inner should have bold style, got \(inner.fontStyle)",
        )
    }

    @Test func italicAccentedI() {
        // Test that î in mathit mode uses italic (via the styling system)
        let latex = "\\mathit{î}"
        let mathList = MathListBuilder.build(fromString: latex)

        guard let accent = mathList?.atoms.first as? Accent,
              let inner = accent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        // Should use base dotless i with italic font style
        let dotlessI = "\u{0131}"
        #expect(
            inner.nucleus == dotlessI,
            "Should use base dotless i",
        )
        #expect(
            inner.fontStyle == .italic,
            "In \\mathit{}, should have italic style, got \(inner.fontStyle)",
        )
    }

    @Test func romanAccentedI() {
        // Test that î in mathrm mode uses roman dotless i
        let latex = "\\mathrm{î}"
        let mathList = MathListBuilder.build(fromString: latex)

        guard let accent = mathList?.atoms.first as? Accent,
              let inner = accent.innerList?.atoms.first
        else {
            Issue.record("Should parse as accent with inner list")
            return
        }

        // Should use base dotless i with roman font style
        let dotlessI = "\u{0131}"
        #expect(
            inner.nucleus == dotlessI,
            "Should use base dotless i",
        )
        #expect(
            inner.fontStyle == .roman,
            "In \\mathrm{}, should have roman style, got \(inner.fontStyle)",
        )
    }

    // MARK: - Special Character Tests

    @Test(arguments: ["ç", "å", "æ", "œ", "ß"])
    func specialCharactersInMathMode(_ char: String) {
        // Test special characters in math mode - should render without crashing
        let mathList = MathListBuilder.build(fromString: char)
        #expect(mathList != nil, "\(char) should parse in math mode")
        #expect(mathList?.atoms.count == 1, "\(char) should produce 1 atom")

        // Test rendering - this should not crash
        let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)
        #expect(display != nil, "\(char) should render without crashing")
    }

    @Test func specialCharactersInTextMode() {
        // Test special characters in text mode
        let latex = "\\text{ça va? æther œuvre süß}"
        let mathList = MathListBuilder.build(fromString: latex)

        #expect(mathList != nil, "Text with special chars should parse")

        // Test rendering - should not crash
        let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)
        #expect(display != nil, "Special chars in text mode should render")
    }

    @Test(arguments: [
        // Acute
        "á", "é", "í", "ó", "ú", "ý",
        "Á", "É", "Í", "Ó", "Ú", "Ý",
        // Grave
        "à", "è", "ì", "ò", "ù",
        "À", "È", "Ì", "Ò", "Ù",
        // Circumflex
        "â", "ê", "î", "ô", "û",
        "Â", "Ê", "Î", "Ô", "Û",
        // Umlaut/dieresis
        "ä", "ë", "ï", "ö", "ü", "ÿ",
        "Ä", "Ë", "Ï", "Ö", "Ü",
        // Tilde
        "ã", "ñ", "õ",
        "Ã", "Ñ", "Õ",
        // Special
        "ç", "ø", "å", "æ", "œ", "ß",
        "Ç", "Ø", "Å", "Æ", "Œ",
    ])
    func allSupportedAccentedCharactersRender(_ char: String) {
        // Comprehensive test: all supported accented characters should render
        let mathList = MathListBuilder.build(fromString: char)
        #expect(mathList != nil, "\(char) should parse")

        // Render in math mode - should not crash
        let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)
        #expect(display != nil, "\(char) should render in math mode without crashing")
    }

    @Test(arguments: [
        "á", "é", "í", "ó", "ú", "ý",
        "à", "è", "ì", "ò", "ù",
        "â", "ê", "î", "ô", "û",
        "ä", "ë", "ï", "ö", "ü", "ÿ",
        "ã", "ñ", "õ",
    ])
    func allAccentedCharactersInTextMode(_ char: String) {
        // Test all accented characters in text mode with roman font
        let latex = "\\text{\(char)}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "\\text{\(char)} should parse")

        // Render - should not crash
        let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)
        #expect(display != nil, "\\text{\(char)} should render without crashing")
    }
}
