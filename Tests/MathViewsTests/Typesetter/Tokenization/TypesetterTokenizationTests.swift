import Testing
@testable import MathViews
import CoreGraphics

struct TypesetterTokenizationTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModern.fontInstance(size: 20)
    }

    // MARK: - Integration Tests

    @Test func simpleExpression() throws {
        // x + y
        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))
        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "y"))

        let display = try #require(
            Typesetter.makeLineDisplayWithTokenization(
                for: mathList,
                font: font,
                style: .display,
                cramped: false,
                spaced: false,
                maxWidth: 0,
            ),
        )

        #expect(display.width > 0)
        #expect(!(display.subDisplays.isEmpty))
    }

    @Test func expressionWithWidthConstraint() throws {
        // Create a long expression
        let mathList = MathList()
        for i in 0 ..< 10 {
            mathList.add(MathAtom(type: .variable, value: "x"))
            if i < 9 {
                mathList.add(MathAtom(type: .binaryOperator, value: "+"))
            }
        }

        let display = try #require(
            Typesetter.makeLineDisplayWithTokenization(
                for: mathList,
                font: font,
                style: .display,
                cramped: false,
                spaced: false,
                maxWidth: 150,
            ),
        )

        // With width constraint, should create multiple lines
        // Check that display has reasonable dimensions
        #expect(!(display.subDisplays.isEmpty))
    }

    @Test func expressionWithScripts() throws {
        // x^2 + y
        let mathList = MathList()

        let x = MathAtom(type: .variable, value: "x")
        let superScript = MathList()
        superScript.add(MathAtom(type: .number, value: "2"))
        x.superScript = superScript
        mathList.add(x)

        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "y"))

        let display = try #require(
            Typesetter.makeLineDisplayWithTokenization(
                for: mathList,
                font: font,
                style: .display,
                cramped: false,
                spaced: false,
                maxWidth: 0,
            ),
        )

        #expect(display.width > 0)
    }

    @Test func fractionInExpression() throws {
        let mathList = MathList()

        let fraction = Fraction()
        fraction.numerator = MathList()
        fraction.numerator?.add(MathAtom(type: .variable, value: "a"))
        fraction.denominator = MathList()
        fraction.denominator?.add(MathAtom(type: .variable, value: "b"))

        mathList.add(fraction)
        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "c"))

        let display = try #require(
            Typesetter.makeLineDisplayWithTokenization(
                for: mathList,
                font: font,
                style: .display,
                cramped: false,
                spaced: false,
                maxWidth: 0,
            ),
        )

        #expect(display.width > 0)
    }

    @Test func emptyMathList() {
        let mathList = MathList()

        let display = Typesetter.makeLineDisplayWithTokenization(
            for: mathList,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 0,
        )

        // Empty math list should return an empty display (not nil) to match KaTeX behavior
        // This allows empty fraction numerators/denominators to render correctly
        #expect(
            display != nil,
            "Empty math list should return an empty display (KaTeX compatibility)",
        )
        #expect(display?.width == 0, "Empty display should have zero width")
        #expect(display?.ascent == 0, "Empty display should have zero ascent")
        #expect(display?.descent == 0, "Empty display should have zero descent")
    }

    @Test func nilMathList() {
        let display = Typesetter.makeLineDisplayWithTokenization(
            for: nil,
            font: font,
            style: .display,
            cramped: false,
            spaced: false,
            maxWidth: 0,
        )

        #expect(display == nil, "Nil math list should return nil")
    }
}
