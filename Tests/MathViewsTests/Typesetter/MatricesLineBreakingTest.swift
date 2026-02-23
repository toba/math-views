import Testing
@testable import MathViews
import Foundation
import CoreGraphics

/// Test case to verify the fix for incorrect line breaking with mixed text and math
struct MatricesLineBreakingTest {
    @Test func matricesLineBreakingFixed() throws {
        var helper = TypesetterHelper()
        helper.latex = "\\(\\text{Add corresponding entries of matrices }A\\text{ and }B\\text{.}\\)"
        helper.fontSize = 20
        helper.maxWidth = 235.0

        let displayList = try #require(helper.displayList)

        // Verify we have multiple sub-displays (text characters + math variables)
        #expect(!displayList.subDisplays.isEmpty, "Should have sub-displays")

        let size = helper.intrinsicContentSize
        #expect(size.width > 0, "Width should be positive")
        #expect(size.height > 0, "Height should be positive")

        let ctLineDisplays = displayList.subDisplays.compactMap { $0 as? CTLineDisplay }
        #expect(!ctLineDisplays.isEmpty, "Should have CTLine displays")

        let hasRomanText = ctLineDisplays.contains { display in
            if let text = display.attributedString?.string {
                return text.contains("A") && text.count == 1 && text == "A"
                    || text.contains("c") && text.count == 1
                    || text.contains("o") && text.count == 1
            }
            return false
        }

        #expect(
            hasRomanText || ctLineDisplays.count > 10,
            "Text should be properly tokenized (not fused with math variables)",
        )
    }

    @Test func textAndMathNotFused() throws {
        var helper = TypesetterHelper()
        helper.latex = "\\(\\text{hello }x\\text{ world}\\)"
        helper.fontSize = 20

        let displayList = try #require(helper.displayList, "Display list should be created")

        let ctLineDisplays = displayList.subDisplays.compactMap { $0 as? CTLineDisplay }

        #expect(
            ctLineDisplays.count > 1,
            "Text atoms should not be fused with math variable atoms",
        )

        let size = helper.intrinsicContentSize
        #expect(size.width > 0)
        #expect(size.height > 0)
    }
}
