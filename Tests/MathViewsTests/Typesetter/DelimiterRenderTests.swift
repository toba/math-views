import Testing

@testable import MathViews

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

// MARK: - Delimiter Render Tests

struct DelimiterRenderTests {
  let font = MathFont.latinModern
  let fontSize: CGFloat = 24.0

  nonisolated static let delimiterSizeCases: [RenderCase] = [
    RenderCase(name: "size_comparison_parens", latex: #"( \big( \Big( \bigg( \Bigg("#),
    RenderCase(name: "size_comparison_parens_close", latex: #") \big) \Big) \bigg) \Bigg)"#),
    RenderCase(name: "size_comparison_brackets", latex: #"[ \big[ \Big[ \bigg[ \Bigg["#),
    RenderCase(name: "size_comparison_braces", latex: #"\{ \big\{ \Big\{ \bigg\{ \Bigg\{"#),
    RenderCase(name: "size_comparison_pipes", latex: #"| \big| \Big| \bigg| \Bigg|"#),
    RenderCase(name: "bigl_bigr_parens", latex: #"\bigl( x \bigr)"#),
    RenderCase(name: "Bigl_Bigr_brackets", latex: #"\Bigl[ x \Bigr]"#),
    RenderCase(name: "biggl_biggr_braces", latex: #"\biggl\{ x \biggr\}"#),
    RenderCase(name: "Biggl_Biggr_pipes", latex: #"\Biggl| x \Biggr|"#),
    RenderCase(name: "bigm_pipe", latex: #"a \bigm| b"#),
    RenderCase(name: "Bigm_Biggm_pipes", latex: #"a \Bigm| b \Biggm| c"#),
    RenderCase(name: "bigl_frac", latex: #"\bigl( \frac{a}{b} \bigr)"#),
    RenderCase(name: "Bigl_frac", latex: #"\Bigl( \frac{a}{b} \Bigr)"#),
    RenderCase(name: "biggl_frac", latex: #"\biggl( \frac{a}{b} \biggr)"#),
    RenderCase(name: "Biggl_frac", latex: #"\Biggl( \frac{a}{b} \Biggr)"#),
    RenderCase(
      name: "auto_vs_manual",
      latex: #"\left( \frac{a}{b} \right) \quad \big( \frac{a}{b} \big)"#,
    ),
  ]

  @Test(arguments: delimiterSizeCases)
  func delimiterSizeRendering(_ renderCase: RenderCase) {
    let result = MathImageResult.useMathImage(
      latex: renderCase.latex, font: font, fontSize: fontSize,
    )

    #expect(
      result.error == nil,
      "Should render \(renderCase.name) without error: \(result.error?.localizedDescription ?? "")",
    )
    #expect(result.image != nil, "Should produce image for \(renderCase.name)")

    if let image = result.image, let imageData = image.pngData() {
      _ = saveImage(prefix: "delimiter", name: renderCase.name, pngData: imageData)
    }
  }

  /// Test that delimiter sizes increase progressively
  @Test func delimiterSizeProgression() {
    let font = MathFont.latinModern
    let fontSize: CGFloat = 24.0

    // Render each size and compare heights
    let sizeCommands = ["big", "Big", "bigg", "Bigg"]
    var previousHeight: CGFloat = 0

    for command in sizeCommands {
      let latex = "\\\(command)("
      let result = MathImageResult.useMathImage(latex: latex, font: font, fontSize: fontSize)

      #expect(result.error == nil, "Should render \\\(command)( without error")
      #expect(result.image != nil, "Should produce image for \\\(command)(")

      if let layoutInfo = result.layoutInfo {
        let currentHeight = layoutInfo.ascent + layoutInfo.descent

        // Each size should be larger than the previous
        #expect(
          currentHeight > previousHeight,
          "\\\(command) height (\(currentHeight)) should be greater than previous (\(previousHeight))",
        )
        previousHeight = currentHeight
      }

      if let image = result.image, let imageData = image.pngData() {
        _ = saveImage(
          prefix: "delimiter",
          name: "progression_\(command)",
          pngData: imageData,
        )
      }
    }
  }
}
