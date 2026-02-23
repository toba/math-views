import Testing
@testable import MathViews

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Operatorname Render Tests

struct OperatornameRenderTests {
    let font = MathFont.latinModern
    let fontSize: CGFloat = 20.0

    static let operatornameCases: [RenderCase] = [
        RenderCase(name: "lcm", latex: "\\operatorname{lcm}(a,b)"),
        RenderCase(name: "sgn", latex: "\\operatorname{sgn}(x)"),
        RenderCase(name: "ord", latex: "\\operatorname{ord}(g)"),
        RenderCase(name: "trace", latex: "\\operatorname{Tr}(A)"),
        RenderCase(name: "rank", latex: "\\operatorname{rank}(M)"),
    ]

    static let operatornameStarCases: [RenderCase] = [
        RenderCase(name: "argmax", latex: "\\operatorname*{argmax}_{x \\in X} f(x)"),
        RenderCase(name: "argmin", latex: "\\operatorname*{argmin}_{x \\in X} f(x)"),
        RenderCase(name: "esssup", latex: "\\operatorname*{esssup}_{x \\in \\mathbb{R}} |f(x)|"),
    ]

    static let comparisonCases: [RenderCase] = [
        RenderCase(name: "compare_sin", latex: "\\sin x + \\operatorname{mysin} x"),
        RenderCase(
            name: "compare_lim",
            latex: "\\lim_{n \\to \\infty} a_n = \\operatorname*{lim}_{n \\to \\infty} b_n",
        ),
    ]

    @Test(arguments: operatornameCases)
    func operatornameRendering(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(
                prefix: "operatorname",
                name: "basic_\(renderCase.name)",
                pngData: imageData,
            )
        }
    }

    @Test(arguments: operatornameStarCases)
    func operatornameStarRendering(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(
                prefix: "operatorname",
                name: "star_\(renderCase.name)",
                pngData: imageData,
            )
        }
    }

    @Test(arguments: comparisonCases)
    func operatornameComparisonWithBuiltIn(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "operatorname", name: renderCase.name, pngData: imageData)
        }
    }
}
