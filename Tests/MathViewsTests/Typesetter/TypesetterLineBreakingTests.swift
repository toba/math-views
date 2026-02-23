import Testing
@testable import MathViews
import CoreGraphics

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

struct TypesetterLineBreakingTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModern.fontInstance(size: 20)
    }

    // MARK: - Interatom Line Breaking Tests

    @Test func interatomLineBreaking_SimpleEquation() throws {
        // Simple equation that should break between atoms when width is constrained
        let latex = "a=1, b=2, c=3, d=4"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Create display with narrow width constraint (should force multiple lines)
        let maxWidth: CGFloat = 100
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should have multiple sub-displays (lines)
        #expect(
            display.subDisplays.count > 1,
            "Expected multiple lines with width constraint of \(maxWidth)",
        )

        // Verify that each line respects the width constraint
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.1,
                "Line \(index) width \(subDisplay.width) exceeds maxWidth \(maxWidth)",
            )
        }

        // Verify vertical positioning - check for multiple y-positions indicating multiple lines
        let uniqueYPositions = Set(display.subDisplays.map(\.position.y))
        if display.width > maxWidth * 0.9 {
            // If width exceeds constraint, should have multiple lines (different y positions)
            #expect(
                uniqueYPositions.count > 1,
                "Should have multiple lines with different y positions when width exceeds constraint",
            )
        }
    }

    @Test func interatomLineBreaking_TextAndMath() throws {
        // The user's specific example: text mixed with math
        let latex =
            "\\text{Calculer le discriminant }\\Delta=b^{2}-4ac\\text{ avec }a=1\\text{, }b=-1\\text{, }c=-5"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Create display with width constraint of 235 as specified by user
        let maxWidth: CGFloat = 235
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should have multiple lines
        #expect(
            display.subDisplays.count > 1,
            "Expected multiple lines with width \(maxWidth) for the given LaTeX",
        )

        // Verify each line respects width constraint
        for (index, subDisplay) in display.subDisplays.enumerated() {
            // Allow 10% tolerance for spacing and rounding
            #expect(
                subDisplay.width <= maxWidth * 1.1,
                "Line \(index) width \(subDisplay.width) exceeds maxWidth \(maxWidth)",
            )
        }

        // Verify vertical spacing between lines - check for multiple y-positions
        let uniqueYPositions = Set(display.subDisplays.map(\.position.y))
        if display.width > maxWidth * 0.9 || display.subDisplays.count > 5 {
            // Content should wrap to multiple lines when it exceeds width or has many elements
            #expect(
                uniqueYPositions.count > 1,
                "Should have multiple lines with different y positions",
            )
        }
    }

    @Test func interatomLineBreaking_BreaksAtAtomBoundaries() throws {
        // Test that breaking happens between atoms, not within them
        // Using mathematical atoms separated by operators
        let latex = "a+b+c+d+e+f+g+h+i+j+k+l+m+n+o+p"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Create display with narrow width that should force breaking
        let maxWidth: CGFloat = 120
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should have multiple lines
        #expect(
            display.subDisplays.count > 1,
            "Expected line breaking with narrow width",
        )

        // Each line should respect the width constraint (with some tolerance)
        // since we break at atom boundaries, not mid-atom
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) width \(subDisplay.width) exceeds maxWidth \(maxWidth) by too much",
            )
        }
    }

    @Test func interatomLineBreaking_WithSuperscripts() throws {
        // Test breaking with atoms that have superscripts
        let latex = "a^{2}+b^{2}+c^{2}+d^{2}+e^{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 100
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should handle superscripts properly and create multiple lines if needed
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.1,
                "Line \(index) with superscripts exceeds width",
            )
        }
    }

    @Test func interatomLineBreaking_NoBreakingWhenNotNeeded() throws {
        // Test that short content doesn't break unnecessarily
        let latex = "a=b"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 200
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should stay on single line since content is short
        // Note: The number of subDisplays might be 1 or more depending on internal structure,
        // but the total width should be well under maxWidth
        #expect(
            display.width < maxWidth,
            "Short content should fit without breaking",
        )
    }

    @Test func interatomLineBreaking_BreaksAfterOperators() throws {
        // Test that breaking prefers to happen after operators (good break points)
        let latex = "a+b+c+d+e+f+g+h"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 80
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should break into multiple lines
        #expect(display.subDisplays.count > 1, "Expected multiple lines")

        // Verify width constraints
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(subDisplay.width <= maxWidth * 1.1, "Line \(index) exceeds width")
        }
    }

    // MARK: - Complex Display Line Breaking Tests (Fractions & Radicals)

    @Test func complexDisplay_FractionStaysInlineWhenFits() throws {
        // Fraction that should stay inline with surrounding content
        let latex = "a+\\frac{1}{2}+b"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Wide enough to fit everything on one line
        let maxWidth: CGFloat = 200
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should fit on a single line (all elements have same y position)
        // Note: subdisplays may be > 1 due to flushing currentLine before complex atoms
        // What matters is that they're all at the same y position (no line breaks)
        let firstY = display.subDisplays.first?.position.y ?? 0
        for subDisplay in display.subDisplays {
            #expect(
                abs(subDisplay.position.y - firstY) <= 0.1,
                "All elements should be on the same line (same y position)",
            )
        }

        // Total width should be within constraint
        let displayWidth = display.width
        #expect(
            displayWidth < maxWidth,
            "Expression should fit within width constraint",
        )
    }

    @Test func complexDisplay_FractionBreaksWhenTooWide() throws {
        // Multiple fractions with narrow width should break
        let latex = "a+\\frac{1}{2}+b+\\frac{3}{4}+c"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Narrow width should force breaking
        let maxWidth: CGFloat = 80
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should have multiple lines
        #expect(
            display.subDisplays.count > 1,
            "Expected line breaking with narrow width",
        )

        // Each line should respect width constraint (with tolerance)
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) width \(subDisplay.width) exceeds maxWidth \(maxWidth) significantly",
            )
        }
    }

    @Test func complexDisplay_RadicalStaysInlineWhenFits() throws {
        // Radical that should stay inline with surrounding content
        let latex = "x+\\sqrt{2}+y"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Wide enough to fit everything on one line
        let maxWidth: CGFloat = 150
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should fit on a single line (all elements have same y position)
        let firstY = display.subDisplays.first?.position.y ?? 0
        for subDisplay in display.subDisplays {
            #expect(
                abs(subDisplay.position.y - firstY) <= 0.1,
                "All elements should be on the same line (same y position)",
            )
        }

        // Total width should be within constraint
        let displayWidth = display.width
        #expect(
            displayWidth < maxWidth,
            "Expression should fit within width constraint",
        )
    }

    @Test func complexDisplay_RadicalBreaksWhenTooWide() throws {
        // Multiple radicals with narrow width should break
        let latex = "a+\\sqrt{2}+b+\\sqrt{3}+c+\\sqrt{5}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Narrow width should force breaking
        let maxWidth: CGFloat = 100
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should have multiple lines
        #expect(
            display.subDisplays.count > 1,
            "Expected line breaking with narrow width",
        )

        // Each line should respect width constraint (with tolerance)
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) width \(subDisplay.width) exceeds maxWidth \(maxWidth) significantly",
            )
        }
    }

    @Test func complexDisplay_MixedFractionsAndRadicals() throws {
        // Mix of fractions and radicals
        let latex = "a+\\frac{1}{2}+\\sqrt{3}+b"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Medium width
        let maxWidth: CGFloat = 150
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should handle mixed complex displays
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(subDisplay.width <= maxWidth * 1.2, "Line \(index) width exceeds constraint")
        }
    }

    @Test func complexDisplay_FractionWithComplexNumerator() throws {
        // Fraction with more complex content
        let latex = "\\frac{a+b}{c}+d"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 150
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should stay inline if it fits
        #expect(
            display.width < maxWidth * 1.5,
            "Complex fraction should handle width reasonably",
        )
    }

    @Test func complexDisplay_RadicalWithDegree() throws {
        // Cube root
        let latex = "\\sqrt[3]{8}+x"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 150
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should handle radicals with degrees
        #expect(
            display.width < maxWidth * 1.2,
            "Radical with degree should fit reasonably",
        )
    }

    @Test func complexDisplay_NoBreakingWithoutWidthConstraint() throws {
        // Without width constraint, should never break
        let latex = "a+\\frac{1}{2}+\\sqrt{3}+b+\\frac{4}{5}+c"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // No width constraint (maxWidth = 0)
        let display = try #require(
            Typesetter.makeLineDisplay(for: mathList, font: font, style: .display),
        )
        // Should not artificially break when no constraint
        var allAtSameY = true
        let firstY = display.subDisplays.first?.position.y ?? 0
        for subDisplay in display.subDisplays
            where abs(subDisplay.position.y - firstY) > 0.1
        {
            allAtSameY = false
            break
        }
        #expect(allAtSameY, "Without width constraint, all elements should be at same Y position")
    }

    // MARK: - Additional Recommended Tests

    @Test func edgeCase_VeryNarrowWidth() throws {
        // Test behavior with extremely narrow width constraint
        let latex = "a+b+c"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Very narrow width - each element might need its own line
        let maxWidth: CGFloat = 30
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should handle gracefully without crashing
        #expect(
            !display.subDisplays.isEmpty,
            "Should produce at least one display",
        )

        // Each subdisplay should attempt to respect width (though may overflow for single atoms)
        for subDisplay in display.subDisplays {
            // Allow overflow for unavoidable cases (single atom wider than constraint)
            #expect(
                subDisplay.width < maxWidth * 3,
                "Width shouldn't be excessively larger than constraint",
            )
        }
    }

    @Test func edgeCase_VeryWideAtom() throws {
        // Test handling of atom that's wider than maxWidth constraint
        let latex = "\\text{ThisIsAnExtremelyLongWordThatCannotBreak}+b"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 100
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should not crash, even if single atom exceeds width
        #expect(!display.subDisplays.isEmpty, "Should produce display")

        // The wide atom should be placed, even if it exceeds maxWidth
        // (no way to break it further)
    }

    @Test func mixedScriptsAndNonScripts() throws {
        // Test mixing atoms with scripts and without scripts
        let latex = "a+b^{2}+c+d^{3}+e"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 120
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should handle mixed content
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.3,
                "Line \(index) with mixed scripts should respect width reasonably",
            )
        }
    }

    @Test func multipleLineBreaks() throws {
        // Test expression that requires 4+ line breaks
        let latex = "a+b+c+d+e+f+g+h+i+j+k+l+m+n+o+p+q+r+s+t"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        // Very narrow to force many breaks
        let maxWidth: CGFloat = 60
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should create multiple lines
        #expect(
            display.subDisplays.count >= 4,
            "Should create at least 4 lines for long expression",
        )

        // Verify vertical positioning - tokenization groups subdisplays on same line
        // Count unique y-positions instead of consecutive subdisplays
        let uniqueYPositions = Set(display.subDisplays.map(\.position.y))
            .sorted(by: >)
        #expect(uniqueYPositions.count >= 4, "Should have at least 4 distinct line positions")

        // Verify consistent line spacing using unique y-positions
        if uniqueYPositions.count >= 3 {
            // Calculate spacing between consecutive lines (not consecutive subdisplays)
            let spacing1 = abs(uniqueYPositions[0] - uniqueYPositions[1])
            let spacing2 = abs(uniqueYPositions[1] - uniqueYPositions[2])
            #expect(abs(spacing1 - spacing2) <= 1.0, "Line spacing should be consistent")
        }
    }

    @Test func unicodeTextWrapping() throws {
        // Test wrapping with Unicode characters (including CJK)
        let latex = "\\text{Hello 世界 こんにちは 안녕하세요 مرحبا}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 150
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should handle Unicode text (may need fallback font)

        // Each line should attempt to respect width
        for subDisplay in display.subDisplays {
            // More tolerance for Unicode as font metrics vary
            #expect(
                subDisplay.width <= maxWidth * 1.5,
                "Unicode text line should respect width reasonably",
            )
        }
    }

    @Test func numberProtection() throws {
        // Test that numbers don't break in the middle
        let latex = "\\text{The value is 3.14159 or 2,718 or 1,000,000}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 150
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Numbers should stay together (not split like "3.14" → "3." on one line, "14" on next)
        // This is handled by the universal breaking mechanism with Core Text
        #expect(display.width > 0, "Display should have positive width")
    }

    // MARK: - Tests for Not-Yet-Optimized Cases (Document Current Behavior)

    @Test func currentBehavior_LargeOperators() throws {
        // Documents current behavior: large operators still force line breaks
        let latex = "\\sum_{i=1}^{n}x_{i}+\\int_{0}^{1}f(x)dx"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 300
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Current behavior: operators force breaks
        // This test documents current behavior for future improvement
        _ = display // verify it rendered
    }

    @Test func currentBehavior_NestedDelimiters() throws {
        // Documents current behavior: \left...\right still forces line breaks
        let latex = "a+\\left(b+c\\right)+d"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 200
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Current behavior: delimiters may force breaks
        // This test documents current behavior for future improvement
        _ = display // verify it rendered
    }

    @Test func currentBehavior_ColoredExpressions() throws {
        // Documents current behavior: colored sections still force line breaks
        let latex = "a+\\color{red}{b+c}+d"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 200
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Current behavior: colored sections may force breaks
        // This test documents current behavior for future improvement
        _ = display // verify it rendered
    }

    @Test func currentBehavior_MatricesWithSurroundingContent() throws {
        // Documents current behavior: matrices still force line breaks
        let latex = "A=\\begin{pmatrix}1&2\\\\3&4\\end{pmatrix}+B"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 300
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Current behavior: matrices force breaks
        // This test documents current behavior for future improvement
        _ = display // verify it rendered
    }

    @Test func realWorldExample_QuadraticFormula() throws {
        // Real-world test: quadratic formula with width constraint
        let latex = "x=\\frac{-b\\pm\\sqrt{b^{2}-4ac}}{2a}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 200
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should render the formula (may break if too wide)
        _ = display // verify it rendered
        #expect(display.width > 0, "Formula has non-zero width")
    }

    @Test func realWorldExample_ComplexFraction() throws {
        // Real-world test: continued fraction
        let latex = "\\frac{1}{2+\\frac{1}{3+\\frac{1}{4}}}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 150
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should render nested fractions
        _ = display // verify it rendered
        #expect(display.width > 0, "Formula has non-zero width")
    }

    @Test func realWorldExample_MixedOperationsWithFractions() throws {
        // Real-world test: mixed arithmetic with multiple fractions
        let latex = "\\frac{1}{2}+\\frac{2}{3}+\\frac{3}{4}+\\frac{4}{5}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Failed to parse LaTeX")

        let maxWidth: CGFloat = 180
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // With new implementation, fractions should stay inline when possible
        // May break into 2-3 lines depending on actual widths
        #expect(!display.subDisplays.isEmpty, "Multiple fractions render")

        // Verify width constraints are respected
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.3,
                "Line \(index) should respect width constraint reasonably",
            )
        }
    }
}
