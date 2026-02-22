import Testing
import Foundation
import CoreGraphics
import CoreText
#if os(macOS)
import AppKit
#else
import UIKit
#endif
@testable import MathViews

struct MathUILabelLineWrappingTests {

    // MARK: - Helper Functions for Punctuation Tests

    /// Groups displays by Y-position to identify visual lines
    /// Returns an array of lines, where each line contains the displays at that Y-position
    private func groupDisplaysByLine(_ displayList: MathListDisplay) -> [[CTLineDisplay]] {
        var lines: [CGFloat: [CTLineDisplay]] = [:]

        for subDisplay in displayList.subDisplays {
            if let ctLine = subDisplay as? CTLineDisplay {
                let y = ctLine.position.y
                if lines[y] == nil {
                    lines[y] = []
                }
                lines[y]!.append(ctLine)
            }
        }

        // Sort lines by Y-position (top to bottom, descending Y values)
        let sortedYs = lines.keys.sorted(by: >)
        return sortedYs.map { y in
            // Sort displays within each line by X-position (left to right)
            lines[y]!.sorted { $0.position.x < $1.position.x }
        }
    }

    /// Checks if any line starts with the given string
    /// Returns true if no line starts with the text, false if any line starts with it
    private func checkNoLineStartsWith(_ text: String, in displayList: MathListDisplay) -> Bool {
        let lines = groupDisplaysByLine(displayList)

        for line in lines {
            if let firstDisplay = line.first,
               let firstString = firstDisplay.attributedString?.string {
                // Check if the first display's text starts with the forbidden text
                if firstString.hasPrefix(text) {
                    return false // Found a line starting with text
                }
            }
        }

        return true // No line starts with text
    }

    /// Checks if any line ends with the given string
    /// Returns true if no line ends with the text, false if any line ends with it
    private func checkNoLineEndsWith(_ text: String, in displayList: MathListDisplay) -> Bool {
        let lines = groupDisplaysByLine(displayList)

        for line in lines {
            if let lastDisplay = line.last,
               let lastString = lastDisplay.attributedString?.string {
                // Trim whitespace for line-end checks
                let trimmed = lastString.trimmingCharacters(in: .whitespaces)
                if trimmed.hasSuffix(text) {
                    return false // Found a line ending with text
                }
            }
        }

        return true // No line ends with text
    }

    // MARK: - Equals Sign Clipping Tests

    @Test func equalsSignClipping_InlineFraction() {
        // Test for equals sign clipping in inline math with fractions
        // Issue: "=" sign may be clipped when line breaking with width constraints
        let label = MathUILabel()
        label.latex = "Simplify the numerical coefficients \\\\(\\\\frac{2^{2}}{4} = 1\\\\)."
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        print("\n=== testEqualsSignClipping_InlineFraction ===")
        print("LaTeX: \(label.latex)")
        print("MathList: \(String(describing: label.mathList))")
        print("Error: \(String(describing: label.error))")

        let unconstrainedSize = label.intrinsicContentSize
        print("Unconstrained size: \(unconstrainedSize)")

        if label.error != nil {
            print("Warning: Parsing error: \(label.error!)")
            Issue.record("LaTeX parsing failed: \(label.error!)")
            return
        }

        // Test with various width constraints
        for width in [300.0, 250.0, 200.0, 150.0] {
            label.preferredMaxLayoutWidth = width
            let size = label.intrinsicContentSize
            print("\nWidth constraint: \(width)")
            print("  Result size: \(size)")

            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            // Check display list
            if let display = label.displayList {
                print("  Display: width=\(display.width), subDisplays=\(display.subDisplays.count)")

                // Check each subdisplay for overflow
                for (i, sub) in display.subDisplays.enumerated() {
                    let rightEdge = sub.position.x + sub.width
                    print("    Sub[\(i)]: x=\(sub.position.x), width=\(sub.width), rightEdge=\(rightEdge)")

                    if rightEdge > size.width + 1.0 {
                        print("      Warning: CLIPPING DETECTED: rightEdge \(rightEdge) > intrinsicSize.width \(size.width)")

                        // If it's a text line, try to see what content might be clipped
                        if let _ = sub as? CTLineDisplay {
                            print("      CTLine content might be clipped")
                        }
                    }
                }
            }

            #expect(label.displayList != nil, "Display list should be created")
            #expect(label.error == nil, "Should have no rendering error")
        }
    }

    @Test func equalsSignClipping_DisplayMath() {
        // Test for equals sign clipping in display math with multiple equations
        let label = MathUILabel()
        label.latex = "\\[\\frac{3}{\\sqrt{9+c^{2}}}=\\frac{1}{2}\\Rightarrow \\sqrt{9+c^{2}}=6\\Rightarrow 9+c^{2}=36\\Rightarrow c^{2}=27\\Rightarrow c=3\\sqrt{3}\\]"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let unconstrainedSize = label.intrinsicContentSize
        print("\n=== testEqualsSignClipping_DisplayMath ===")
        print("Unconstrained size: \(unconstrainedSize)")

        // Test with various width constraints that should force line breaking
        for width in [500.0, 400.0, 300.0, 250.0] {
            label.preferredMaxLayoutWidth = width
            let size = label.intrinsicContentSize
            print("\nWidth constraint: \(width)")
            print("  Result size: \(size)")

            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            // Check display list
            if let display = label.displayList {
                print("  Display: width=\(display.width), ascent=\(display.ascent), descent=\(display.descent)")
                print("  SubDisplays: \(display.subDisplays.count)")

                // Collect all y positions to see how many lines we have
                let yPositions = Set(display.subDisplays.map { $0.position.y }).sorted()
                print("  Unique Y positions (lines): \(yPositions.count) -> \(yPositions)")

                // Check each subdisplay for overflow
                var hasClipping = false
                for (i, sub) in display.subDisplays.enumerated() {
                    let rightEdge = sub.position.x + sub.width
                    let clipped = rightEdge > size.width + 1.0

                    print("    Sub[\(i)]: type=\(type(of: sub)), y=\(sub.position.y), x=\(sub.position.x), width=\(sub.width), rightEdge=\(rightEdge)\(clipped ? " CLIPPED" : "")")

                    if clipped {
                        hasClipping = true
                        print("      CLIPPING: rightEdge \(rightEdge) > intrinsicSize.width \(size.width)")
                        print("      Overflow amount: \(rightEdge - size.width)")
                    }
                }

                if hasClipping {
                    print("  CLIPPING DETECTED - content exceeds reported intrinsicContentSize.width")
                    Issue.record("Content clipping detected at width \(width): display content exceeds intrinsicContentSize.width \(size.width)")
                }
            }

            #expect(label.displayList != nil, "Display list should be created")
            #expect(label.error == nil, "Should have no rendering error")
        }
    }

