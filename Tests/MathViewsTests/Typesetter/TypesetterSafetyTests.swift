import CoreGraphics
import Testing

@testable import MathViews

#if canImport(AppKit)
  import AppKit
#else
  import UIKit
#endif

struct TypesetterSafetyTests {
  let font: FontInstance

  init() {
    font = MathFont.latinModern.fontInstance(size: 20)
  }

  @Test func typesetterNeverReturnsNegativeDimensions() {
    // This tests that typesetting never produces negative dimensions
    var helper = TypesetterHelper()

    // Test 1: Complex multiline expression
    helper.latex =
      #"\[ AC = c = 3\sqrt{3} \\ CB^{2} = AB^{2} + AC^{2} = 5^{2} + \left(3\sqrt{3}\right)^{2} = 25 + 27 = 52 \\ CB = \sqrt{52} = 2\sqrt{13} \approx 7.211 \]"#

    // Test with various width constraints
    let testWidths: [CGFloat] = [100, 50, 0, 500]
    for width in testWidths {
      helper.maxWidth = width
      let size = helper.intrinsicContentSize
      #expect(size.width >= 0, "Width should never be negative for maxWidth \(width)")
      #expect(size.height >= 0, "Height should never be negative for maxWidth \(width)")
    }

    // Test 2: With maxWidth constraint
    helper.maxWidth = 150
    let sizeWithMaxWidth = helper.intrinsicContentSize
    #expect(sizeWithMaxWidth.width >= 0, "Width should never be negative with maxWidth")
    #expect(sizeWithMaxWidth.height >= 0, "Height should never be negative with maxWidth")

    // Test 3: Verify the problematic cosine fraction expression
    helper.latex =
      #"\[ \cos\widehat{ABC} = \frac{\overrightarrow{BA}\cdot\overrightarrow{BC}}{|\overrightarrow{BA}||\overrightarrow{BC}|} = \frac{25}{5\cdot 2\sqrt{13}} = \frac{5}{2\sqrt{13}} \\ \widehat{ABC} = \arccos\left(\frac{5}{2\sqrt{13}}\right) \approx 0.806 \text{ rad} \]"#
    helper.maxWidth = 300
    let sizeForCosine = helper.intrinsicContentSize
    #expect(sizeForCosine.width >= 0, "Width should never be negative for cosine expression")
    #expect(sizeForCosine.height >= 0, "Height should never be negative for cosine expression")
  }

  @Test func nSRangeOverflowProtection() throws {
    // This tests the NSRange overflow protection in MathList.finalized
    // The issue occurred when prevNode.indexRange.location was NSNotFound or very large

    let latex = #"x^{2} + y^{2}"#
    let mathList = try MathListBuilder.buildChecked(fromString: latex)

    // Trigger finalization which performs indexRange calculations
    let finalized = mathList.finalized

    // Verify all atoms have valid ranges
    for atom in finalized.atoms {
      #expect(atom.indexRange.lowerBound >= 0, "Lower bound should be non-negative")
      #expect(!atom.indexRange.isEmpty, "Count should be positive")
    }

    // Test with more complex expression that has nested structures
    let complexLatex = #"\frac{a^{2}}{b_{3}} + \sqrt{x^{2}}"#
    let complexMathList = try MathListBuilder.buildChecked(fromString: complexLatex)

    _ = complexMathList.finalized
  }

  @Test func invalidFractionRangeHandling() throws {
    // This tests the invalid fraction range handling in FractionDisplay
    // The issue occurred when fraction ranges were (0,0) or otherwise invalid

    let latex = #"\frac{1}{2}"#
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse fraction")

    // Create display which triggers fraction range validation
    let display = try #require(
      Typesetter.makeLineDisplay(for: mathList, font: font, style: .display))
    // The display should not crash even if internal ranges are invalid
    #expect(display.width > 0, "Fraction should have positive width")
    #expect(display.ascent > 0, "Fraction should have positive ascent")

