import Testing
@testable import MathViews

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Trig Function Render Tests

struct TrigFunctionRenderTests {
    let font = MathFont.latinModern
    let fontSize: CGFloat = 20.0

    nonisolated static let inverseTrigCases: [RenderCase] = [
        RenderCase(name: "arccot", latex: "\\arccot x"),
        RenderCase(name: "arcsec", latex: "\\arcsec x"),
        RenderCase(name: "arccsc", latex: "\\arccsc x"),
    ]

    nonisolated static let hyperbolicCases: [RenderCase] = [
        RenderCase(name: "sech", latex: "\\sech x"),
        RenderCase(name: "csch", latex: "\\csch x"),
        RenderCase(name: "arcsinh", latex: "\\arcsinh x"),
        RenderCase(name: "arccosh", latex: "\\arccosh x"),
        RenderCase(name: "arctanh", latex: "\\arctanh x"),
    ]

    @Test(arguments: inverseTrigCases)
    func inverseTrigFunctions(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "trig", name: renderCase.name, pngData: imageData)
        }
    }

    @Test(arguments: hyperbolicCases)
    func hyperbolicFunctions(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "trig", name: renderCase.name, pngData: imageData)
        }
    }
}