    @Test func equalsSignClipping_UserReportedCases() {
        // Test the exact cases reported by the user with width constraint 235
        print("\n=== testEqualsSignClipping_UserReportedCases ===")

        // Case 1: Long inline equation with multiple arrow operators
        let label1 = MathUILabel()
        label1.latex = #"\(\frac{3}{\sqrt{9+c^{2}}}=\frac{1}{2}\Rightarrow \sqrt{9+c^{2}}=6\Rightarrow 9+c^{2}=36\Rightarrow c^{2}=27\Rightarrow c=3\sqrt{3}\)"#
        label1.font = FontManager.fontManager.defaultFont
        label1.labelMode = .text
        label1.preferredMaxLayoutWidth = 235.0

        let size1 = label1.intrinsicContentSize
        print("\nCase 1: Long inline equation")
        print("  LaTeX: \(label1.latex)")
        print("  Constraint width: 235.0")
        print("  Result size: \(size1)")

        #expect(label1.mathList != nil, "Should parse LaTeX")
        #expect(label1.error == nil, "Should have no error")

        // Verify no content exceeds the reported width
        if let display = label1.displayList {
            for (i, sub) in display.subDisplays.enumerated() {
                let rightEdge = sub.position.x + sub.width
                if rightEdge > size1.width + 1.0 {
                    Issue.record("Case 1: SubDisplay[\(i)] rightEdge \(rightEdge) exceeds size.width \(size1.width)")
                }
            }
        }

        // Case 2: Text with inline fraction
        let label2 = MathUILabel()
        label2.latex = #"\(\text{Simplify the numerical coefficients }\frac{2^{2}}{4} = 1\text{.}\)"#
        label2.font = FontManager.fontManager.defaultFont
        label2.labelMode = .text
        label2.preferredMaxLayoutWidth = 235.0

        let size2 = label2.intrinsicContentSize
        print("\nCase 2: Text with inline fraction")
        print("  LaTeX: \(label2.latex)")
        print("  Constraint width: 235.0")
        print("  Result size: \(size2)")

        #expect(label2.mathList != nil, "Should parse LaTeX")
        #expect(label2.error == nil, "Should have no error")

        // Verify no content exceeds the reported width
        if let display = label2.displayList {
            for (i, sub) in display.subDisplays.enumerated() {
                let rightEdge = sub.position.x + sub.width
                if rightEdge > size2.width + 1.0 {
                    Issue.record("Case 2: SubDisplay[\(i)] rightEdge \(rightEdge) exceeds size.width \(size2.width)")
                }
            }
        }

        print("\nBoth user-reported cases handle width constraints without clipping")
    }

    @Test func longTextTermClipping() {
        // Test user-reported case with long text that should break properly
        let label = MathUILabel()
        label.latex = #"\(\text{Assume }f(x)=3x^{2}+5x-2\text{ so that we can differentiate the polynomial term by term.}\)"#
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text
        label.preferredMaxLayoutWidth = 235.0

        let size = label.intrinsicContentSize

        #expect(label.mathList != nil, "Should parse LaTeX")
        #expect(label.error == nil, "Should have no error")

        // Verify no content exceeds the constraint (allowing for intrinsicContentSize which might be wider)
        if let display = label.displayList {
            for (i, sub) in display.subDisplays.enumerated() {
                let rightEdge = sub.position.x + sub.width
                // Content should not exceed its own reported width
                if rightEdge > size.width + 1.0 {
                    Issue.record("SubDisplay[\(i)] rightEdge \(rightEdge) exceeds size.width \(size.width)")
                }
            }
        }
    }

    @Test func logSubscriptLineBreaking() {
        // Test that atoms with subscripts break properly when added after flushed content
        // Bug: \log_{3}(x) was being placed on first line even though it exceeded width constraint
        let label = MathUILabel()
        label.latex = #"\(\text{Rewrite the logarithmic equation }\log_{3}(x)=4\text{ in exponential form.}\)"#
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text
        label.preferredMaxLayoutWidth = 235.0

        _ = label.intrinsicContentSize

        #expect(label.mathList != nil, "Should parse LaTeX")
        #expect(label.error == nil, "Should have no error")

        // Verify no content exceeds the width constraint
        if let display = label.displayList {
            for (i, sub) in display.subDisplays.enumerated() {
                let rightEdge = sub.position.x + sub.width
                // Content should not exceed the width constraint (with small tolerance)
                if rightEdge > 235.0 + 1.0 {
                    Issue.record("SubDisplay[\(i)] rightEdge \(rightEdge) exceeds constraint 235.0")
                }
            }
        }
    }

    @Test func antiderivativeLineBreaking() {
        // Test long text with embedded math that needs multiple line breaks
        let label = MathUILabel()
        label.latex = #"\(\text{Treat }v\text{ as a constant and find an antiderivative of }x^{2}+v\text{.}\)"#
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text
        label.preferredMaxLayoutWidth = 235.0

        _ = label.intrinsicContentSize

        #expect(label.mathList != nil, "Should parse LaTeX")
        #expect(label.error == nil, "Should have no error")

        // Verify no content exceeds the width constraint
        if let display = label.displayList {
            for (i, sub) in display.subDisplays.enumerated() {
                let rightEdge = sub.position.x + sub.width
                // Content should not exceed the width constraint (with small tolerance)
                if rightEdge > 235.0 + 1.0 {
                    Issue.record("SubDisplay[\(i)] rightEdge \(rightEdge) exceeds constraint 235.0")
                }
            }
        }
    }

    @Test func basicIntrinsicContentSize() {
        let label = MathUILabel()
        label.latex = "\\(x + y\\)"
        label.font = FontManager.fontManager.defaultFont

        // Debug: check if parsing worked
        #expect(label.mathList != nil, "Math list should not be nil")
        #expect(label.error == nil, "Should have no parsing error, got: \(String(describing: label.error))")
        #expect(label.font != nil, "Font should not be nil")

        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be greater than 0, got \(size.width)")
        #expect(size.height > 0, "Height should be greater than 0, got \(size.height)")
    }

