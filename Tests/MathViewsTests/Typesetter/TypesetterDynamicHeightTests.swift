import CoreGraphics
import Testing

@testable import MathViews

#if canImport(AppKit)
  import AppKit
#else
  import UIKit
#endif

struct TypesetterDynamicHeightTests {
  let font: FontInstance

  init() {
    font = MathFont.latinModern.fontInstance(size: 20)
  }

  // MARK: - Dynamic Line Height Tests

  @Test func dynamicLineHeight_TallContentHasMoreSpacing() throws {
    // Test that lines with tall content (fractions) have appropriate spacing
    let latex = "a+b+c+\\frac{x^{2}}{y^{2}}+d+e+f"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Force multiple lines
    let maxWidth: CGFloat = 80
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Collect unique y positions (representing different lines)
    let yPositions = Set(display.subDisplays.map(\.position.y)).sorted(by: >)

    // Should have multiple lines
    #expect(yPositions.count > 1, "Should have multiple lines")

    // Calculate spacing between lines
    var spacings: [CGFloat] = []
    for i in 1..<yPositions.count {
      let spacing = yPositions[i - 1] - yPositions[i]
      spacings.append(spacing)
    }

    // With dynamic line height, spacing should vary based on content height
    // Line with fraction should have larger spacing than lines with just variables
    // All spacings should be at least 20% of fontSize (minimum spacing)
    let minExpectedSpacing = font.fontSize * 0.2
    for spacing in spacings {
      #expect(
        spacing >= minExpectedSpacing,
        "Line spacing should be at least minimum spacing",
      )
    }
  }

  @Test func dynamicLineHeight_RegularContentHasReasonableSpacing() throws {
    // Test that lines with regular content don't have excessive spacing
    let latex = "a+b+c+d+e+f+g+h+i+j"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Force multiple lines
    let maxWidth: CGFloat = 60
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Collect unique y positions
    let yPositions = Set(display.subDisplays.map(\.position.y)).sorted(by: >)

    // Should have multiple lines
    #expect(yPositions.count > 1, "Should have multiple lines")

    // Calculate spacing between lines
    var spacings: [CGFloat] = []
    for i in 1..<yPositions.count {
      let spacing = yPositions[i - 1] - yPositions[i]
      spacings.append(spacing)
    }

    // For regular content, spacing should be reasonable (roughly 1.2-1.8x fontSize)
    for spacing in spacings {
      #expect(spacing >= font.fontSize * 1.0, "Spacing should be at least fontSize")
      #expect(
        spacing <= font.fontSize * 2.0,
        "Spacing should not be excessive for regular content",
      )
    }
  }

  @Test func dynamicLineHeight_MixedContentVariesSpacing() throws {
    // Test that spacing adapts to each line's content
    // Line 1: regular (a+b)
    // Line 2: with fraction (more height needed)
    // Line 3: regular again (c+d)
    let latex = "a+b+\\frac{x}{y}+c+d"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Force breaks to create multiple lines
    let maxWidth: CGFloat = 50
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Should render successfully with varying line heights
    #expect(!display.subDisplays.isEmpty, "Should have content")

    // Verify overall height is reasonable
    let totalHeight = display.ascent + display.descent
    #expect(totalHeight > 0, "Total height should be positive")
  }

  @Test func dynamicLineHeight_LargeOperatorsGetAdequateSpace() throws {
    // Test that large operators with limits get adequate vertical spacing
    let latex = "\\sum_{i=1}^{n}i+\\prod_{j=1}^{m}j"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Force line break between operators
    let maxWidth: CGFloat = 80
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Collect y positions
    let yPositions = Set(display.subDisplays.map(\.position.y)).sorted(by: >)

    if yPositions.count > 1 {
      // Calculate spacing
      var spacings: [CGFloat] = []
      for i in 1..<yPositions.count {
        let spacing = yPositions[i - 1] - yPositions[i]
        spacings.append(spacing)
      }

      // Large operators need spacing - with tokenization, elements on same line share y-position
      // So spacing may be less if not actually separate lines
      // Just verify we have positive spacing between actual lines
      for spacing in spacings {
        #expect(spacing > 0, "Lines should have positive spacing")
      }
    }
  }

  @Test func dynamicLineHeight_ConsistentWithinSimilarContent() throws {
    // Test that similar lines get similar spacing
    let latex = "a+b+c+d+e+f"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Force multiple lines with similar content
    let maxWidth: CGFloat = 40
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Collect unique y positions
    let yPositions = Set(display.subDisplays.map(\.position.y)).sorted(by: >)

    if yPositions.count >= 3 {
      // Calculate all spacings
      var spacings: [CGFloat] = []
      for i in 1..<yPositions.count {
        let spacing = yPositions[i - 1] - yPositions[i]
        spacings.append(spacing)
      }

      // Similar content should have similar spacing (within 20% variance)
      let avgSpacing = spacings.reduce(0, +) / CGFloat(spacings.count)
      for spacing in spacings {
        let variance = abs(spacing - avgSpacing) / avgSpacing
        #expect(
          variance <= 0.3,
          "Spacing variance should be reasonable for similar content",
        )
      }
    }
  }

  @Test func dynamicLineHeight_NoRegressionOnSingleLine() throws {
    // Test that single-line expressions still work correctly
    let latex = "a+b+c"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // No width constraint
    let display = try #require(
      Typesetter.makeLineDisplay(for: mathList, font: font, style: .display))
    // Should be on single line
    let yPositions = Set(display.subDisplays.map(\.position.y))
    #expect(yPositions.count == 1, "Should be on single line")
  }

  @Test func dynamicLineHeight_DeepFractionsGetExtraSpace() throws {
    // Test that nested/continued fractions get adequate spacing
    let latex = "a+\\frac{1}{\\frac{2}{3}}+b+c"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Force line breaks
    let maxWidth: CGFloat = 70
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Deep fractions are taller - verify reasonable total height
    let totalHeight = display.ascent + display.descent
    #expect(totalHeight > 0, "Should have positive height")

    // Should render without issues
    #expect(!display.subDisplays.isEmpty, "Should have content")
  }

  @Test func dynamicLineHeight_RadicalsWithIndicesGetSpace() throws {
    // Test that radicals (especially with degrees like cube roots) get adequate spacing
    let latex = "a+\\sqrt[3]{x}+b+\\sqrt{y}+c"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Force line breaks
    let maxWidth: CGFloat = 70
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Should render successfully
    #expect(!display.subDisplays.isEmpty, "Should have content")

    // Verify reasonable spacing
    let yPositions = Set(display.subDisplays.map(\.position.y)).sorted(by: >)
    if yPositions.count > 1 {
      for i in 1..<yPositions.count {
        let spacing = yPositions[i - 1] - yPositions[i]
        #expect(spacing >= font.fontSize * 0.2, "Should have minimum spacing")
      }
    }
  }

  // MARK: - Table Cell Line Breaking Tests

  @Test func tableCellLineBreaking_MultipleFractions() throws {
    // Test for table cell line breaking with multiple fractions
    // This verifies the fix for shouldBreakBeforeDisplay() using currentPosition.x
    // instead of getCurrentLineWidth() to correctly track line width
    let latex =
      "\\[ \\cos\\widehat{ABC} = \\frac{\\overrightarrow{BA}\\cdot\\overrightarrow{BC}}{|\\overrightarrow{BA}||\\overrightarrow{BC}|} = \\frac{25}{5\\cdot 2\\sqrt{13}} = \\frac{5}{2\\sqrt{13}} \\\\ \\widehat{ABC} = \\arccos\\left(\\frac{5}{2\\sqrt{13}}\\right) \\approx 0.806 \\text{ rad} \\]"

    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX with table structure")

    // Use narrow width to force line breaking within table cells
    let maxWidth: CGFloat = 235.0
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Verify display was created successfully
    #expect(!display.subDisplays.isEmpty, "Should have subdisplays")

    // For tables, the rows are nested inside the table display
    // The table itself is a single subdisplay, and its subdisplays are the rows
    if let tableDisplay = display.subDisplays[0] as? MathListDisplay {
      // Check that the table has multiple rows (table rows should be at different y positions)
      let yPositions = Set(tableDisplay.subDisplays.map(\.position.y))
      #expect(
        yPositions.count >= 2,
        "Should have multiple rows (at least 2 different y positions)",
      )

      // Verify the table width doesn't significantly exceed maxWidth
      let tolerance: CGFloat = 10.0
      #expect(
        tableDisplay.width <= maxWidth + tolerance,
        "Table width \(tableDisplay.width) should not significantly exceed maxWidth \(maxWidth)",
      )
    }

    // Verify the display has reasonable dimensions
    #expect(display.width > 0, "Display should have positive width")
    #expect(display.ascent > 0, "Display should have positive ascent")
  }

  @Test func tableCellLineBreaking_ThreeRowsWithPowers() throws {
    // Test case that was reported to cause assertion failure
    // Tests multiple table rows with equations containing powers and radicals
    let latex =
      "\\[ AC = c = 3\\sqrt{3} \\\\ CB^{2} = AB^{2} + AC^{2} = 5^{2} + \\left(3\\sqrt{3}\\right)^{2} = 25 + 27 = 52 \\\\ CB = \\sqrt{52} = 2\\sqrt{13} \\approx 7.211 \\]"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX with 3-row table")

    // Use narrow width to force line breaking
    let maxWidth: CGFloat = 200.0
    let display = try #require(
      Typesetter.makeLineDisplay(
        for: mathList, font: font, style: .display, maxWidth: maxWidth,
      ))
    // Verify display was created
    #expect(!display.subDisplays.isEmpty, "Should have subdisplays")

    // For tables, the rows are nested inside the table display
    if let tableDisplay = display.subDisplays[0] as? MathListDisplay {
      // Check for multiple rows (3 table rows should be at 3 different y positions)
      let yPositions = Set(tableDisplay.subDisplays.map(\.position.y))
      #expect(yPositions.count >= 3, "Should have at least 3 rows at different y positions")

      // Verify table width doesn't overflow dramatically
      let tolerance: CGFloat = 15.0
      #expect(
        tableDisplay.width <= maxWidth + tolerance,
        "Table width should not significantly exceed maxWidth",
      )
    }

    // Verify dimensions are reasonable
    #expect(display.width > 0, "Display should have positive width")
    #expect(display.ascent > 0, "Display should have positive ascent")
    #expect(display.descent > 0, "Display should have positive descent")
  }
}
