import Testing
@testable import MathViews
import CoreGraphics
import Foundation

struct MathImageTests {
    func safeImage(fileName: String, pngData: Data) {
        let imageFileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("image-\(fileName).png"))
        try? pngData.write(to: imageFileURL, options: [.atomicWrite])
    }
    @Test func mathImageScript() throws {
        let latex = Latex.samples.randomElement()!
        let mathfont = MathFont.allCases.randomElement()!
        let fontsize = CGFloat.random(in: 24 ... 36)
        let result = MathImageResult.useMathImage(latex: latex, font: mathfont, fontSize: fontsize)
        #expect(result.error == nil)
        #expect(result.image != nil)
        #expect(result.layoutInfo != nil)
        if result.error == nil, let image = result.image, let imageData = image.pngData() {
            safeImage(fileName: "test", pngData: imageData)
        }
    }
    @Test func sequentialMultipleImageScript() throws {
        var latex: String { Latex.samples.randomElement()! }
        var mathfont: MathFont { MathFont.allCases.randomElement()! }
        var fontsize: CGFloat { CGFloat.random(in: 20 ... 40) }
        for caseNumber in 0 ..< 20 {
            let result: MathImageResult
            switch caseNumber % 2 {
            case 0:
                result = MathImageResult.useMathImage(latex: latex, font: mathfont, fontSize: fontsize)
                #expect(result.error == nil)
                #expect(result.image != nil)
                #expect(result.layoutInfo != nil)
                if result.error == nil, let image = result.image, let imageData = image.pngData() {
                    safeImage(fileName: "\(caseNumber)", pngData: imageData)
                }
            default:
                result = MathImageResult.useMathImageRenderer(latex: latex, font: mathfont, fontSize: fontsize)
                #expect(result.error == nil)
                #expect(result.image != nil)
                if result.error == nil, let image = result.image, let imageData = image.pngData() {
                    safeImage(fileName: "\(caseNumber)", pngData: imageData)
                }
            }
        }
    }

    @Test func concurrentMathImageScript() {
        let queue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
        let group = DispatchGroup()
        var latex: String { Latex.samples.randomElement()! }
        var mathfont: MathFont { MathFont.allCases.randomElement()! }
        var size: CGFloat { CGFloat.random(in: 20 ... 40) }
        let totalCases = 20
        for caseNumber in 0 ..< totalCases {
            group.enter()
            let l = latex, m = mathfont, s = size
            queue.async {
                defer { group.leave() }
                let result: MathImageResult
                switch caseNumber % 2 {
                case 0:
                    result = MathImageResult.useMathImage(latex: l, font: m, fontSize: s)
                    #expect(result.error == nil)
                    #expect(result.image != nil)
                    #expect(result.layoutInfo != nil)
                default:
                    result = MathImageResult.useMathImageRenderer(latex: l, font: m, fontSize: s)
                    #expect(result.error == nil)
                    #expect(result.image != nil)
                }
            }
        }
        group.wait()
    }
}
struct MathImageResult {
    let error: ParseError?
    let image: PlatformImage?
    let layoutInfo: MathImage.LayoutInfo?
}
extension MathImageResult {
    static func useMathImageRenderer(latex: String, font: MathFont, fontSize: CGFloat, textColor: MathColor = MathColor.black) -> MathImageResult {
        let alignment = MathTextAlignment.left
        let formatter = MathImageRenderer(latex: latex, fontSize: fontSize - 1.0,
                                    textColor: textColor,
                                    labelMode: .text, textAlignment: alignment)
        formatter.font = font.fontInstance(size: fontSize)
        let (error, image) = formatter.asImage()
        return MathImageResult(error: error, image: image, layoutInfo: nil)
    }
    static func useMathImage(latex: String, font: MathFont, fontSize: CGFloat, textColor: MathColor = MathColor.black) -> MathImageResult {
        let alignment = MathTextAlignment.left
        var formatter = MathImage(latex: latex, fontSize: fontSize - 1.0,
                                  textColor: textColor,
                                  labelMode: .text, textAlignment: alignment)
        formatter.font = font
        let (error, image, layoutInfo) = formatter.asImage()
        return MathImageResult(error: error, image: image, layoutInfo: layoutInfo)
    }
}
#if os(macOS)
import AppKit
extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
}
extension Data {
    var bitmap: NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}
extension NSImage {
    func pngData() -> Data? {
        tiffRepresentation?.bitmap?.png
    }
}
#endif