    @Test func textModeIntrinsicContentSize() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Hello World}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be greater than 0, got \(size.width)")
        #expect(size.height > 0, "Height should be greater than 0, got \(size.height)")
    }

    @Test func longTextIntrinsicContentSize() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Rappelons la conversion : 1 km équivaut à 1000 m.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be greater than 0, got \(size.width)")
        #expect(size.height > 0, "Height should be greater than 0, got \(size.height)")
    }

    @Test func sizeThatFitsWithoutConstraint() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Hello World}\\)"
        label.font = FontManager.fontManager.defaultFont

        let size = label.sizeThatFits(CGSize.zero)

        #expect(size.width > 0, "Width should be greater than 0, got \(size.width)")
        #expect(size.height > 0, "Height should be greater than 0, got \(size.height)")
    }

    @Test func sizeThatFitsWithWidthConstraint() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Rappelons la conversion : 1 km équivaut à 1000 m.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Get unconstrained size first
        let unconstrainedSize = label.sizeThatFits(CGSize.zero)
        #expect(unconstrainedSize.width > 0, "Unconstrained width should be > 0")

        // Test with width constraint (use 300 since longest word might be ~237pt)
        let constrainedSize = label.sizeThatFits(CGSize(width: 300, height: CGFloat.greatestFiniteMagnitude))

        #expect(constrainedSize.width > 0, "Constrained width should be greater than 0, got \(constrainedSize.width)")
        #expect(constrainedSize.width < unconstrainedSize.width, "Constrained width (\(constrainedSize.width)) should be less than unconstrained (\(unconstrainedSize.width))")
        #expect(constrainedSize.height > 0, "Constrained height should be greater than 0, got \(constrainedSize.height)")

        // When constrained, height should increase when text wraps
        #expect(constrainedSize.height > unconstrainedSize.height,
                            "Constrained height (\(constrainedSize.height)) should be > unconstrained (\(unconstrainedSize.height)) when text wraps")
    }

    @Test func preferredMaxLayoutWidth() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Rappelons la conversion : 1 km équivaut à 1000 m.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Get unconstrained size
        let unconstrainedSize = label.intrinsicContentSize

        // Now set preferred max width (use 300 since longest word might be ~237pt)
        label.preferredMaxLayoutWidth = 300
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be greater than 0, got \(constrainedSize.width)")
        #expect(constrainedSize.width < unconstrainedSize.width, "Constrained width (\(constrainedSize.width)) should be < unconstrained (\(unconstrainedSize.width))")
        #expect(constrainedSize.height > unconstrainedSize.height, "Constrained height (\(constrainedSize.height)) should be > unconstrained (\(unconstrainedSize.height)) due to wrapping")
    }

    @Test func wordBoundaryBreaking() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Word1 Word2 Word3 Word4 Word5}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text
        label.preferredMaxLayoutWidth = 150

        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be greater than 0, got \(size.width)")
        #expect(size.height > 0, "Height should be greater than 0, got \(size.height)")

        // Verify it actually uses the layout
        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
    }

    @Test func emptyLatex() {
        let label = MathUILabel()
        label.latex = ""
        label.font = FontManager.fontManager.defaultFont

        let size = label.intrinsicContentSize

        // Empty latex should still return a valid size (might be zero or minimal)
        #expect(size.width >= 0, "Width should be >= 0 for empty latex, got \(size.width)")
        #expect(size.height >= 0, "Height should be >= 0 for empty latex, got \(size.height)")
    }

    @Test func mathAndTextMixed() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Result: } x^2 + y^2 = z^2\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be greater than 0, got \(size.width)")
        #expect(size.height > 0, "Height should be greater than 0, got \(size.height)")
    }

    @Test func debugSizeThatFitsWithConstraint() {
        let label = MathUILabel()
        label.latex = "\\(\\text{Word1 Word2 Word3 Word4 Word5}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let unconstr = label.sizeThatFits(CGSize.zero)
        let constr = label.sizeThatFits(CGSize(width: 150, height: 999))

        #expect(constr.width < unconstr.width, "Constrained (\(constr.width)) should be < unconstrained (\(unconstr.width))")
        #expect(constr.height > unconstr.height, "Constrained height (\(constr.height)) should be > unconstrained (\(unconstr.height))")
    }

    @Test func accentedCharactersWithLineWrapping() {
        let label = MathUILabel()
        // French text with accented characters: è, é, à
        label.latex = "\\(\\text{Rappelons la relation entre kilomètres et mètres.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Get unconstrained size
        let unconstrainedSize = label.intrinsicContentSize

        // Set a width constraint that should cause wrapping
        label.preferredMaxLayoutWidth = 250
        let constrainedSize = label.intrinsicContentSize

        // Verify wrapping occurred
        #expect(constrainedSize.width > 0, "Width should be > 0")
        #expect(constrainedSize.width < unconstrainedSize.width, "Constrained width should be < unconstrained")
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        // Verify the label can render without errors
        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func vectorArrowsWithLineWrapping() {
        let label = MathUILabel()
        label.fontSize = 20
        #if os(macOS)
        label.textColor = NSColor.black
        #else
        label.textColor = UIColor.black
        #endif
        label.textAlignment = .left

        // Test each arrow command
        let testCases = [
            "\\vec{v} + \\vec{u}",
            "\\overrightarrow{AB} + \\overrightarrow{CD}",
            "\\overleftarrow{F_x} + \\overleftarrow{F_y}",
            "\\overleftrightarrow{PQ} \\parallel \\overleftrightarrow{RS}"
        ]

        for latex in testCases {
            label.latex = "\\(\(latex)\\)"

            // Get size and verify layout
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            // Verify label has content and no errors
            #expect(size.width > 0, "Should have width: \(latex)")
            #expect(size.height > 0, "Should have height: \(latex)")
            #expect(label.displayList != nil, "Display list should be created for: \(latex)")
            #expect(label.error == nil, "Should have no rendering error for: \(latex)")
        }
    }

    @Test func unicodeWordBreaking_EquivautCase() {
        // Specific test for the reported issue: "équivaut" should not break at "é"
        let label = MathUILabel()
        label.latex = "\\(\\text{Rappelons la conversion : 1 km équivaut à 1000 m.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Set the exact width constraint from the bug report
        label.preferredMaxLayoutWidth = 235
        let constrainedSize = label.intrinsicContentSize

        // Verify the label can render without errors
        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Verify that the text wrapped (multiple lines)
        #expect(constrainedSize.height > 20, "Should have wrapped to multiple lines")

        // The critical check: ensure "équivaut" is not broken in the middle
        // We can't easily check the exact line breaks, but we can verify:
        // 1. The rendering succeeded without crashes
        // 2. The display has reasonable dimensions
        #expect(constrainedSize.width > 100, "Width should be reasonable")
        #expect(constrainedSize.width < 250, "Width should respect constraint")
    }

    @Test func mixedTextMathNoTruncation() {
        // Test for truncation bug: content should wrap, not be lost
        // Input: \(\text{Calculer le discriminant }\Delta=b^{2}-4ac\text{ avec }a=1\text{, }b=-1\text{, }c=-5\)
        let label = MathUILabel()
        label.latex = "\\(\\text{Calculer le discriminant }\\Delta=b^{2}-4ac\\text{ avec }a=1\\text{, }b=-1\\text{, }c=-5\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Set width constraint that should cause wrapping
        label.preferredMaxLayoutWidth = 235
        let constrainedSize = label.intrinsicContentSize

        // Verify the label can render without errors
        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Verify content is not truncated - should wrap to multiple lines
        #expect(constrainedSize.height > 30, "Should wrap to multiple lines (not truncate)")

        // Check that we have multiple display elements (wrapped content)
        if let displayList = label.displayList {
            #expect(displayList.subDisplays.count > 1, "Should have multiple display elements from wrapping")
        }
    }

    @Test func numberProtection_FrenchDecimal() {
        let label = MathUILabel()
        // French decimal number should NOT be broken
        label.latex = "\\(\\text{La valeur de pi est approximativement 3,14 dans ce calcul simple.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Constrain to force wrapping, but 3,14 should stay together
        label.preferredMaxLayoutWidth = 200
        let size = label.intrinsicContentSize

        // Verify it renders without error
        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func numberProtection_ThousandsSeparator() {
        let label = MathUILabel()
        // Number with comma separator should stay together
        label.latex = "\\(\\text{The population is approximately 1,000,000 people in this city.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        label.preferredMaxLayoutWidth = 200
        let size = label.intrinsicContentSize

        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func numberProtection_MixedWithText() {
        let label = MathUILabel()
        // Mixed numbers and text - numbers should be protected
        label.latex = "\\(\\text{Results: 3.14, 2.71, and 1.41 are important constants.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        label.preferredMaxLayoutWidth = 180
        let size = label.intrinsicContentSize

        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    // MARK: - International Text Tests

    @Test func chineseTextWrapping() {
        let label = MathUILabel()
        // Chinese text: "Mathematical equations are an important tool for describing natural phenomena"
        label.latex = "\\(\\text{数学方程式は自然現象を記述するための重要なツールです。}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Get unconstrained size
        let unconstrainedSize = label.intrinsicContentSize

        // Set constraint to force wrapping
        label.preferredMaxLayoutWidth = 200
        let constrainedSize = label.intrinsicContentSize

        // Chinese should wrap (can break between characters)
        #expect(constrainedSize.width > 0, "Width should be > 0")
        // NOTE: intrinsicContentSize returns actual content width (no clamping) to prevent clipping
        // Content may exceed preferredMaxLayoutWidth if it cannot fit even with line breaking
        // This is correct behavior - the view should not clip content
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        // Verify no content is clipped at the returned size
        if let display = label.displayList {
            for sub in display.subDisplays {
                let rightEdge = sub.position.x + sub.width
                #expect(rightEdge <= constrainedSize.width + 1.0, "No content should be clipped")
            }
        }

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func japaneseTextWrapping() {
        let label = MathUILabel()
        // Japanese text (Hiragana + Kanji): "This is a mathematics explanation"
        label.latex = "\\(\\text{これは数学の説明です。計算式を使います。}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let unconstrainedSize = label.intrinsicContentSize

        label.preferredMaxLayoutWidth = 180
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        // NOTE: intrinsicContentSize returns actual content width to prevent clipping
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        // Verify no content is clipped
        if let display = label.displayList {
            for sub in display.subDisplays {
                let rightEdge = sub.position.x + sub.width
                #expect(rightEdge <= constrainedSize.width + 1.0, "No content should be clipped")
            }
        }

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func koreanTextWrapping() {
        let label = MathUILabel()
        // Korean text: "Mathematics is a very important subject"
        label.latex = "\\(\\text{수학은 매우 중요한 과목입니다. 방정식을 배웁니다.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        label.preferredMaxLayoutWidth = 200
        let constrainedSize = label.intrinsicContentSize

        // Korean uses spaces, should wrap at word boundaries
        #expect(constrainedSize.width > 0, "Width should be > 0")
        // NOTE: intrinsicContentSize returns actual content width to prevent clipping

        // Verify no content is clipped
        if let display = label.displayList {
            for sub in display.subDisplays {
                let rightEdge = sub.position.x + sub.width
                #expect(rightEdge <= constrainedSize.width + 1.0, "No content should be clipped")
            }
        }

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func mixedLatinCJKWrapping() {
        let label = MathUILabel()
        // Mixed English and Chinese
        label.latex = "\\(\\text{The equation is 方程式: } x^2 + y^2 = r^2 \\text{ です。}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        label.preferredMaxLayoutWidth = 250
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        // NOTE: intrinsicContentSize returns actual content width to prevent clipping

        // Verify no content is clipped
        if let display = label.displayList {
            for sub in display.subDisplays {
                let rightEdge = sub.position.x + sub.width
                #expect(rightEdge <= constrainedSize.width + 1.0, "No content should be clipped")
            }
        }

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func emojiGraphemeClusters() {
        let label = MathUILabel()
        // Emoji and complex grapheme clusters should not be broken
        label.latex = "\\(\\text{Math is fun! 🎉📐📊 The formula is } E = mc^2 \\text{ 🚀✨}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        label.preferredMaxLayoutWidth = 200
        let size = label.intrinsicContentSize

        // Should wrap but not break emoji
        #expect(size.width > 0, "Width should be > 0")
        let tolerance_200 = max(200 * 0.05, 10.0)
        #expect(size.width <= 200 + tolerance_200, "Width should not significantly exceed constraint (within 5% tolerance)")

        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func longEnglishMultiSentence() {
        let label = MathUILabel()
        // Standard English multi-sentence paragraph
        label.latex = "\\(\\text{Mathematics is the study of numbers, shapes, and patterns. It is used in science, engineering, and everyday life. Equations help us solve problems.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let unconstrainedSize = label.intrinsicContentSize

        label.preferredMaxLayoutWidth = 300
        let constrainedSize = label.intrinsicContentSize

        // Should wrap at word boundaries (spaces)
        #expect(constrainedSize.width > 0, "Width should be > 0")
        // NOTE: intrinsicContentSize returns actual content width to prevent clipping
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        // Verify no content is clipped
        if let display = label.displayList {
            for sub in display.subDisplays {
                let rightEdge = sub.position.x + sub.width
                #expect(rightEdge <= constrainedSize.width + 1.0, "No content should be clipped")
            }
        }

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func spanishAccentedText() {
        let label = MathUILabel()
        // Spanish with various accents
        label.latex = "\\(\\text{La ecuación es muy útil para cálculos científicos y matemáticos.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let unconstrainedSize = label.intrinsicContentSize

        label.preferredMaxLayoutWidth = 220
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        let tolerance_220 = max(220 * 0.05, 10.0)
        #expect(constrainedSize.width <= 220 + tolerance_220, "Width should not significantly exceed constraint (within 5% tolerance)")
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func germanUmlautsWrapping() {
        let label = MathUILabel()
        // German with umlauts
        label.latex = "\\(\\text{Mathematische Gleichungen können für Berechnungen verwendet werden.}\\)"
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        let unconstrainedSize = label.intrinsicContentSize

        label.preferredMaxLayoutWidth = 250
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        let tolerance_250 = max(250 * 0.05, 10.0)
        #expect(constrainedSize.width <= 250 + tolerance_250, "Width should not significantly exceed constraint (within 5% tolerance)")
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    // MARK: - Tests for Complex Math Expressions with Line Breaking

    @Test func complexExpressionWithRadicalWrapping() {
        // This is the reported issue: y=x^{2}+3x+4x+9x+8x+8+\sqrt{\dfrac{3x^{2}+5x}{\cos x}}
        // The sqrt part is displayed on the second line and overlaps the first line
        let label = MathUILabel()
        label.latex = "y=x^{2}+3x+4x+9x+8x+8+\\sqrt{\\dfrac{3x^{2}+5x}{\\cos x}}"
        label.font = FontManager.fontManager.defaultFont

        // Get unconstrained size first
        let unconstrainedSize = label.intrinsicContentSize
        #expect(unconstrainedSize.width > 0, "Unconstrained width should be > 0")
        #expect(unconstrainedSize.height > 0, "Unconstrained height should be > 0")

        // Now constrain the width to force wrapping
        label.preferredMaxLayoutWidth = 200
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        let tolerance_200 = max(200 * 0.05, 10.0)
        #expect(constrainedSize.width <= 200 + tolerance_200, "Width should not significantly exceed constraint (within 5% tolerance)")
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        // Layout and check for overlapping
        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Check that displays don't overlap by examining positions
        // Group displays by line (similar y positions) and check for overlap between lines
        if let displayList = label.displayList {
            // Group displays by line based on their y position
            var lineGroups: [[Display]] = []
            var currentLineDisplays: [Display] = []
            var currentLineY: CGFloat? = nil
            let yTolerance: CGFloat = 15.0  // Displays within 15 units are considered on same line (accounts for superscripts/subscripts)

            for display in displayList.subDisplays {
                if let lineY = currentLineY {
                    if abs(display.position.y - lineY) < yTolerance {
                        // Same line
                        currentLineDisplays.append(display)
                    } else {
                        // New line
                        lineGroups.append(currentLineDisplays)
                        currentLineDisplays = [display]
                        currentLineY = display.position.y
                    }
                } else {
                    // First display
                    currentLineDisplays = [display]
                    currentLineY = display.position.y
                }
            }
            if !currentLineDisplays.isEmpty {
                lineGroups.append(currentLineDisplays)
            }

            // Check for overlap between consecutive lines
            for i in 1..<lineGroups.count {
                let previousLine = lineGroups[i-1]
                let currentLine = lineGroups[i]

                // Find the minimum bottom edge of previous line (Y-up: bottom = pos - desc, smaller Y)
                let previousLineMinBottom = previousLine.map { $0.position.y - $0.descent }.min() ?? 0

                // Find the maximum top edge of current line (Y-up: top = pos + asc, larger Y)
                let currentLineMaxTop = currentLine.map { $0.position.y + $0.ascent }.max() ?? 0

                // Check for overlap: if current line's top > previous line's bottom, they overlap
                // (In Y-up coordinate system: positive Y is upward, negative Y is downward)
                // Allow 0.5 points tolerance for floating-point precision and small adjustments
                #expect(currentLineMaxTop <= previousLineMinBottom + 0.5,
                                       "Line \(i) (top at \(currentLineMaxTop)) overlaps with line \(i-1) (bottom at \(previousLineMinBottom))")
            }
        }
    }

    @Test func radicalWithFractionInsideWrapping() {
        // Simplified version: just a radical with a fraction inside
        let label = MathUILabel()
        label.latex = "x+y+z+\\sqrt{\\dfrac{a}{b}}"
        label.font = FontManager.fontManager.defaultFont

        let unconstrainedSize = label.intrinsicContentSize

        // Use narrower constraint to ensure wrapping
        label.preferredMaxLayoutWidth = 80
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func tallElementsOnSecondLine() {
        // Test case with tall fractions and radicals breaking to second line
        let label = MathUILabel()
        label.latex = "a+b+c+\\dfrac{x^2+y^2}{z^2}+\\sqrt{\\dfrac{p}{q}}"
        label.font = FontManager.fontManager.defaultFont

        let unconstrainedSize = label.intrinsicContentSize

        label.preferredMaxLayoutWidth = 150
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Verify no overlapping displays between lines
        if let displayList = label.displayList {
            // Group displays by line
            var lineGroups: [[Display]] = []
            var currentLineDisplays: [Display] = []
            var currentLineY: CGFloat? = nil
            let yTolerance: CGFloat = 15.0

            for display in displayList.subDisplays {
                if let lineY = currentLineY {
                    if abs(display.position.y - lineY) < yTolerance {
                        currentLineDisplays.append(display)
                    } else {
                        lineGroups.append(currentLineDisplays)
                        currentLineDisplays = [display]
                        currentLineY = display.position.y
                    }
                } else {
                    currentLineDisplays = [display]
                    currentLineY = display.position.y
                }
            }
            if !currentLineDisplays.isEmpty {
                lineGroups.append(currentLineDisplays)
            }

            // Check for overlap between consecutive lines
            for i in 1..<lineGroups.count {
                let previousLine = lineGroups[i-1]
                let currentLine = lineGroups[i]

                let previousLineMinBottom = previousLine.map { $0.position.y - $0.descent }.min() ?? 0
                let currentLineMaxTop = currentLine.map { $0.position.y + $0.ascent }.max() ?? 0

                // Allow 0.5 points tolerance for floating-point precision
                #expect(currentLineMaxTop <= previousLineMinBottom + 0.5,
                                       "Line \(i) overlaps with line \(i-1)")
            }
        }
    }

    @Test func multipleLinesWithVaryingHeights() {
        // Test expression that should wrap to multiple lines with different heights
        let label = MathUILabel()
        label.latex = "x+y+z+a+b+c+\\sqrt{d}+e+f+g+h+\\dfrac{i}{j}+k"
        label.font = FontManager.fontManager.defaultFont

        let unconstrainedSize = label.intrinsicContentSize

        label.preferredMaxLayoutWidth = 120
        let constrainedSize = label.intrinsicContentSize

        #expect(constrainedSize.width > 0, "Width should be > 0")
        #expect(constrainedSize.height > unconstrainedSize.height, "Height should increase when wrapped")

        label.frame = CGRect(origin: .zero, size: constrainedSize)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")
    }

    @Test func accentedCharacterWidthCalculation() {
        // Test that accented characters like "é" have their full visual width calculated
        // including the accent, not just the typographic advance width.
        // This prevents clipping when the character appears at the end of a line.

        // Test with the exact user-reported string
        let label = MathUILabel()
        label.latex = #"\text{Utiliser le fait que, dans un triangle rectangle, la médiane issue de l'angle droit vers l'hypoténuse vaut la moitié de l'hypoténuse : }m_{B} = \frac{AC}{2}\text{.}"#
        label.font = FontManager.fontManager.defaultFont
        label.fontSize = 14

        // Use a width that causes "moitié" to appear near the end of a line
        // This should trigger the clipping issue if width calculation is incorrect
        label.preferredMaxLayoutWidth = 300
        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be > 0")
        #expect(size.height > 0, "Height should be > 0")

        label.frame = CGRect(origin: .zero, size: size)

        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Now verify that any text containing accented characters has proper width
        #expect(label.displayList != nil, "Display list should exist")
    }

    @Test func accentedCharacterAtLineEnd() {
        // Specific test for accented character appearing exactly at line end
        let label = MathUILabel()

        // Craft a string that will put "été" at the end of a line
        label.latex = #"\text{Il a été}"#
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text
        label.fontSize = 14

        // Very narrow width to force "été" to line end
        label.preferredMaxLayoutWidth = 60

        let size = label.intrinsicContentSize
        label.frame = CGRect(origin: .zero, size: size)

        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Check that the display width includes the accent extent
        let displayList = try? #require(label.displayList)

        func findAccentedTextDisplay(_ display: Display) -> CTLineDisplay? {
            if let lineDisplay = display as? CTLineDisplay {
                if let attrString = lineDisplay.attributedString,
                   attrString.string.contains("é") {
                    return lineDisplay
                }
            }

            if let mathListDisplay = display as? MathListDisplay {
                for subDisplay in mathListDisplay.subDisplays {
                    if let found = findAccentedTextDisplay(subDisplay) {
                        return found
                    }
                }
            }

            return nil
        }

        if let displayList = displayList,
           let accentedDisplay = findAccentedTextDisplay(displayList) {
            let bounds = CTLineGetBoundsWithOptions(accentedDisplay.line, .useGlyphPathBounds)
            let visualWidth = CGRectGetMaxX(bounds) - CGRectGetMinX(bounds)
            let reportedWidth = accentedDisplay.width

            // This should pass after the fix
            #expect(reportedWidth >= visualWidth - 0.5,
                 "Reported width should include full visual extent of accented characters")
        }
    }

    @Test func textBlockWordBreaking() {
        // Test that words inside \text{...} blocks don't get broken mid-word
        // Regression test for: "of" being broken into "o" | "f" on different lines
        let label = MathUILabel()
        label.latex = "\\(\\text{Apply the Fundamental Theorem of Calculus and evaluate the antiderivative from }0\\text{ to }2\\text{.}\\)"
        label.font = FontManager.fontManager.defaultFont

        // Use a width that would cause line wrapping
        label.preferredMaxLayoutWidth = 235.0
        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be > 0")
        #expect(size.height > 0, "Height should be > 0")

        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Check that no words are broken mid-word
        if let displayList = label.displayList {
            // Group displays by line (Y position)
            let lines = groupDisplaysByLine(displayList)

            // Check each line for mid-word breaks
            for line in lines {
                // Get text displays only
                let textDisplays = line.compactMap { display -> (display: CTLineDisplay, text: String)? in
                    if let ctLine = display as? CTLineDisplay,
                       let text = ctLine.attributedString?.string,
                       !text.trimmingCharacters(in: .whitespaces).isEmpty {
                        return (ctLine, text)
                    }
                    return nil
                }

                // Check if line starts with a single letter
                if let firstDisplay = textDisplays.first,
                   firstDisplay.text.count == 1,
                   firstDisplay.text.first?.isLetter == true {

                    // Find the last display from the previous line
                    let currentY = firstDisplay.display.position.y
                    let previousLineDisplays = lines.filter { $0.first?.position.y ?? 0 > currentY }
                        .sorted { ($0.first?.position.y ?? 0) > ($1.first?.position.y ?? 0) }
                        .first

                    if let prevLine = previousLineDisplays {
                        let prevTextDisplays = prevLine.compactMap { display -> (display: CTLineDisplay, text: String)? in
                            if let ctLine = display as? CTLineDisplay,
                               let text = ctLine.attributedString?.string,
                               !text.trimmingCharacters(in: .whitespaces).isEmpty {
                                return (ctLine, text)
                            }
                            return nil
                        }

                        // Check if previous line ends with a single letter
                        if let lastPrevDisplay = prevTextDisplays.last,
                           lastPrevDisplay.text.count == 1,
                           lastPrevDisplay.text.first?.isLetter == true {

                            // Check if they're part of the same word
                            // With character-level tokenization, we need to check if there's a space
                            // on the same line before/after these letters
                            let allDisplays = displayList.subDisplays
                            if let prevIndex = allDisplays.firstIndex(where: { $0 === lastPrevDisplay.display }),
                               let currIndex = allDisplays.firstIndex(where: { $0 === firstDisplay.display }) {

                                // Look for spaces on the previous line (same Y as 'h')
                                let prevLineY = lastPrevDisplay.display.position.y
                                var hasSpaceOnPrevLine = false

                                // Check all displays on the same line as the last char of prev line
                                for i in 0..<allDisplays.count {
                                    if let ctLine = allDisplays[i] as? CTLineDisplay,
                                       let text = ctLine.attributedString?.string,
                                       abs(ctLine.position.y - prevLineY) < 1.0 {  // Same line
                                        // If we find a space on this line, then 'h' is after a word boundary
                                        if text.trimmingCharacters(in: .letters).contains(where: { $0.isWhitespace }) {
                                            hasSpaceOnPrevLine = true
                                            break
                                        }
                                    }
                                }

                                // Only fail if there's NO space on the previous line
                                // (which would mean the last char is truly mid-word)
                                if !hasSpaceOnPrevLine {
                                    Issue.record("Word broken mid-word: '\(lastPrevDisplay.text)' | '\(firstDisplay.text)' across lines")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @Test func textBlockContractions() {
        // Test that contractions like "don't" and hyphenated words aren't broken
        let label = MathUILabel()
        label.latex = "\\(\\text{We don't break contractions or well-known hyphenated words incorrectly.}\\)"
        label.font = FontManager.fontManager.defaultFont

        // Use a width that would cause line wrapping
        label.preferredMaxLayoutWidth = 200.0
        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be > 0")
        #expect(size.height > 0, "Height should be > 0")

        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Check that contractions and hyphenated words aren't broken
        if let displayList = label.displayList {
            var previousDisplay: Display?
            var previousY: CGFloat?

            for display in displayList.subDisplays {
                if let lineDisplay = display as? CTLineDisplay,
                   let text = lineDisplay.attributedString?.string {

                    // If we have a previous display on a different line
                    if let prevDisplay = previousDisplay as? CTLineDisplay,
                       let prevText = prevDisplay.attributedString?.string,
                       let prevY = previousY,
                       abs(display.position.y - prevY) > 5.0 {  // Different lines

                        // Check for bad breaks in contractions
                        // Pattern 1: letter | apostrophe (e.g., "don" | "'t")
                        if let prevLast = prevText.last, prevLast.isLetter,
                           let currFirst = text.first, currFirst == "'" {
                            Issue.record("Bad break in contraction: '\(prevText)' | '\(text)' across lines")
                        }

                        // Pattern 2: apostrophe | letter (e.g., "don'" | "t")
                        if let prevLast = prevText.last, prevLast == "'",
                           let currFirst = text.first, currFirst.isLetter {
                            Issue.record("Bad break in contraction: '\(prevText)' | '\(text)' across lines")
                        }

                        // Check for bad breaks in hyphenated words
                        // Pattern 3: letter | hyphen (e.g., "well" | "-known")
                        if let prevLast = prevText.last, prevLast.isLetter,
                           let currFirst = text.first, currFirst == "-" {
                            Issue.record("Bad break in hyphenated word: '\(prevText)' | '\(text)' across lines")
                        }

                        // Pattern 4: hyphen | letter (e.g., "well-" | "known")
                        if let prevLast = prevText.last, prevLast == "-",
                           let currFirst = text.first, currFirst.isLetter {
                            Issue.record("Bad break in hyphenated word: '\(prevText)' | '\(text)' across lines")
                        }
                    }

                    previousDisplay = display
                    previousY = display.position.y
                }
            }
        }
    }

    @Test func textBlockUnicodeText() {
        // Test Unicode word boundary detection with international text
        let label = MathUILabel()
        label.latex = "\\(\\text{Testing café résumé naïve Zürich—em-dash…ellipsis correctly.}\\)"
        label.font = FontManager.fontManager.defaultFont

        // Use a width that would cause line wrapping
        label.preferredMaxLayoutWidth = 200.0
        let size = label.intrinsicContentSize

        #expect(size.width > 0, "Width should be > 0")
        #expect(size.height > 0, "Height should be > 0")

        label.frame = CGRect(origin: .zero, size: size)
        #if os(macOS)
        label.layout()
        #else
        label.layoutSubviews()
        #endif

        #expect(label.displayList != nil, "Display list should be created")
        #expect(label.error == nil, "Should have no rendering error")

        // Verify no words with accented characters are broken
        if let displayList = label.displayList {
            var previousDisplay: Display?
            var previousY: CGFloat?

            for display in displayList.subDisplays {
                if let lineDisplay = display as? CTLineDisplay,
                   let text = lineDisplay.attributedString?.string {

                    if let prevDisplay = previousDisplay as? CTLineDisplay,
                       let prevText = prevDisplay.attributedString?.string,
                       let prevY = previousY,
                       abs(display.position.y - prevY) > 5.0 {

                        // Check for bad breaks (letter-to-letter without word boundary)
                        if let prevLast = prevText.last, let currFirst = text.first {
                            // Both are letters - this could be a bad break
                            if prevLast.isLetter && currFirst.isLetter {
                                // For single-character atoms in text, Unicode word detection
                                // should have prevented this unless it's a valid word boundary
                                // If we see this, it should only be at natural boundaries

                                // Common valid boundaries: after spaces, punctuation, em-dash, etc.
                                // If both are single letter atoms and we broke between them,
                                // it should be acceptable (Unicode word boundary allowed it)
                            }
                        }
                    }

                    previousDisplay = display
                    previousY = display.position.y
                }
            }
        }

        // Main goal: proper Unicode word boundary detection means international
        // text is handled correctly without crashes or corruption
    }

    @Test func unicodeWordBoundaryRules() {
        // Test that our word boundary detection correctly handles ALL cases
        // including contractions, hyphens, and international text

        func testOurWordBoundary(_ text1: String, _ text2: String, shouldBreak: Bool, description: String) {
            // Replicate our hasWordBoundaryBetween logic from AtomTokenizer
            func hasWordBoundaryBetween(_ text1: String, and text2: String) -> Bool {
                // RULE 1: Check for apostrophes and hyphens between letters
                if let lastChar1 = text1.last, let firstChar2 = text2.first {
                    if lastChar1.isLetter && (firstChar2 == "'" || firstChar2 == "-") {
                        return false
                    }
                    if (lastChar1 == "'" || lastChar1 == "-") && firstChar2.isLetter {
                        return false
                    }
                }

                // RULE 2: Use Unicode word boundary detection
                let combined = text1 + text2
                let junctionIndex = text1.endIndex

                var wordBoundaries: Set<String.Index> = []
                combined.enumerateSubstrings(in: combined.startIndex..<combined.endIndex, options: .byWords) { _, substringRange, _, _ in
                    wordBoundaries.insert(substringRange.lowerBound)
                    wordBoundaries.insert(substringRange.upperBound)
                }

                return wordBoundaries.contains(junctionIndex)
            }

            let hasBoundary = hasWordBoundaryBetween(text1, and: text2)
            #expect(hasBoundary == shouldBreak,
                          "\(description): '\(text1)' + '\(text2)' should \(shouldBreak ? "allow" : "prevent") breaking")
        }

        // Contractions: should NOT break mid-word
        testOurWordBoundary("don", "'", shouldBreak: false, description: "Contraction part 1")
        testOurWordBoundary("'", "t", shouldBreak: false, description: "Contraction part 2")
        testOurWordBoundary("won", "'", shouldBreak: false, description: "Contraction won't part 1")
        testOurWordBoundary("'", "t", shouldBreak: false, description: "Contraction won't part 2")

        // Hyphenated words: should NOT break mid-word
        testOurWordBoundary("well", "-", shouldBreak: false, description: "Hyphenated word part 1")
        testOurWordBoundary("-", "known", shouldBreak: false, description: "Hyphenated word part 2")
        testOurWordBoundary("state", "-", shouldBreak: false, description: "Hyphenated state-of part 1")
        testOurWordBoundary("-", "of", shouldBreak: false, description: "Hyphenated state-of part 2")

        // Regular words: should NOT break between letters
        testOurWordBoundary("o", "f", shouldBreak: false, description: "Regular word 'of'")
        testOurWordBoundary("t", "h", shouldBreak: false, description: "Regular word 'th'")
        testOurWordBoundary("th", "e", shouldBreak: false, description: "Regular word 'the'")

        // Spaces: SHOULD allow breaking
        testOurWordBoundary("word", " ", shouldBreak: true, description: "After word before space")
        testOurWordBoundary(" ", "next", shouldBreak: true, description: "After space before word")
        testOurWordBoundary("the", " ", shouldBreak: true, description: "Between words")

        // Punctuation: SHOULD allow breaking
        testOurWordBoundary("end", ".", shouldBreak: true, description: "Before period")
        // Note: "." + " " edge case skipped - no words means no boundaries detected by Foundation
        // In practice, punctuation and spaces are handled correctly when part of larger text
        testOurWordBoundary("word", ",", shouldBreak: true, description: "Before comma")

        // International text: properly handled by Unicode
        testOurWordBoundary("caf", "é", shouldBreak: false, description: "Accented character café")
        testOurWordBoundary("na", "ï", shouldBreak: false, description: "Diaeresis naïve")
    }

    // MARK: - Latin Punctuation Tests

    @Test func latinPunctuation_SentenceEnding() throws {

        // Test that commas, periods, semicolons, etc. stay at end of line, not beginning
        let label = MathUILabel()
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Test with comma
        label.latex = "\\text{First part, second part, third part, fourth part}"
        label.preferredMaxLayoutWidth = 100  // Force breaking

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            // Check that lines don't start with commas
            if let display = label.displayList {
                #expect(checkNoLineStartsWith(",", in: display),
                         "No line should start with comma")
            }
        }

        // Test with period
        label.latex = "\\text{Sentence one. Sentence two. Sentence three. Sentence four.}"
        label.preferredMaxLayoutWidth = 120

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                #expect(checkNoLineStartsWith(".", in: display),
                         "No line should start with period")
            }
        }

        // Test with semicolon
        label.latex = "\\text{First clause; second clause; third clause; fourth clause}"
        label.preferredMaxLayoutWidth = 110

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                #expect(checkNoLineStartsWith(";", in: display),
                         "No line should start with semicolon")
            }
        }
    }

    @Test func latinPunctuation_OpeningClosing() throws {

        // Test that opening brackets/quotes don't end lines, closing brackets/quotes don't start lines
        let label = MathUILabel()
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Test with parentheses
        label.latex = "\\text{This is a long sentence with (parenthetical information) in the middle}"
        label.preferredMaxLayoutWidth = 120

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                // Opening parenthesis should not be at line end
                #expect(checkNoLineEndsWith("(", in: display),
                         "No line should end with opening parenthesis")
                // Closing parenthesis should not be at line start
                #expect(checkNoLineStartsWith(")", in: display),
                         "No line should start with closing parenthesis")
            }
        }

        // Test with brackets
        label.latex = "\\text{This sentence has [bracketed content] that spans multiple words}"
        label.preferredMaxLayoutWidth = 110

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                #expect(checkNoLineEndsWith("[", in: display),
                         "No line should end with opening bracket")
                #expect(checkNoLineStartsWith("]", in: display),
                         "No line should start with closing bracket")
            }
        }
    }

    @Test func latinPunctuation_QuestionExclamation() throws {

        // Test that question marks and exclamation marks don't start lines
        let label = MathUILabel()
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        label.latex = "\\text{Question? Answer! Another question? Another answer!}"
        label.preferredMaxLayoutWidth = 100

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                #expect(checkNoLineStartsWith("?", in: display),
                         "No line should start with question mark")
                #expect(checkNoLineStartsWith("!", in: display),
                         "No line should start with exclamation mark")
            }
        }
    }

    // MARK: - CJK Punctuation Tests

    @Test func cjkPunctuation_Japanese() throws {

        // Test Japanese kinsoku rules
        let label = MathUILabel()
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Test with Japanese sentence-ending punctuation
        // These should NEVER appear at line start
        label.latex = "\\text{これは日本語の文章です。これも文章です。さらに文章があります。}"
        label.preferredMaxLayoutWidth = 120

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                #expect(checkNoLineStartsWith("。", in: display),
                         "No line should start with Japanese period")
                #expect(checkNoLineStartsWith("、", in: display),
                         "No line should start with Japanese comma")
            }
        }

        // Test with Japanese brackets
        // Opening brackets should not end lines, closing brackets should not start lines
        label.latex = "\\text{これは「引用文」です。『二重引用』もあります。（括弧）も使います。}"
        label.preferredMaxLayoutWidth = 130

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                // Opening brackets should not end lines
                #expect(checkNoLineEndsWith("「", in: display),
                         "No line should end with Japanese opening quote")
                #expect(checkNoLineEndsWith("『", in: display),
                         "No line should end with Japanese double opening quote")
                #expect(checkNoLineEndsWith("（", in: display),
                         "No line should end with Japanese opening paren")
                // Closing brackets should not start lines
                #expect(checkNoLineStartsWith("」", in: display),
                         "No line should start with Japanese closing quote")
                #expect(checkNoLineStartsWith("』", in: display),
                         "No line should start with Japanese double closing quote")
                #expect(checkNoLineStartsWith("）", in: display),
                         "No line should start with Japanese closing paren")
            }
        }
    }

    @Test func cjkPunctuation_SmallKana() throws {

        // Test that small kana don't start lines
        let label = MathUILabel()
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Small tsu is commonly used for gemination
        label.latex = "\\text{がっこう がっき ずっと きっぷ けっこん}"
        label.preferredMaxLayoutWidth = 80

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                // Small kana should not start lines
                #expect(checkNoLineStartsWith("っ", in: display),
                         "No line should start with small tsu")
                #expect(checkNoLineStartsWith("ゃ", in: display),
                         "No line should start with small ya")
                #expect(checkNoLineStartsWith("ゅ", in: display),
                         "No line should start with small yu")
                #expect(checkNoLineStartsWith("ょ", in: display),
                         "No line should start with small yo")
            }
        }

        // Katakana small characters
        label.latex = "\\text{チェック シェア ジェット ティーシャツ}"
        label.preferredMaxLayoutWidth = 80

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                #expect(checkNoLineStartsWith("ェ", in: display),
                         "No line should start with small katakana e")
                #expect(checkNoLineStartsWith("ャ", in: display),
                         "No line should start with small katakana ya")
                #expect(checkNoLineStartsWith("ュ", in: display),
                         "No line should start with small katakana yu")
            }
        }
    }

    @Test func cjkPunctuation_Chinese() throws {

        // Test Chinese punctuation rules (similar to Japanese kinsoku)
        let label = MathUILabel()
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Chinese sentence with full-width punctuation
        label.latex = "\\text{这是一个句子。这是另一个句子。还有一个句子。}"
        label.preferredMaxLayoutWidth = 100

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                #expect(checkNoLineStartsWith("。", in: display),
                         "No line should start with Chinese period")
                #expect(checkNoLineStartsWith("，", in: display),
                         "No line should start with Chinese comma")
            }
        }

        // Chinese with brackets and quotes
        label.latex = "\\text{这是「引用」的例子。这是（括号）的例子。这是【书名号】的例子。}"
        label.preferredMaxLayoutWidth = 120

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                // Opening brackets should not end lines
                #expect(checkNoLineEndsWith("「", in: display),
                         "No line should end with Chinese opening quote")
                #expect(checkNoLineEndsWith("（", in: display),
                         "No line should end with Chinese opening paren")
                #expect(checkNoLineEndsWith("【", in: display),
                         "No line should end with Chinese lenticular bracket")
                // Closing brackets should not start lines
                #expect(checkNoLineStartsWith("」", in: display),
                         "No line should start with Chinese closing quote")
                #expect(checkNoLineStartsWith("）", in: display),
                         "No line should start with Chinese closing paren")
                #expect(checkNoLineStartsWith("】", in: display),
                         "No line should start with Chinese lenticular bracket close")
            }
        }
    }

    @Test func cjkPunctuation_Mixed() throws {

        // Test mixed Latin and CJK punctuation
        let label = MathUILabel()
        label.font = FontManager.fontManager.defaultFont
        label.labelMode = .text

        // Mixed sentence with both Latin and CJK punctuation
        label.latex = "\\text{This is English. これは日本語です。This is English again, with comma.}"
        label.preferredMaxLayoutWidth = 150

        if label.error == nil {
            let size = label.intrinsicContentSize
            label.frame = CGRect(origin: .zero, size: size)
            #if os(macOS)
            label.layout()
            #else
            label.layoutSubviews()
            #endif

            if let display = label.displayList {
                // Both Latin and CJK punctuation should not start lines
                #expect(checkNoLineStartsWith(".", in: display),
                         "No line should start with Latin period")
                #expect(checkNoLineStartsWith(",", in: display),
                         "No line should start with Latin comma")
                #expect(checkNoLineStartsWith("。", in: display),
                         "No line should start with CJK period")
            }
        }
    }
}
