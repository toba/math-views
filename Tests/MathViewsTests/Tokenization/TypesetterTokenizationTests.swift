import XCTest
@testable import MathViews

class TypesetterTokenizationTests: XCTestCase {

    var font: FontInstance!

    override func setUp() {
        super.setUp()
        font = FontInstance(fontWithName: "latinmodern-math", size: 20)
    }

    override func tearDown() {
        font = nil
        super.tearDown()
    }

    // MARK: - Integration Tests

    func testSimpleExpression() {
        // x + y
        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))
        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "y"))

        let display = Typesetter.createLineForMathListWithTokenization(
            mathList,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 0
        )

        XCTAssertNotNil(display)
        XCTAssertGreaterThan(display!.width, 0)
        XCTAssertGreaterThan(display!.subDisplays.count, 0)
    }

    func testExpressionWithWidthConstraint() {
        // Create a long expression
        let mathList = MathList()
        for i in 0..<10 {
            mathList.add(MathAtom(type: .variable, value: "x"))
            if i < 9 {
                mathList.add(MathAtom(type: .binaryOperator, value: "+"))
            }
        }

        let display = Typesetter.createLineForMathListWithTokenization(
            mathList,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 150
        )

        XCTAssertNotNil(display)
        // With width constraint, should create multiple lines
        // Check that display has reasonable dimensions
        XCTAssertGreaterThan(display!.subDisplays.count, 0)
    }

    func testExpressionWithScripts() {
        // x^2 + y
        let mathList = MathList()

        let x = MathAtom(type: .variable, value: "x")
        let superScript = MathList()
        superScript.add(MathAtom(type: .number, value: "2"))
        x.superScript = superScript
        mathList.add(x)

        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "y"))

        let display = Typesetter.createLineForMathListWithTokenization(
            mathList,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 0
        )

        XCTAssertNotNil(display)
        XCTAssertGreaterThan(display!.width, 0)
    }

    func testFractionInExpression() {
        let mathList = MathList()

        let fraction = Fraction()
        fraction.numerator = MathList()
        fraction.numerator?.add(MathAtom(type: .variable, value: "a"))
        fraction.denominator = MathList()
        fraction.denominator?.add(MathAtom(type: .variable, value: "b"))

        mathList.add(fraction)
        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "c"))

        let display = Typesetter.createLineForMathListWithTokenization(
            mathList,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 0
        )

        XCTAssertNotNil(display)
        XCTAssertGreaterThan(display!.width, 0)
    }

    func testEmptyMathList() {
        let mathList = MathList()

        let display = Typesetter.createLineForMathListWithTokenization(
            mathList,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 0
        )

        // Empty math list should return an empty display (not nil) to match KaTeX behavior
        // This allows empty fraction numerators/denominators to render correctly
        XCTAssertNotNil(display, "Empty math list should return an empty display (KaTeX compatibility)")
        XCTAssertEqual(display?.width, 0, "Empty display should have zero width")
        XCTAssertEqual(display?.ascent, 0, "Empty display should have zero ascent")
        XCTAssertEqual(display?.descent, 0, "Empty display should have zero descent")
    }

    func testNilMathList() {
        let display = Typesetter.createLineForMathListWithTokenization(
            nil,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 0
        )

        XCTAssertNil(display, "Nil math list should return nil")
    }
}
