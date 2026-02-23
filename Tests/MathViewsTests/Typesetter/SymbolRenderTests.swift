import Testing
@testable import MathViews

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Symbol Render Tests

struct SymbolRenderTests {
    nonisolated static let priority1SymbolCases: [RenderCase] = [
        RenderCase(name: "01_greek_varkappa", latex: #"\varkappa"#),
        RenderCase(
            name: "02_arrows", latex: #"\longmapsto \quad \hookrightarrow \quad \hookleftarrow"#,
        ),
        RenderCase(
            name: "03_slanted_ineq",
            latex: #"a \leqslant b \leqslant c \quad x \geqslant y \geqslant z"#,
        ),
        RenderCase(name: "04_precedence", latex: #"a \preceq b \quad c \succeq d"#),
        RenderCase(name: "05_turnstiles", latex: #"A \vdash B \quad C \dashv D \quad E \bowtie F"#),
        RenderCase(name: "06_diamond", latex: #"A \diamond B \diamond C"#),
        RenderCase(name: "07_hebrew", latex: #"\aleph \quad \beth \quad \gimel \quad \daleth"#),
        RenderCase(name: "08_misc", latex: #"\varnothing \quad \Box \quad \measuredangle"#),
        RenderCase(
            name: "09_combined",
            latex: #"\varkappa \hookrightarrow \varnothing \quad a \leqslant b \preceq c"#,
        ),
        RenderCase(
            name: "10_in_context",
            latex: #"f: A \longmapsto B, \quad x \leqslant y \implies \Box P"#,
        ),
    ]

    nonisolated static let negatedRelationCases: [RenderCase] = [
        RenderCase(
            name: "11_ineq_negations",
            latex: #"a \nless b \quad c \ngtr d \quad x \nleq y \quad z \ngeq w"#,
        ),
        RenderCase(name: "12_slant_negations", latex: #"a \nleqslant b \quad c \ngeqslant d"#),
        RenderCase(
            name: "13_neq_variants",
            latex: #"a \lneq b \quad c \gneq d \quad x \lneqq y \quad z \gneqq w"#,
        ),
        RenderCase(
            name: "14_sim_negations",
            latex: #"a \lnsim b \quad c \gnsim d \quad x \lnapprox y \quad z \gnapprox w"#,
        ),
        RenderCase(
            name: "15_ordering_neg",
            latex: #"a \nprec b \quad c \nsucc d \quad x \npreceq y \quad z \nsucceq w"#,
        ),
        RenderCase(name: "16_prec_variants", latex: #"a \precneqq b \quad c \succneqq d"#),
        RenderCase(
            name: "17_prec_sim",
            latex: #"a \precnsim b \quad c \succnsim d \quad x \precnapprox y \quad z \succnapprox w"#,
        ),
        RenderCase(name: "18_sim_cong", latex: #"a \nsim b \quad c \ncong d"#),
        RenderCase(
            name: "19_mid_parallel",
            latex: #"a \nmid b \quad c \nshortmid d \quad x \nparallel y \quad z \nshortparallel w"#,
        ),
        RenderCase(name: "20_set_neg", latex: #"A \nsubseteq B \quad C \nsupseteq D"#),
        RenderCase(
            name: "21_set_neq",
            latex: #"A \subsetneq B \quad C \supsetneq D \quad X \subsetneqq Y \quad Z \supsetneqq W"#,
        ),
        RenderCase(name: "22_set_var", latex: #"A \varsubsetneq B \quad C \varsupsetneq D"#),
        RenderCase(name: "23_notni", latex: #"a \notni b \quad c \nni d"#),
        RenderCase(
            name: "24_triangle",
            latex:
            #"A \ntriangleleft B \quad C \ntriangleright D \quad X \ntrianglelefteq Y \quad Z \ntrianglerighteq W"#,
        ),
        RenderCase(
            name: "25_turnstile_neg",
            latex: #"A \nvdash B \quad C \nvDash D \quad X \nVdash Y \quad Z \nVDash W"#,
        ),
        RenderCase(name: "26_sq_subset", latex: #"A \nsqsubseteq B \quad C \nsqsupseteq D"#),
        RenderCase(
            name: "27_combined",
            latex: #"x \nless y \nleq z \quad A \nsubseteq B \ntriangleleft C"#,
        ),
        RenderCase(name: "28_with_positive", latex: #"a \leq b \quad \text{but} \quad c \nleq d"#),
    ]

    @Test(arguments: priority1SymbolCases)
    func priority1SymbolRendering(_ renderCase: RenderCase) {
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

        _ = saveImage(prefix: "symbol", name: renderCase.name, pngData: imageData)
    }

    @Test(arguments: negatedRelationCases)
    func negatedRelationRendering(_ renderCase: RenderCase) {
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

        _ = saveImage(prefix: "symbol", name: renderCase.name, pngData: imageData)
    }
}
