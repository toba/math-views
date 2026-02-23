import Testing
@testable import MathViews

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Delimiter Sizing Render Tests

struct DelimiterSizingRenderTests {
    static let bigDelimiterCases: [RenderCase] = [
        RenderCase(
            name: "01_sizes_comparison",
            latex: #"\Bigg( \bigg( \Big( \big( x \big) \Big) \bigg) \Bigg)"#,
        ),
        RenderCase(name: "02_size1_big_parens", latex: #"\big( \frac{a}{b} \big)"#),
        RenderCase(name: "03_size2_Big_parens", latex: #"\Big( \frac{a}{b} \Big)"#),
        RenderCase(name: "04_size3_bigg_parens", latex: #"\bigg( \frac{a}{b} \bigg)"#),
        RenderCase(name: "05_size4_Bigg_parens", latex: #"\Bigg( \frac{a}{b} \Bigg)"#),
        RenderCase(
            name: "06_standalone_sizes",
            latex: #"\big( \quad \Big( \quad \bigg( \quad \Bigg("#,
        ),
        RenderCase(
            name: "07_mixed_expression", latex: #"f\big(g(x)\big) = \Big(\sum_{i=1}^n x_i\Big)"#,
        ),
        RenderCase(
            name: "08_brackets", latex: #"\Bigg[ \bigg[ \Big[ \big[ x \big] \Big] \bigg] \Bigg]"#,
        ),
        RenderCase(
            name: "09_left_right_vs_Big",
            latex: #"\left( \frac{a}{b} \right) \quad \Big( \frac{a}{b} \Big)"#,
        ),
        RenderCase(
            name: "10_vertical_bars",
            latex: #"\big| \Big| \bigg| \Bigg| x \Bigg| \bigg| \Big| \big|"#,
        ),
        RenderCase(
            name: "11_nested_left_right",
            latex: #"\left( \left( \left( \left( x \right) \right) \right) \right)"#,
        ),
        RenderCase(
            name: "12_nested_growing_content",
            latex: #"\left( a + \left( b + \left( c + \left( d \right) \right) \right) \right)"#,
        ),
        RenderCase(
            name: "13_manual_vs_auto_nested",
            latex:
            #"\Bigg(\bigg(\Big(\big( x \big)\Big)\bigg)\Bigg) \quad \left(\left(\left(\left( x \right)\right)\right)\right)"#,
        ),
        RenderCase(
            name: "14_nested_fractions_auto",
            latex: #"\left( \frac{a}{\left( \frac{b}{\left( \frac{c}{d} \right)} \right)} \right)"#,
        ),
        RenderCase(
            name: "15_nested_fractions_manual",
            latex: #"\Bigg( \frac{a}{\Big( \frac{b}{\big( \frac{c}{d} \big)} \Big)} \Bigg)"#,
        ),
    ]

    @Test(arguments: bigDelimiterCases)
    func bigDelimiterRendering(_ renderCase: RenderCase) {
        let result = MathImageResult.useMathImage(
            latex: renderCase.latex,
            font: .latinModern,
            fontSize: 30,
        )

        #expect(
            result.error == nil,
            "Failed to render '\(renderCase.name)': \(result.error?.localizedDescription ?? "")",
        )

        guard let image = result.image, let imageData = image.pngData() else {
            Issue.record("No image generated for '\(renderCase.name)'")
            return
        }

        _ = saveImage(prefix: "delimiter", name: renderCase.name, pngData: imageData)
    }
}
