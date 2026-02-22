#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Testing
@testable import MathViews

// MARK: - Dirac Notation Render Tests

struct DiracRenderTests {

    let font = MathFont.latinModernFont
    let fontSize: CGFloat = 20.0

    static let diracExpressionCases: [RenderCase] = [
        RenderCase(name: "bra_0", latex: "\\bra{0}"),
        RenderCase(name: "ket_1", latex: "\\ket{1}"),
        RenderCase(name: "braket_01", latex: "\\braket{0}{1}"),
        RenderCase(name: "braket_nm", latex: "\\braket{n}{m}"),
        RenderCase(name: "schrodinger", latex: "H\\ket{\\psi}=E\\ket{\\psi}"),
        RenderCase(name: "matrix_element", latex: "\\bra{\\phi}A\\ket{\\psi}"),
        RenderCase(name: "completeness", latex: "\\sum_n\\ket{n}\\bra{n}=I"),
    ]

    @Test func braRendering() throws {
        // Test \bra{psi} renders correctly
        let latex = "\\bra{\\psi}"
        let result = MathImageResult.useMathImage(latex: latex, font: font, fontSize: fontSize)

        #expect(result.error == nil, "Should render \\bra{\\psi} without error: \(result.error?.localizedDescription ?? "")")
        #expect(result.image != nil, "Should produce image for \\bra{\\psi}")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "dirac", name: "bra_psi", pngData: imageData)
        }
    }

    @Test func ketRendering() throws {
        // Test \ket{psi} renders correctly
        let latex = "\\ket{\\psi}"
        let result = MathImageResult.useMathImage(latex: latex, font: font, fontSize: fontSize)

        #expect(result.error == nil, "Should render \\ket{\\psi} without error: \(result.error?.localizedDescription ?? "")")
        #expect(result.image != nil, "Should produce image for \\ket{\\psi}")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "dirac", name: "ket_psi", pngData: imageData)
        }
    }

    @Test func braketRendering() throws {
        // Test \braket{phi}{psi} renders correctly
        let latex = "\\braket{\\phi}{\\psi}"
        let result = MathImageResult.useMathImage(latex: latex, font: font, fontSize: fontSize)

        #expect(result.error == nil, "Should render \\braket{\\phi}{\\psi} without error: \(result.error?.localizedDescription ?? "")")
        #expect(result.image != nil, "Should produce image for \\braket{\\phi}{\\psi}")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "dirac", name: "braket_phi_psi", pngData: imageData)
        }
    }

    @Test(arguments: diracExpressionCases)
    func diracExpressionRendering(_ renderCase: RenderCase) throws {
        let result = MathImageResult.useMathImage(latex: renderCase.latex, font: font, fontSize: fontSize)

        #expect(result.error == nil, "Should render \(renderCase.latex) without error: \(result.error?.localizedDescription ?? "")")
        #expect(result.image != nil, "Should produce image for \(renderCase.latex)")

        if let image = result.image, let imageData = image.pngData() {
            _ = saveImage(prefix: "dirac", name: renderCase.name, pngData: imageData)
        }
    }
}
