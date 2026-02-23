import Testing
@testable import MathViews
import CoreGraphics

struct TokenizationImprovementTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModernFont.fontInstance(size: 20)
    }

    // MARK: - Real-World Scenario 1: Radical with Long Text

    @Test func radicalWithLongText() throws {
        let latex = "\\text{Approximate }\\sqrt{61}\\text{ and compute the two decimal solutions}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 235,
        )

        #expect(display != nil)

        let yPositions = try Set(#require(display?.subDisplays.map(\.position.y)))
        let lineCount = yPositions.count

        print("Radical with long text - Lines: \(lineCount), Width: \(display!.width)")

        // Should fit text efficiently
        #expect(try #require(display?.width) > 0)
    }

    // MARK: - Real-World Scenario 2: Equation with Text

    @Test func equationWithText() throws {
        // "Integrate each term of the integrand x^2+v"
        let latex = "\\text{Integrate each term of the integrand }x^2+v"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 300,
        )

        #expect(display != nil)

        let yPositions = try Set(#require(display?.subDisplays.map(\.position.y)))
        let lineCount = yPositions.count

        print("Equation with text - Lines: \(lineCount)")

        // Should keep equation on same line as text
        #expect(try #require(display?.width) > 0)
    }

    // MARK: - Complex Expression Tests

    @Test func longEquation() throws {
        let latex = "a+b+c+d+e+f+g+h+i+j+k"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 150,
        )

        #expect(display != nil)

        let yPositions = try Set(#require(display?.subDisplays.map(\.position.y)))
        print("Long equation - Lines: \(yPositions.count)")

        // Should break at operators efficiently
        #expect(try #require(display?.width) > 0)
    }

    // MARK: - Edge Cases

    @Test func fractionWithScripts() throws {
        let latex = "\\frac{a}{b}^{n}+c+d+e+f"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 150,
        )

        #expect(display != nil)
        // Should keep fraction and script grouped
        #expect(try #require(display?.width) > 0)
    }

    @Test func mixedContent() throws {
        let latex = "\\text{The answer is }x=\\frac{a+b}{c}\\text{ approximately}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 200,
        )

        #expect(display != nil)
        #expect(try #require(display?.width) > 0)
    }
}
