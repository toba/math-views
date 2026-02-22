import Testing

@testable import MathViews

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

// MARK: - Boldsymbol Render Tests

struct BoldsymbolRenderTests {

  let font = MathFont.latinModernFont
  let fontSize: CGFloat = 20.0

  static let greekCases: [RenderCase] = [
    RenderCase(name: "alpha", latex: "\\boldsymbol{\\alpha}"),
    RenderCase(name: "beta", latex: "\\boldsymbol{\\beta}"),
    RenderCase(name: "gamma", latex: "\\boldsymbol{\\gamma}"),
    RenderCase(name: "Gamma_upper", latex: "\\boldsymbol{\\Gamma}"),
    RenderCase(name: "mu_sigma", latex: "\\boldsymbol{\\mu} + \\boldsymbol{\\sigma}"),
  ]

  static let comparisonCases: [RenderCase] = [
    RenderCase(name: "x_comparison", latex: "\\mathbf{x} \\text{ vs } \\boldsymbol{x}"),
    RenderCase(
      name: "alpha_comparison", latex: "\\mathbf{\\alpha} \\text{ vs } \\boldsymbol{\\alpha}"),
    RenderCase(name: "gradient", latex: "\\boldsymbol{\\nabla} f = \\mathbf{0}"),
  ]

  @Test(arguments: greekCases)
  func boldsymbolGreekRendering(_ renderCase: RenderCase) {
    let result = MathImageResult.useMathImage(
      latex: renderCase.latex, font: font, fontSize: fontSize)

    #expect(
      result.error == nil,
      "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")"
    )
    #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

    if let image = result.image, let imageData = image.pngData() {
      _ = saveImage(prefix: "boldsymbol", name: "greek_\(renderCase.name)", pngData: imageData)
    }
  }

  @Test(arguments: comparisonCases)
  func boldsymbolComparisonWithMathbf(_ renderCase: RenderCase) {
    let result = MathImageResult.useMathImage(
      latex: renderCase.latex, font: font, fontSize: fontSize)

    #expect(
      result.error == nil,
      "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")"
    )
    #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

    if let image = result.image, let imageData = image.pngData() {
      _ = saveImage(prefix: "boldsymbol", name: "compare_\(renderCase.name)", pngData: imageData)
    }
  }
}
