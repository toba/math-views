import CoreGraphics
import Testing
@testable import MathViews

struct ArrowStretchingTest {

    let font: FontInstance

    init() {
        font = FontManager().termesFont(withSize: 20)!
    }

    @Test func vecSingleCharacter() throws {
        // Test that \vec{v} produces an arrow (not a bar)
        let mathList = MathList()
        let vec = MathAtomFactory.accent(withName: "vec")
        vec?.innerList = MathAtomFactory.mathListForCharacters("v")
        mathList.add(vec)

        let display = try #require(
            Typesetter.createLineForMathList(mathList, font: font, style: .display)
        )

        #expect(display.subDisplays.count == 1, "Should have 1 subdisplay")
        let accentDisp = try #require(display.subDisplays[0] as? AccentDisplay)

        _ = try #require(accentDisp.accentee)
        let accentGlyph = try #require(accentDisp.accent)

        // The arrow should have non-zero width
        #expect(accentGlyph.width > 0, "Arrow should have width > 0")

        // For single character, the arrow should be reasonably sized (not 0 like a bar)
        // uni20D7.h1 has width ~12.14
        #expect(accentGlyph.width > 10, "Arrow should be at least 10 points wide")
    }

    @Test func vecMultipleCharacters() throws {
        // Test that \vec{AB} uses small arrow (NOT stretchy like \overrightarrow{AB})
        let mathList = MathList()
        let vec = MathAtomFactory.accent(withName: "vec")
        vec?.innerList = MathAtomFactory.mathListForCharacters("AB")
        mathList.add(vec)

        let display = try #require(
            Typesetter.createLineForMathList(mathList, font: font, style: .display)
        )

        #expect(display.subDisplays.count == 1, "Should have 1 subdisplay")
        let accentDisp = try #require(display.subDisplays[0] as? AccentDisplay)

        _ = try #require(accentDisp.accentee)
        let accentGlyph = try #require(accentDisp.accent)

        // \vec should use small fixed arrow, NOT stretch to content width
        // The arrow should be the small uni20D7.h1 variant (~12.14 wide)
        #expect(accentGlyph.width < 15, "\\vec should use small arrow, not stretch")
        #expect(accentGlyph.width > 10, "Arrow should be uni20D7.h1 variant")
    }

    @Test func arrowStretchingForDA() throws {
        // Test the reported issue: arrow should stretch to match "DA" width
        let mathList = MathList()
        let accent = MathAtomFactory.accent(withName: "overrightarrow")
        accent?.innerList = MathAtomFactory.mathListForCharacters("DA")
        mathList.add(accent)

        let display = try #require(
            Typesetter.createLineForMathList(mathList, font: font, style: .display)
        )

        #expect(display.subDisplays.count == 1, "Should have 1 subdisplay")
        let accentDisp = try #require(display.subDisplays[0] as? AccentDisplay)

        let accentee = try #require(accentDisp.accentee)
        let accentGlyph = try #require(accentDisp.accent)

        let ratio = accentGlyph.width / accentee.width

        // For proper rendering, the arrow should cover at least 90% of the content width
        #expect(ratio > 0.9, "Arrow should cover at least 90% of content width")
        #expect(accentee.width > 0, "Accentee should have width")
        #expect(accentGlyph.width > 0, "Arrow should have width")
    }

    struct ArrowCase: Sendable, CustomTestStringConvertible {
        let content: String
        let command: String
        var testDescription: String { "\\\(command){\(content)}" }

        static let all: [ArrowCase] = [
            ArrowCase(content: "A", command: "overrightarrow"),
            ArrowCase(content: "DA", command: "overrightarrow"),
            ArrowCase(content: "ABC", command: "overrightarrow"),
            ArrowCase(content: "ABCD", command: "overrightarrow"),
            ArrowCase(content: "velocity", command: "overleftrightarrow"),
        ]
    }

    @Test(arguments: ArrowCase.all)
    func arrowStretchingComparison(_ testCase: ArrowCase) throws {
        // Compare arrow stretching for different content widths
        let mathList = MathList()
        let accent = MathAtomFactory.accent(withName: testCase.command)
        accent?.innerList = MathAtomFactory.mathListForCharacters(testCase.content)
        mathList.add(accent)

        let display = try #require(
            Typesetter.createLineForMathList(mathList, font: font, style: .display)
        )

        let accentDisp = try #require(display.subDisplays[0] as? AccentDisplay)
        let accentee = try #require(accentDisp.accentee)
        let accentGlyph = try #require(accentDisp.accent)

        let ratio = accentGlyph.width / accentee.width
        #expect(ratio > 0.9, "\\\(testCase.command){\(testCase.content)} should have adequate arrow coverage")
    }

    @Test func regularAccentVsArrowAccent() throws {
        // Compare how regular accents (bar, hat) behave vs arrow accents

        // Test \bar{DA} - regular accent
        let barList = MathList()
        let barAccent = MathAtomFactory.accent(withName: "bar")
        barAccent?.innerList = MathAtomFactory.mathListForCharacters("DA")
        barList.add(barAccent)

        let barDisplay = try #require(
            Typesetter.createLineForMathList(barList, font: font, style: .display)
        )

        let barAccentDisp = try #require(barDisplay.subDisplays[0] as? AccentDisplay)
        _ = try #require(barAccentDisp.accentee)
        _ = try #require(barAccentDisp.accent)

        // Test \overrightarrow{DA} - arrow accent
        let arrowList = MathList()
        let arrowAccent = MathAtomFactory.accent(withName: "overrightarrow")
        arrowAccent?.innerList = MathAtomFactory.mathListForCharacters("DA")
        arrowList.add(arrowAccent)

        let arrowDisplay = try #require(
            Typesetter.createLineForMathList(arrowList, font: font, style: .display)
        )

        let arrowAccentDisp = try #require(arrowDisplay.subDisplays[0] as? AccentDisplay)
        let arrowAccentee = try #require(arrowAccentDisp.accentee)
        let arrowGlyph = try #require(arrowAccentDisp.accent)

        let arrowRatio = arrowGlyph.width / arrowAccentee.width

        // Regular accents (bar) can be narrower than content
        // Arrow accents should stretch to match content width
        #expect(arrowRatio > 0.9, "Arrow accents should stretch to match content")
    }

}
