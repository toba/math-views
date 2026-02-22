import Testing

@testable import MathViews

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

// MARK: - EXAMPLES.md Image Generation Tests

/// Generates PNG images for EXAMPLES.md examples that are missing images
/// Run this test to regenerate all example images in the img/ directory
struct ExamplesImageGenerationTests {

  let font = MathFont.latinModernFont
  let fontSize: CGFloat = 20.0

  /// Get the path to the project's img/ directory
  private func imgDirectory() -> URL? {
    // Use #filePath to find project root (Tests/MathViewsTests/ExamplesImageGenerationTests.swift)
    let testFile = URL(fileURLWithPath: #filePath)
    let projectRoot =
      testFile
      .deletingLastPathComponent()  // MathViewsTests/
      .deletingLastPathComponent()  // Tests/
      .deletingLastPathComponent()  // project root
    return projectRoot.appendingPathComponent("img")
  }

  private func saveImageToProject(named name: String, mode: String, pngData: Data) -> Bool {
    guard let imgDir = imgDirectory() else {
      print("Could not determine img directory")
      return false
    }

    // Ensure directory exists
    try? FileManager.default.createDirectory(at: imgDir, withIntermediateDirectories: true)

    let filename = "\(name)-\(mode).png"
    let fileURL = imgDir.appendingPathComponent(filename)

    do {
      try pngData.write(to: fileURL)
      print("Saved: \(fileURL.path)")
      return true
    } catch {
      print("Failed to save \(filename): \(error)")
      return false
    }
  }

  static let exampleCases: [RenderCase] = [
    RenderCase(name: "dirac", latex: #"\bra{\psi} \ket{\phi} = \braket{\psi}{\phi}"#),
    RenderCase(
      name: "operatorname",
      latex:
        #"\operatorname{argmax}_{x \in \mathbb{R}} f(x) = \operatorname*{lim}_{n \to \infty} a_n"#),
    RenderCase(name: "delimiter", latex: #"\Bigg( \bigg( \Big( \big( x \big) \Big) \bigg) \Bigg)"#),
    RenderCase(
      name: "boldsymbol", latex: #"\boldsymbol{\alpha} + \boldsymbol{\beta} = \boldsymbol{\gamma}"#),
    RenderCase(name: "trighyp", latex: #"\arcsinh x + \arccosh y = \arctanh z"#),
  ]

  /// Generate both light and dark mode images for each example
  @Test(arguments: exampleCases)
  func generateExampleImages(_ renderCase: RenderCase) {
    // Generate light mode image (black text)
    let lightResult = MathImageResult.useMathImage(
      latex: renderCase.latex,
      font: font,
      fontSize: fontSize,
      textColor: MathColor.black
    )

    #expect(
      lightResult.error == nil,
      "Failed to render '\(renderCase.name)' (light): \(lightResult.error?.localizedDescription ?? "")"
    )

    guard let lightImage = lightResult.image, let lightData = lightImage.pngData() else {
      Issue.record("No image generated for '\(renderCase.name)' (light)")
      return
    }

    // Generate dark mode image (white text)
    let darkResult = MathImageResult.useMathImage(
      latex: renderCase.latex,
      font: font,
      fontSize: fontSize,
      textColor: MathColor.white
    )

    #expect(
      darkResult.error == nil,
      "Failed to render '\(renderCase.name)' (dark): \(darkResult.error?.localizedDescription ?? "")"
    )

    guard let darkImage = darkResult.image, let darkData = darkImage.pngData() else {
      Issue.record("No image generated for '\(renderCase.name)' (dark)")
      return
    }

    // Save both images
    let lightSaved = saveImageToProject(named: renderCase.name, mode: "light", pngData: lightData)
    let darkSaved = saveImageToProject(named: renderCase.name, mode: "dark", pngData: darkData)
    #expect(
      lightSaved && darkSaved, "Should save both light and dark images for '\(renderCase.name)'")
  }
}
