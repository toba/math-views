import XCTest
@testable import MathViews

final class ArrowStretchingTest: XCTestCase {

    var font: MTFont!

    override func setUp() {
        super.setUp()
        font = FontManager().termesFont(withSize: 20)
    }

    func testVecSingleCharacter() throws {
        // Test that \vec{v} produces an arrow (not a bar)
        let mathList = MathList()
        let vec = MathAtomFactory.accent(withName: "vec")
        vec?.innerList = MathAtomFactory.mathListForCharacters("v")
        mathList.add(vec)

        let display = try XCTUnwrap(
            Typesetter.createLineForMathList(mathList, font: self.font, style: .display)
        )

        XCTAssertEqual(display.subDisplays.count, 1, "Should have 1 subdisplay")
        let accentDisp = try XCTUnwrap(display.subDisplays[0] as? AccentDisplay)

        _ = try XCTUnwrap(accentDisp.accentee)
        let accentGlyph = try XCTUnwrap(accentDisp.accent)

        // The arrow should have non-zero width
        XCTAssertGreaterThan(accentGlyph.width, 0, "Arrow should have width > 0")

        // For single character, the arrow should be reasonably sized (not 0 like a bar)
        // uni20D7.h1 has width ~12.14
        XCTAssertGreaterThan(accentGlyph.width, 10, "Arrow should be at least 10 points wide")
    }

    func testVecMultipleCharacters() throws {
        // Test that \vec{AB} uses small arrow (NOT stretchy like \overrightarrow{AB})
        let mathList = MathList()
        let vec = MathAtomFactory.accent(withName: "vec")
        vec?.innerList = MathAtomFactory.mathListForCharacters("AB")
        mathList.add(vec)

        let display = try XCTUnwrap(
            Typesetter.createLineForMathList(mathList, font: self.font, style: .display)
        )

        XCTAssertEqual(display.subDisplays.count, 1, "Should have 1 subdisplay")
        let accentDisp = try XCTUnwrap(display.subDisplays[0] as? AccentDisplay)

        _ = try XCTUnwrap(accentDisp.accentee)
        let accentGlyph = try XCTUnwrap(accentDisp.accent)

        // \vec should use small fixed arrow, NOT stretch to content width
        // The arrow should be the small uni20D7.h1 variant (~12.14 wide)
        XCTAssertLessThan(accentGlyph.width, 15, "\\vec should use small arrow, not stretch")
        XCTAssertGreaterThan(accentGlyph.width, 10, "Arrow should be uni20D7.h1 variant")
    }

    func testArrowStretchingForDA() throws {
        // Test the reported issue: arrow should stretch to match "DA" width
        let mathList = MathList()
        let accent = MathAtomFactory.accent(withName: "overrightarrow")
        accent?.innerList = MathAtomFactory.mathListForCharacters("DA")
        mathList.add(accent)

        let display = try XCTUnwrap(
            Typesetter.createLineForMathList(mathList, font: self.font, style: .display)
        )

        XCTAssertEqual(display.subDisplays.count, 1, "Should have 1 subdisplay")
        let accentDisp = try XCTUnwrap(display.subDisplays[0] as? AccentDisplay)

        let accentee = try XCTUnwrap(accentDisp.accentee)
        let accentGlyph = try XCTUnwrap(accentDisp.accent)

        let ratio = accentGlyph.width / accentee.width

        // For proper rendering, the arrow should cover at least 90% of the content width
        XCTAssertGreaterThan(ratio, 0.9, "Arrow should cover at least 90% of content width")
        XCTAssertGreaterThan(accentee.width, 0, "Accentee should have width")
        XCTAssertGreaterThan(accentGlyph.width, 0, "Arrow should have width")
    }

    func testArrowStretchingComparison() throws {
        // Compare arrow stretching for different content widths
        let testCases = [
            ("A", "overrightarrow"),
            ("DA", "overrightarrow"),
            ("ABC", "overrightarrow"),
            ("ABCD", "overrightarrow"),
            ("velocity", "overleftrightarrow")
        ]

        for (content, command) in testCases {
            let mathList = MathList()
            let accent = MathAtomFactory.accent(withName: command)
            accent?.innerList = MathAtomFactory.mathListForCharacters(content)
            mathList.add(accent)

            let display = try XCTUnwrap(
                Typesetter.createLineForMathList(mathList, font: self.font, style: .display)
            )

            let accentDisp = try XCTUnwrap(display.subDisplays[0] as? AccentDisplay)
            let accentee = try XCTUnwrap(accentDisp.accentee)
            let accentGlyph = try XCTUnwrap(accentDisp.accent)

            let ratio = accentGlyph.width / accentee.width
            XCTAssertGreaterThan(ratio, 0.9, "\\\(command){\(content)} should have adequate arrow coverage")
        }
    }

    func testRegularAccentVsArrowAccent() throws {
        // Compare how regular accents (bar, hat) behave vs arrow accents

        // Test \bar{DA} - regular accent
        let barList = MathList()
        let barAccent = MathAtomFactory.accent(withName: "bar")
        barAccent?.innerList = MathAtomFactory.mathListForCharacters("DA")
        barList.add(barAccent)

        let barDisplay = try XCTUnwrap(
            Typesetter.createLineForMathList(barList, font: self.font, style: .display)
        )

        let barAccentDisp = try XCTUnwrap(barDisplay.subDisplays[0] as? AccentDisplay)
        _ = try XCTUnwrap(barAccentDisp.accentee)
        _ = try XCTUnwrap(barAccentDisp.accent)

        // Test \overrightarrow{DA} - arrow accent
        let arrowList = MathList()
        let arrowAccent = MathAtomFactory.accent(withName: "overrightarrow")
        arrowAccent?.innerList = MathAtomFactory.mathListForCharacters("DA")
        arrowList.add(arrowAccent)

        let arrowDisplay = try XCTUnwrap(
            Typesetter.createLineForMathList(arrowList, font: self.font, style: .display)
        )

        let arrowAccentDisp = try XCTUnwrap(arrowDisplay.subDisplays[0] as? AccentDisplay)
        let arrowAccentee = try XCTUnwrap(arrowAccentDisp.accentee)
        let arrowGlyph = try XCTUnwrap(arrowAccentDisp.accent)

        let arrowRatio = arrowGlyph.width / arrowAccentee.width

        // Regular accents (bar) can be narrower than content
        // Arrow accents should stretch to match content width
        XCTAssertGreaterThan(arrowRatio, 0.9, "Arrow accents should stretch to match content")
    }

}
