import Testing
@testable import MathViews

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Binary Operator Render Tests

struct BinaryOperatorRenderTests {
    let font = MathFont.latinModern
    let fontSize: CGFloat = 20.0

    static let semidirectProductCases: [RenderCase] = [
        RenderCase(name: "ltimes", latex: "G \\ltimes H"),
        RenderCase(name: "rtimes", latex: "G \\rtimes H"),
        RenderCase(name: "bowtie", latex: "A \\bowtie B"),
    ]

    static let circledAndBoxedCases: [RenderCase] = [
        RenderCase(name: "oplus", latex: "a \\oplus b"),
        RenderCase(name: "ominus", latex: "a \\ominus b"),
        RenderCase(name: "otimes", latex: "a \\otimes b"),
        RenderCase(name: "circledast", latex: "a \\circledast b"),
        RenderCase(name: "circledcirc", latex: "a \\circledcirc b"),
        RenderCase(name: "boxplus", latex: "a \\boxplus b"),
        RenderCase(name: "boxminus", latex: "a \\boxminus b"),
        RenderCase(name: "boxtimes", latex: "a \\boxtimes b"),
        RenderCase(name: "boxdot", latex: "a \\boxdot b"),
    ]

    static let logicalCases: [RenderCase] = [
        RenderCase(name: "barwedge", latex: "p \\barwedge q"),
        RenderCase(name: "veebar", latex: "p \\veebar q"),
        RenderCase(name: "curlywedge", latex: "p \\curlywedge q"),
        RenderCase(name: "curlyvee", latex: "p \\curlyvee q"),
    ]

    @Test(arguments: semidirectProductCases)
    func semidirectProducts(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "binaryop", name: renderCase.name, pngData: imageData)
        }
    }

    @Test(arguments: circledAndBoxedCases)
    func circledAndBoxedOperators(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "binaryop", name: renderCase.name, pngData: imageData)
        }
    }

    @Test(arguments: logicalCases)
    func logicalOperators(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex, font: font, fontSize: fontSize,
        )

        #expect(
            result.error == nil,
            "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")",
        )
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "binaryop", name: renderCase.name, pngData: imageData)
        }
    }
}
