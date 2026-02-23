import Testing
@testable import MathViews
import CoreGraphics

struct MathDelimiterTests {
    // MARK: - Display Math Delimiters

    @Test func displayMathBrackets() {
        // Test \[...\] delimiter for display math
        let latex = "\\[x^2 + y^2 = z^2\\]"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "MathList should be parsed successfully")
        #expect(style == .display, "\\[...\\] should produce display style")

        // Verify the content was parsed correctly (without the delimiters)
        // Atoms: x (with ^2), +, y (with ^2), =, z (with ^2) = 5 atoms
        #expect(mathList?.atoms.count == 5, "Should have 5 atoms: x^2 + y^2 = z^2")
    }

    @Test func doubleDollarDisplayMath() {
        // Test $$...$$ delimiter for display math
        let latex = "$$\\sum_{i=1}^{n} i$$"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "MathList should be parsed successfully")
        #expect(style == .display, "$$...$$ should produce display style")

        // Verify content was parsed
        #expect((mathList?.atoms.count ?? 0) > 0, "MathList should contain atoms")
    }

    // MARK: - Inline Math Delimiters

    @Test func inlineMathParentheses() {
        // Test \(...\) delimiter for inline math
        let latex = "\\(a + b\\)"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "MathList should be parsed successfully")
        #expect(style == .text, "\\(...\\) should produce text/inline style")

        // Verify content - includes style atom
        #expect((mathList?.atoms.count ?? 0) >= 3, "Should have at least 3 atoms: a + b")
    }

    @Test func singleDollarInlineMath() {
        // Test $...$ delimiter for inline math
        let latex = "$\\frac{1}{2}$"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "MathList should be parsed successfully")
        #expect(style == .text, "$...$ should produce text/inline style")

        // Verify fraction was parsed (may include style atom)
        #expect((mathList?.atoms.count ?? 0) >= 1, "Should have at least 1 atom")

        // Find the fraction atom (might not be first due to style atoms)
        let hasFraction = mathList?.atoms.contains(where: { $0.type == .fraction }) ?? false
        #expect(hasFraction, "Should contain a fraction atom")
    }

    // MARK: - No Delimiters (Default Behavior)

    @Test func noDelimitersDefaultsToDisplay() {
        // Test that content without delimiters defaults to display mode
        let latex = "x + y = z"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "MathList should be parsed successfully")
        #expect(style == .display, "Content without delimiters should default to display style")

        // Verify content
        #expect(mathList?.atoms.count == 5, "Should have 5 atoms: x + y = z")
    }

    // MARK: - Edge Cases

    @Test func emptyBrackets() {
        // Test empty \[...\]
        // Note: \[\] is exactly 4 characters, so delimiter detection requires > 4
        // Empty delimiters are not detected as display math delimiters
        let latex = "\\[ \\]" // Add space to make it > 4 characters
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "Empty display math with space should parse")
        #expect(style == .display, "\\[ \\] should produce display style")
        #expect(mathList?.atoms.isEmpty == true, "Empty delimiters should produce empty list")
    }

    @Test func emptyDoubleDollar() {
        // Test empty $$...$$
        let latex = "$$$$"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "Empty display math should still parse")
        #expect(style == .display, "Empty $$$$ should produce display style")
        #expect(mathList?.atoms.isEmpty == true, "Empty delimiters should produce empty list")
    }

    @Test func whitespaceInBrackets() {
        // Test \[...\] with whitespace
        let latex = "\\[  x + y  \\]"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "Whitespace should not affect parsing")
        #expect(style == .display, "\\[...\\] with whitespace should produce display style")
        #expect(mathList?.atoms.count == 3, "Should have 3 atoms: x + y")
    }

    @Test func nestedBracesInDisplayMath() {
        // Test \[...\] with nested braces
        let latex = "\\[\\frac{a}{b}\\]"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "Nested structures should parse correctly")
        #expect(style == .display, "\\[...\\] should produce display style")
        #expect(mathList?.atoms.first?.type == .fraction, "Should contain a fraction")
    }

    // MARK: - Complex Expressions

    @Test func complexDisplayExpression() {
        // Test a complex display math expression
        let latex = "\\[\\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\\]"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "Complex expression should parse")
        #expect(style == .display, "\\[...\\] should produce display style")
        #expect((mathList?.atoms.count ?? 0) > 5, "Should have multiple atoms")
    }

    @Test func complexInlineExpression() {
        // Test a complex inline math expression
        let latex = "$\\sum_{i=1}^{n} x_i$"
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)

        #expect(mathList != nil, "Complex inline expression should parse")
        #expect(style == .text, "$...$ should produce text/inline style")
        #expect((mathList?.atoms.count ?? 0) > 0, "Should have atoms")
    }

    // MARK: - Error Handling

    @Test func invalidLatexWithBrackets() {
        // Test \[...\] with invalid LaTeX
        let latex = "\\[\\invalidcommand\\]"
        #expect(throws: ParseError.self) {
            try MathListBuilder.buildWithStyleChecked(fromString: latex)
        }
        // Style detection still works even when content is invalid
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)
        #expect(mathList == nil, "Invalid LaTeX should return nil")
        #expect(style == .display, "Style should still be detected even with error")
    }

    @Test func mismatchedDelimiters() {
        // Test mismatched delimiters - should not be recognized as delimited
        let latex = "\\[x + y\\)"
        let (_, style) = MathListBuilder.buildWithStyle(fromString: latex)

        // The string doesn't match any delimiter pattern, so it's treated as raw content
        // This should parse the raw string including the backslash-bracket
        #expect(style == .display, "Mismatched delimiters default to display mode")
    }

    // MARK: - Backward Compatibility

    @Test func backwardCompatibilityWithOldAPI() {
        // Ensure old API still works
        let latex = "x + y"
        let mathList = MathListBuilder.build(fromString: latex)

        #expect(mathList != nil, "Old API should still work")
        #expect(mathList?.atoms.count == 3, "Should parse correctly")
    }

    @Test func backwardCompatibilityWithError() {
        // Ensure throwing API reports errors
        let latex = "\\invalidcommand"
        #expect(throws: ParseError.self) {
            try MathListBuilder.buildChecked(fromString: latex)
        }
    }

    // MARK: - Multiple Delimiter Types

    @Test(arguments: [
        "\\[x^2\\]",
        "$$x^2$$",
    ])
    func allDisplayDelimiters(_ latex: String) {
        // Test all display delimiter types produce display style
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)
        #expect(mathList != nil, "Display math \(latex) should parse")
        #expect(style == .display, "\(latex) should produce display style")
    }

    @Test(arguments: [
        "\\(x^2\\)",
        "$x^2$",
    ])
    func allInlineDelimiters(_ latex: String) {
        // Test all inline delimiter types produce text style
        let (mathList, style) = MathListBuilder.buildWithStyle(fromString: latex)
        #expect(mathList != nil, "Inline math \(latex) should parse")
        #expect(style == .text, "\(latex) should produce text/inline style")
    }

    // MARK: - Environment Testing

    @Test func environmentDefaultsToDisplay() {
        // Test that \begin{...}\end{...} environments default to display mode
        let latex = "\\begin{align}x &= y\\end{align}"
        let (_, style) = MathListBuilder.buildWithStyle(fromString: latex)

        // Note: This might fail depending on environment support in the codebase
        #expect(style == .display, "Environments should default to display style")
    }
}