    // Test with nested fractions which are more likely to have range issues
    let nestedLatex = #"\frac{\frac{a}{b}}{c}"#
    let nestedMathList = MathListBuilder.build(fromString: nestedLatex)
    let nestedDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: nestedMathList, font: font, style: .display,
      ))
    #expect(
      nestedDisplay.width > 0,
      "Nested fraction should have positive width",
    )

    // Test fraction in table cell (where range issues were most common)
    let tableLatex = #"\[ \frac{a}{b} \\ \frac{c}{d} \]"#
    let tableMathList = MathListBuilder.build(fromString: tableLatex)
    _ = try #require(
      Typesetter.makeLineDisplay(
        for: tableMathList, font: font, style: .display, maxWidth: 200,
      ))
  }

  @Test func atomWidthIncludesScripts() throws {
    // This tests that calculateAtomWidth includes script widths
    // Previously only the base atom width was calculated, causing scripts to overflow

    // Test atom with superscript
    let superscriptLatex = "x^{2}"
    let superscriptMathList = MathListBuilder.build(fromString: superscriptLatex)
    let superscriptDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: superscriptMathList, font: font, style: .text, maxWidth: 100,
      ))

    // The width should include both base and script
    // A simple 'x' would be much narrower than 'x^2'
    let baseOnlyLatex = "x"
    let baseOnlyMathList = MathListBuilder.build(fromString: baseOnlyLatex)
    let baseOnlyDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: baseOnlyMathList, font: font, style: .text,
      ))

    #expect(
      superscriptDisplay.width > baseOnlyDisplay.width,
      "Width with superscript should be greater than base alone",
    )

    // Test atom with subscript
    let subscriptLatex = "x_{i}"
    let subscriptMathList = MathListBuilder.build(fromString: subscriptLatex)
    let subscriptDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: subscriptMathList, font: font, style: .text,
      ))
    #expect(
      subscriptDisplay.width > baseOnlyDisplay.width,
      "Width with subscript should be greater than base alone",
    )

    // Test atom with both superscript and subscript
    let bothLatex = "x_{i}^{2}"
    let bothMathList = MathListBuilder.build(fromString: bothLatex)
    let bothDisplay = try #require(
      Typesetter.makeLineDisplay(for: bothMathList, font: font, style: .text))
    #expect(
      bothDisplay.width > baseOnlyDisplay.width,
      "Width with both scripts should be greater than base alone",
    )

    // Test that scripts don't cause line breaking issues
    // If scripts aren't included in width calculation, this could break between base and script
    let longLatex = "a^{2} + b^{2} + c^{2} + d^{2}"
    let longMathList = MathListBuilder.build(fromString: longLatex)
    let longDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: longMathList, font: font, style: .text, maxWidth: 150,
      ))

    // Verify content doesn't overflow
    let longDisplayWidth = longDisplay.width
    #expect(
      longDisplayWidth <= 150 + 10,
      "Display should respect width constraint with scripts",
    )
  }

  @Test func safeUIntConversionFromNSRange() throws {
    // This tests the safeUIntFromLocation helper function in Typesetter
    // The issue occurred when NSRange locations with NSNotFound were converted to UInt

    // Test with atoms that have scripts (which call makeScripts with UInt index)
    let latex = "x^{2} + y_{i} + z_{j}^{k}"
    let mathList = try MathListBuilder.buildChecked(fromString: latex)

    // Create display - this triggers makeScripts calls with UInt conversions
    _ = try #require(Typesetter.makeLineDisplay(for: mathList, font: font, style: .text))
    // Test with fractions that have scripts
    let fractionLatex = #"\frac{a}{b}^{2}"#
    let fractionMathList = MathListBuilder.build(fromString: fractionLatex)
    _ = try #require(
      Typesetter.makeLineDisplay(
        for: fractionMathList, font: font, style: .display,
      ))
    // Test with radicals that have scripts
    let radicalLatex = #"\sqrt{x}^{2}"#
    let radicalMathList = MathListBuilder.build(fromString: radicalLatex)
    _ = try #require(
      Typesetter.makeLineDisplay(
        for: radicalMathList, font: font, style: .display,
      ))
    // Test with accents that have scripts
    let accentLatex = #"\hat{x}^{2}"#
    let accentMathList = MathListBuilder.build(fromString: accentLatex)
    _ = try #require(
      Typesetter.makeLineDisplay(
        for: accentMathList, font: font, style: .text,
      ))
    // Test complex expression with multiple scripted display types
    let complexLatex = #"\frac{a^{2}}{b_{i}} + \sqrt{x^{2}} + \hat{y}_{j}"#
    let complexMathList = MathListBuilder.build(fromString: complexLatex)
    let complexDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: complexMathList, font: font, style: .display,
      ))
    // complexDisplay is already unwrapped by try #require above
    #expect(
      complexDisplay.width > 0,
      "Complex display should have positive width",
    )
  }

  @Test func negativeNumberAfterRelation() throws {
    // This tests the fix for "Invalid space between Relation and Binary Operator" assertion
    // The issue occurs when a negative number appears after a relation like =
    // The minus sign should be treated as unary (part of the number), not as binary operator

    // Test simple case: equation with negative number
    let simpleLatex = "x=-2"
    let simpleMathList = try MathListBuilder.buildChecked(fromString: simpleLatex)

    let simpleDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: simpleMathList, font: font, style: .display,
      ))
    #expect(simpleDisplay.width > 0, "Display should have positive width")

    // Test with decimal negative number
    let decimalLatex = "y=-1.5"
    let decimalMathList = MathListBuilder.build(fromString: decimalLatex)
    let decimalDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: decimalMathList, font: font, style: .display,
      ))
    #expect(decimalDisplay.width > 0, "Decimal display should have positive width")
    // Test the original problematic input with determinant and matrix
    let complexLatex = #"\[\det(A)=-2,\\ A^{-1}=\begin{bmatrix}-1.5 & 2 \\ 1 & -1\end{bmatrix}\]"#
    let complexMathList = MathListBuilder.build(fromString: complexLatex)
    #expect(complexMathList != nil, "Should parse complex expression with negative numbers")

    let complexDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: complexMathList, font: font, style: .display, maxWidth: 300,
      ))
    // complexDisplay is non-optional (already unwrapped by try #require)
    #expect(complexDisplay.width > 0, "Display should have positive width")

    // Test multiple negative numbers in sequence
    let multipleLatex = "a=-1, b=-2, c=-3"
    let multipleMathList = MathListBuilder.build(fromString: multipleLatex)
    let multipleDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: multipleMathList, font: font, style: .text,
      ))
    #expect(multipleDisplay.width > 0, "Multiple negatives display should have positive width")
    // Test negative in other relation contexts
    let relationLatex = #"x \leq -5"#
    let relationMathList = MathListBuilder.build(fromString: relationLatex)
    let relationDisplay = try #require(
      Typesetter.makeLineDisplay(
        for: relationMathList, font: font, style: .text,
      ))
    #expect(relationDisplay.width > 0, "Relation display should have positive width")
  }
}
