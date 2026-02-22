import CoreGraphics
import Testing

@testable import MathViews

struct ElementWidthCalculatorTests {

  let font: FontInstance
  let calculator: ElementWidthCalculator

  init() {
    font = MathFont.latinModernFont.fontInstance(size: 20)
    calculator = ElementWidthCalculator(font: font, style: .display)
  }

  // MARK: - Text Width Tests

  @Test func measureSimpleText() {
    let width = calculator.measureText("x")
    #expect(width > 0, "Text width should be positive")
  }

  @Test func measureEmptyText() {
    let width = calculator.measureText("")
    #expect(width == 0, "Empty text should have zero width")
  }

  @Test func measureMultiCharacterText() {
    let width = calculator.measureText("abc")
    #expect(width > 0, "Multi-character text should have positive width")

    let singleWidth = calculator.measureText("a")
    #expect(width > singleWidth, "Multi-character text should be wider than single character")
  }

  // MARK: - Operator Width Tests

  @Test func measureBinaryOperator() {
    let plusWidth = calculator.measureOperator("+", type: .binaryOperator)
    let textWidth = calculator.measureText("+")

    // Binary operators should have spacing (8mu total)
    let expectedSpacing = 2 * font.mathTable!.muUnit * 4
    #expect(abs(plusWidth - (textWidth + expectedSpacing)) <= 0.1)
  }

  @Test func measureRelationOperator() {
    let equalsWidth = calculator.measureOperator("=", type: .relation)
    let textWidth = calculator.measureText("=")

    // Relations should have wider spacing (10mu total)
    let expectedSpacing = 2 * font.mathTable!.muUnit * 5
    #expect(abs(equalsWidth - (textWidth + expectedSpacing)) <= 0.1)
  }

  @Test func measureOrdinaryOperator() {
    // Ordinary atoms don't add spacing
    let xWidth = calculator.measureOperator("x", type: .ordinary)
    let textWidth = calculator.measureText("x")

    #expect(abs(xWidth - textWidth) <= 0.1)
  }

  // MARK: - Display Width Tests

  @Test func measureDisplay() {
    let display = Display()
    display.width = 42.5

    let width = calculator.measureDisplay(display)
    #expect(width == 42.5)
  }

  // MARK: - Space Width Tests

  @Test func measureExplicitSpace() {
    let width = calculator.measureExplicitSpace(15.0)
    #expect(width == 15.0)
  }

  // MARK: - Inter-element Spacing Tests

  @Test func interElementSpacingOrdinaryToOrdinary() {
    // Ordinary to ordinary: no space
    let spacing = calculator.getInterElementSpacing(left: .ordinary, right: .ordinary)
    #expect(spacing == 0)
  }

  @Test func interElementSpacingOrdinaryToBinary() {
    // Ordinary to binary: medium space (4mu in display mode)
    let spacing = calculator.getInterElementSpacing(left: .ordinary, right: .binaryOperator)
    let expected = font.mathTable!.muUnit * 4
    #expect(abs(spacing - expected) <= 0.1)
  }

  @Test func interElementSpacingOrdinaryToRelation() {
    // Ordinary to relation: thick space (5mu in display mode)
    let spacing = calculator.getInterElementSpacing(left: .ordinary, right: .relation)
    let expected = font.mathTable!.muUnit * 5
    #expect(abs(spacing - expected) <= 0.1)
  }

  @Test func interElementSpacingBinaryToBinary() {
    // Binary to binary: invalid (should return 0)
    let spacing = calculator.getInterElementSpacing(left: .binaryOperator, right: .binaryOperator)
    #expect(spacing == 0)
  }

  @Test func interElementSpacingInScriptMode() {
    // In script mode, nsMedium spacing should be 0
    let scriptCalculator = ElementWidthCalculator(font: font, style: .script)
    let spacing = scriptCalculator.getInterElementSpacing(left: .ordinary, right: .binaryOperator)
    #expect(spacing == 0, "Script mode should have no nsMedium spacing")
  }

  @Test func interElementSpacingOpenToClose() {
    // Open to close: no space
    let spacing = calculator.getInterElementSpacing(left: .open, right: .close)
    #expect(spacing == 0)
  }

  // MARK: - Edge Cases

  @Test func measureTextWithNumbers() {
    let width = calculator.measureText("123")
    #expect(width > 0)
  }

  @Test func measureTextWithSpecialCharacters() {
    let width = calculator.measureText("α")
    #expect(width > 0)
  }

  // MARK: - Consistency Tests

  @Test func widthConsistency() {
    // Measuring same text twice should give same result
    let width1 = calculator.measureText("test")
    let width2 = calculator.measureText("test")
    #expect(width1 == width2)
  }

  @Test func operatorSpacingConsistency() {
    // Same operator type should have consistent spacing
    let width1 = calculator.measureOperator("+", type: .binaryOperator)
    let width2 = calculator.measureOperator("-", type: .binaryOperator)

    // Different operators may have different base widths, but spacing should be same
    let textWidth1 = calculator.measureText("+")
    let textWidth2 = calculator.measureText("-")

    let spacing1 = width1 - textWidth1
    let spacing2 = width2 - textWidth2

    #expect(abs(spacing1 - spacing2) <= 0.01)
  }
}
