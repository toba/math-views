import Testing

@testable import MathViews

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

// MARK: - Corner Bracket Render Tests

struct CornerBracketRenderTests {

  let font = MathFont.latinModernFont
  let fontSize: CGFloat = 20.0

  static let cornerBracketCases: [RenderCase] = [
    RenderCase(name: "upper_corners", latex: "\\left\\ulcorner x \\right\\urcorner"),
    RenderCase(name: "lower_corners", latex: "\\left\\llcorner x \\right\\lrcorner"),
    RenderCase(name: "quote_corners", latex: "\\left\\ulcorner \\text{quote} \\right\\urcorner"),
  ]

  static let doubleBracketCases: [RenderCase] = [
    RenderCase(name: "double_brackets", latex: "\\left\\llbracket x \\right\\rrbracket"),
    RenderCase(name: "semantic_function", latex: "\\left\\llbracket f(x) \\right\\rrbracket"),
  ]

  @Test(arguments: cornerBracketCases)
  func cornerBrackets(_ renderCase: RenderCase) {
    let result = MathImageResult.useMathImage(
      latex: renderCase.latex, font: font, fontSize: fontSize)

    #expect(
      result.error == nil,
      "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")"
    )
    #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

    if let image = result.image, let imageData = image.pngData() {
      _ = saveImage(prefix: "cornerbracket", name: renderCase.name, pngData: imageData)
    }
  }

  @Test(arguments: doubleBracketCases)
  func doubleBrackets(_ renderCase: RenderCase) {
    let result = MathImageResult.useMathImage(
      latex: renderCase.latex, font: font, fontSize: fontSize)

    #expect(
      result.error == nil,
      "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")"
    )
    #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

    if let image = result.image, let imageData = image.pngData() {
      _ = saveImage(prefix: "cornerbracket", name: renderCase.name, pngData: imageData)
    }
  }
}