// MARK: - Shared helpers for Swift Testing render tests

struct RenderCase: Sendable, CustomTestStringConvertible {
    let name: String
    let latex: String
    var testDescription: String { name }
}

func saveImage(prefix: String, name: String, pngData: Data) -> URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory().appending("\(prefix)-\(name).png"))
    try? pngData.write(to: url, options: [.atomicWrite])
    return url
}

enum Latex {
    static let samples: [String] = [
        #"(a_1 + a_2)^2 = a_1^2 + 2a_1a_2 + a_2^2"#,
        #"x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}"#,
        #"\sigma = \sqrt{\frac{1}{N}\sum_{i=1}^N (x_i - \mu)^2}"#,
        #"\neg(P\land Q) \iff (\neg P)\lor(\neg Q)"#,
        #"\cos(\theta + \varphi) = \cos(\theta)\cos(\varphi) - \sin(\theta)\sin(\varphi)"#,
        #"\lim_{x\to\infty}\left(1 + \frac{k}{x}\right)^x = e^k"#,
        #"f(x) = \int\limits_{-\infty}^\infty\hat f(\xi)\,e^{2 \pi i \xi x}\,\mathrm{d}\xi"#,
        #"{n \brace k} = \frac{1}{k!}\sum_{j=0}^k (-1)^{k-j}\binom{k}{j}(k-j)^n"#,
        #"\int_{-\infty}^{\infty} \! e^{-x^2} dx = \sqrt{\pi}"#,
        #"\frac{1}{n}\sum_{i=1}^{n}x_i \geq \sqrt[n]{\prod_{i=1}^{n}x_i}"#,
        #"\left(\sum_{k=1}^n a_k b_k \right)^2 \le \left(\sum_{k=1}^n a_k^2\right)\left(\sum_{k=1}^n b_k^2\right)"#,
        #"\left( \sum_{k=1}^n a_k b_k \right)^2 \leq \left( \sum_{k=1}^n a_k^2 \right) \left( \sum_{k=1}^n b_k^2 \right)"#,
        #"i\hbar\frac{\partial}{\partial t}\mathbf\Psi(\mathbf{x},t) = -\frac{\hbar}{2m}\nabla^2\mathbf\Psi(\mathbf{x},t) + V(\mathbf{x})\mathbf\Psi(\mathbf{x},t)"#,
        #"""
            \begin{gather}
            \dot{x} = \sigma(y-x) \\
            \dot{y} = \rho x - y - xz \\
            \dot{z} = -\beta z + xy"
            \end{gather}
        """#,
        #"""
            \vec \bf V_1 \times \vec \bf V_2 =  \begin{vmatrix}
            \hat \imath &\hat \jmath &\hat k \\
            \frac{\partial X}{\partial u} & \frac{\partial Y}{\partial u} & 0 \\
            \frac{\partial X}{\partial v} & \frac{\partial Y}{\partial v} & 0
            \end{vmatrix}
        """#,
        #"""
            \begin{eqalign}
            \nabla \cdot \vec{\bf E} & = \frac {\rho} {\varepsilon_0} \\
            \nabla \cdot \vec{\bf B} & = 0 \\
            \nabla \times \vec{\bf E} &= - \frac{\partial\vec{\bf B}}{\partial t} \\
            \nabla \times \vec{\bf B} & = \mu_0\vec{\bf J} + \mu_0\varepsilon_0 \frac{\partial\vec{\bf E}}{\partial t}
            \end{eqalign}
        """#,
        #"\log_b(x) = \frac{\log_a(x)}{\log_a(b)}"#,
        #"""
            \begin{pmatrix}
            a & b\\ c & d
            \end{pmatrix}
            \begin{pmatrix}
            \alpha & \beta \\ \gamma & \delta
            \end{pmatrix} =
            \begin{pmatrix}
            a\alpha + b\gamma & a\beta + b \delta \\
            c\alpha + d\gamma & c\beta + d \delta
            \end{pmatrix}
        """#,
        #"""
            \frak Q(\lambda,\hat{\lambda}) =
            -\frac{1}{2} \mathbb P(O \mid \lambda ) \sum_s \sum_m \sum_t \gamma_m^{(s)} (t) +\\
            \quad \left( \log(2 \pi ) + \log \left| \cal C_m^{(s)} \right| +
            \left( o_t - \hat{\mu}_m^{(s)} \right) ^T \cal C_m^{(s)-1} \right)
        """#
    ]
}
