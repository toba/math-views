import XCTest
@testable import MathViews

class MTDisplayGeneratorTests: XCTestCase {

    var font: MTFont!
    var generator: DisplayGenerator!

    override func setUp() {
        super.setUp()
        font = MTFont(fontWithName: "latinmodern-math", size: 20)
        generator = DisplayGenerator(font: font, style: .display)
    }

    override func tearDown() {
        font = nil
        generator = nil
        super.tearDown()
    }

    // MARK: - Basic Generation Tests

    func testGenerateFromEmptyLines() {
        let displays = generator.generateDisplays(from: [], startPosition: .zero)
        XCTAssertEqual(displays.count, 0)
    }

    func testGenerateSingleLine() {
        let element = createTextElement("x", width: 10)
        let lines = [[element]]

        let displays = generator.generateDisplays(from: lines, startPosition: .zero)

        XCTAssertGreaterThan(displays.count, 0)
    }

    func testGenerateMultipleLines() {
        let line1 = [createTextElement("x", width: 10), createTextElement("+", width: 10)]
        let line2 = [createTextElement("y", width: 10)]
        let lines = [line1, line2]

        let displays = generator.generateDisplays(from: lines, startPosition: .zero)

        XCTAssertGreaterThan(displays.count, 0)
    }

    func testGenerateWithPrerenderedDisplay() {
        let preDisplay = Display()
        preDisplay.width = 20
        preDisplay.ascent = 10
        preDisplay.descent = 5

        let element = createDisplayElement(preDisplay)
        let lines = [[element]]

        let displays = generator.generateDisplays(from: lines, startPosition: .zero)

        XCTAssertGreaterThan(displays.count, 0)
    }

    func testVerticalSpacingBetweenLines() {
        let line1 = [createTextElement("a", width: 10)]
        let line2 = [createTextElement("b", width: 10)]
        let lines = [line1, line2]

        let displays = generator.generateDisplays(from: lines, startPosition: CGPoint(x: 0, y: 0))

        // With multiple lines, y positions should differ
        if displays.count >= 2 {
            let y1 = displays[0].position.y
            let y2 = displays[1].position.y
            XCTAssertNotEqual(y1, y2, "Lines should have different y positions")
        }
    }

    // MARK: - Helper Methods

    private func createTextElement(_ text: String, width: CGFloat) -> BreakableElement {
        let atom = MathAtom(type: .ordinary, value: text)
        return BreakableElement(
            content: .text(text),
            width: width,
            height: 10,
            ascent: 8,
            descent: 2,
            isBreakBefore: true,
            isBreakAfter: true,
            penaltyBefore: BreakPenalty.good,
            penaltyAfter: BreakPenalty.good,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: NSMakeRange(0, 1),
            color: nil,
            backgroundColor: nil,
            indivisible: false
        )
    }

    private func createDisplayElement(_ display: Display) -> BreakableElement {
        let atom = MathAtom(type: .fraction, value: "")
        return BreakableElement(
            content: .display(display),
            width: display.width,
            height: display.ascent + display.descent,
            ascent: display.ascent,
            descent: display.descent,
            isBreakBefore: true,
            isBreakAfter: true,
            penaltyBefore: BreakPenalty.moderate,
            penaltyAfter: BreakPenalty.moderate,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: NSMakeRange(0, 1),
            color: nil,
            backgroundColor: nil,
            indivisible: true
        )
    }
}
