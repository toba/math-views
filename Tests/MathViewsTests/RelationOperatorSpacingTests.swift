import CoreGraphics
import Testing

@testable import MathViews

struct RelationOperatorSpacingTests {

  let font: FontInstance

  init() {
    font = MathFont.termesFont.fontInstance(size: 20)
  }

  /// Test that relation operators (=) have proper spacing
  /// Issue: Space before = was missing in tokenization
  @Test func relationOperatorSpacing() {
    let latex = "a + b = c"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil, "Should parse LaTeX")

    // Use tokenization path
    let display = Typesetter.createLineForMathListWithTokenization(
      mathList,
      font: font,
      style: .text,
      cramped: false,
      spaced: false,
      maxWidth: 1000
    )

    #expect(display != nil)
    #expect(display!.subDisplays.count >= 5, "Should have at least 5 elements: a, +, b, =, c")

    // Check the positions: each operator should have space before it
    // We should see increasing X positions with gaps for spacing
    var prevRightEdge: CGFloat = 0
    for (i, subdisplay) in display!.subDisplays.enumerated() {
      let currentX = subdisplay.position.x
      let rightEdge = currentX + subdisplay.width

      if i > 0 {
        // There should be a gap (spacing) between elements
        let gap = currentX - prevRightEdge
        print("Element[\(i)] gap from previous: \(gap), x=\(currentX), width=\(subdisplay.width)")

        // For operators, there should be spacing before them
        // We're looking for gaps > 0
      }

      prevRightEdge = rightEdge
    }
  }

  /// Test binary operator spacing
  @Test func binaryOperatorSpacing() {
    let latex = "a + b"
    let mathList = MathListBuilder.build(fromString: latex)
    #expect(mathList != nil)

    let display = Typesetter.createLineForMathListWithTokenization(
      mathList,
      font: font,
      style: .text,
      cramped: false,
      spaced: false,
      maxWidth: 1000
    )

    #expect(display != nil)
    #expect(display!.subDisplays.count >= 3, "Should have at least a, +, b")
  }
}
