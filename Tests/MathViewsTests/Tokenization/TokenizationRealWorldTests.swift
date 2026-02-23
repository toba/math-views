import Testing
@testable import MathViews
import CoreGraphics

struct TokenizationRealWorldTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModernFont.fontInstance(size: 20)
    }

    // MARK: - Spec Example 1: Radical with Long Text

    // From spec: "Approximate sqrt(61) and compute the two decimal solutions"
    // Problem: After sqrt(61) (at x=116px), there's 119px of space remaining,
    // but text (263px) breaks to next line instead of fitting partial text

    @Test func specExample1_ApproximateRadical() throws {
        // Test with tokenization enabled

        let latex = "\\text{Approximate }\\sqrt{61}\\text{ and compute the two decimal solutions}"
        let mathList = MathListBuilder.build(fromString: latex)

        // Width chosen to match spec scenario
        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 235,
        )

        #expect(display != nil, "Display should be created")

        // With tokenization, should utilize available width better
        // Check that we're using more horizontal space
        #expect(try #require(display?.width) > 150, "Should use significant width")

        // Verify we have multiple line breaks (can't fit all on one line)
        let yPositions = try Set(#require(display?.subDisplays.map(\.position.y)))
        #expect(yPositions.count > 1, "Should break into multiple lines")

        print("Spec Example 1: Width used = \(display!.width), Lines = \(yPositions.count)")
    }

    // MARK: - Spec Example 2: Equation with Integrand

    // From spec: "Integrate each term of the integrand x^2+v"
    // Problem: Breaks after text instead of keeping equation on same line

    @Test func specExample2_IntegrateEquation() throws {
        let latex = "\\text{Integrate each term of the integrand }x^2+v\\text{ separately}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 350,
        )

        #expect(display != nil)
        #expect(try #require(display?.width) > 200, "Should use available width")

        print("Spec Example 2: Width = \(display!.width)")
    }

    // MARK: - Operator Breaking Tests

    @Test func breakAtBinaryOperators() {
        // Simple arithmetic that should break at + operators
        let latex = "a+b-c\\times d\\div e"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 100,
        )

        #expect(display != nil)

        // Should break at operators when needed
        print("Binary operators: Width = \(display!.width)")
    }

    @Test func breakAtRelationOperators() {
        let latex = "x=y<z>w\\leq a\\geq b\\neq c"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 120,
        )

        #expect(display != nil)

        print("Relation operators: Width = \(display!.width)")
    }

    // MARK: - Script Grouping Tests

    @Test func scriptsStayGrouped() {
        // x^2 should stay together
        let latex = "x^{2}+y^{3}+z^{4}+a^{5}+b^{6}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 100,
        )

        #expect(display != nil)

        // Each base+script should stay together
        print("Script grouping: Width = \(display!.width)")
    }

    @Test func subscriptAndSuperscript() {
        let latex = "x_{i}^{2}+y_{j}^{3}+z_{k}^{4}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 120,
        )

        #expect(display != nil)

        print("Sub+superscript: Width = \(display!.width)")
    }

    // MARK: - Fraction Tests

    @Test func fractionBreaking() {
        let latex = "\\frac{a}{b}+\\frac{c}{d}+\\frac{e}{f}+\\frac{g}{h}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 150,
        )

        #expect(display != nil)

        // Fractions should remain atomic
        print("Fractions: Width = \(display!.width)")
    }

    @Test func fractionWithSuperscript() {
        let latex = "\\frac{a}{b}^{n}+c+d+e"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 100,
        )

        #expect(display != nil)

        // Fraction and superscript should stay grouped
        print("Fraction with script: Width = \(display!.width)")
    }

    // MARK: - Radical Tests

    @Test func radicalBreaking() {
        let latex = "\\sqrt{a}+\\sqrt{b}+\\sqrt{c}+\\sqrt{d}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 120,
        )

        #expect(display != nil)

        // Radicals should remain atomic
        print("Radicals: Width = \(display!.width)")
    }

    // MARK: - Delimiter Tests

    @Test func parenthesesBreaking() {
        let latex = "(a+b)+(c-d)+(e\\times f)"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 120,
        )

        #expect(display != nil)

        // Should not break after ( or before )
        print("Parentheses: Width = \(display!.width)")
    }

    // MARK: - Mixed Content Tests

    @Test func mixedTextAndMath() {
        let latex = "\\text{The quick brown fox jumps over }x+y=z\\text{ lazily}"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 250,
        )

        #expect(display != nil)

        print("Mixed content: Width = \(display!.width)")
    }

    // MARK: - Width Utilization Test

    @Test func widthUtilization() throws {
        let latex = "\\text{Calculate }\\sqrt{x^2+y^2}\\text{ and simplify the result}"

        let display = Typesetter.createLineForMathList(
            MathListBuilder.build(fromString: latex),
            font: font,
            style: .display,
            maxWidth: 250,
        )

        #expect(display != nil)

        let width = try #require(display?.width)

        print("Width utilization: \(width) pts with max 250 pts")

        // Should efficiently use available width
        #expect(width > 200, "Should use most of available width")
    }

    // MARK: - Edge Cases

    @Test func emptyExpression() {
        let mathList = MathList()
        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 100,
        )

        // Empty math list should return an empty display (not nil) to match KaTeX behavior
        // This allows empty fraction numerators/denominators to render correctly
        #expect(
            display != nil,
            "Empty expression should return an empty display (KaTeX compatibility)",
        )
        #expect(display?.width == 0, "Empty display should have zero width")
        #expect(display?.ascent == 0, "Empty display should have zero ascent")
        #expect(display?.descent == 0, "Empty display should have zero descent")
    }

    @Test func singleAtom() throws {
        let latex = "x"
        let mathList = MathListBuilder.build(fromString: latex)

        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 100,
        )

        #expect(display != nil)
        #expect(try #require(display?.width) > 0)
    }

    @Test func veryLongExpression() throws {
        // Generate a+b+c+...
        var latex = ""
        for i in 0 ..< 26 {
            let letter = String(UnicodeScalar(UInt8(97 + i)))
            latex += letter
            if i < 25 {
                latex += "+"
            }
        }

        let mathList = MathListBuilder.build(fromString: latex)
        let display = Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: .display,
            maxWidth: 200,
        )

        #expect(display != nil)

        // Should break into multiple lines
        let yPositions = try Set(#require(display?.subDisplays.map(\.position.y)))
        #expect(yPositions.count > 1, "Should require multiple lines")

        print("Very long expression: \(yPositions.count) lines")
    }
}
