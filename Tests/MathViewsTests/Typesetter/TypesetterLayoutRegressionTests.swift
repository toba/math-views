import Testing
@testable import MathViews
import CoreGraphics

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

struct TypesetterLayoutRegressionTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModern.fontInstance(size: 20)
    }

    // MARK: - Regression Test for Sum Equation Layout Bug

    @Test func sumEquationWithFraction_CorrectOrdering() throws {
        // Test case for: \(\sum_{i=1}^{n} i = \frac{n(n+1)}{2}\)
        // Bug: The = sign was appearing at the end instead of between i and the fraction
        let latex = "\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        // Create display without width constraint first to check ordering
        let display = try #require(Typesetter.makeLineDisplay(for: mathList, font: font, style: .display))
        // Get the subdisplays to check ordering
        let subDisplays = display.subDisplays

        // The expected order should be: sum (with limits), i, =, fraction
        // We need to verify that the x positions are monotonically increasing
        var previousX: CGFloat = -1
        var foundSum = false
        var foundEquals = false
        var foundFraction = false

        for subDisplay in subDisplays {
            // Skip nested containers (MathListDisplay with subdisplays) for ordering check
            // Their internal subdisplays have positions relative to container, not absolute
            let skipOrderingCheck: Bool
            if let mathListDisplay = subDisplay as? MathListDisplay {
                skipOrderingCheck = !mathListDisplay.subDisplays.isEmpty
            } else {
                skipOrderingCheck = false
            }

            // Check x position is increasing (allowing small tolerance for rounding)
            if !skipOrderingCheck, previousX >= 0 {
                #expect(
                    subDisplay.position.x >= previousX - 0.1,
                    "Displays should be ordered left to right, but got x=\(subDisplay.position.x) after x=\(previousX)",
                )
            }
            previousX = subDisplay.position.x + subDisplay.width

            // Identify what type of display this is
            if subDisplay is LargeOpLimitsDisplay {
                foundSum = true
                #expect(!foundEquals, "Sum should come before equals sign")
                #expect(!foundFraction, "Sum should come before fraction")
            } else if let lineDisplay = subDisplay as? CTLineDisplay,
                      let text = lineDisplay.attributedString?.string
            {
                if text.contains("=") {
                    foundEquals = true
                    #expect(foundSum, "Equals should come after sum")
                    #expect(!foundFraction, "Equals should come before fraction")
                }
            } else if subDisplay is FractionDisplay {
                foundFraction = true
                #expect(foundSum, "Fraction should come after sum")
                #expect(foundEquals, "Fraction should come after equals sign")
            }
        }

        #expect(foundSum, "Should contain sum operator")
        #expect(foundEquals, "Should contain equals sign")
        #expect(foundFraction, "Should contain fraction")
    }

    @Test func sumEquationWithFraction_WithWidthConstraint() throws {
        // Test case for: \(\sum_{i=1}^{n} i = \frac{n(n+1)}{2}\) with width constraint
        // This reproduces the issue where = appears at the end instead of in the middle
        let latex = "\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        // Create display with width constraint matching MathView preview (235)
        // Use .text mode and font size 17 to match MathView settings
        let testFont = MathFont.latinModern.fontInstance(size: 17)
        let maxWidth: CGFloat = 235 // Same width as MathView preview
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: testFont, style: .text, maxWidth: maxWidth,
        ))
        // Get the subdisplays to check ordering
        let subDisplays = display.subDisplays

        // Track what we find and their y positions
        var sumX: CGFloat?
        var equalsX: CGFloat?
        var equalsY: CGFloat?
        var fractionX: CGFloat?
        var fractionY: CGFloat?

        for subDisplay in subDisplays {
            if subDisplay is LargeOpLimitsDisplay {
                // Display mode: sum with limits as single display
                sumX = subDisplay.position.x
            } else if subDisplay is GlyphDisplay {
                // Text mode: sum symbol as glyph display (check if it's the sum symbol)
                if sumX == nil {
                    sumX = subDisplay.position.x
                }
            } else if let lineDisplay = subDisplay as? CTLineDisplay,
                      let text = lineDisplay.attributedString?.string
            {
                if text.contains("="), !text.contains("i") {
                    // Just the equals sign (not combined with i)
                    equalsX = subDisplay.position.x
                    equalsY = subDisplay.position.y
                } else if text.contains("i"), text.contains("=") {
                    // i and = together (ideal case)
                    equalsX = subDisplay.position.x // They're together
                    equalsY = subDisplay.position.y
                } else if text.contains("i") {
                    // Just i
                }
            } else if subDisplay is FractionDisplay {
                fractionX = subDisplay.position.x
                fractionY = subDisplay.position.y
            }
        }

        // Verify we found all components
        #expect(sumX != nil, "Should find sum operator (glyph or large op display)")
        #expect(equalsX != nil, "Should find equals sign")
        #expect(fractionX != nil, "Should find fraction")

        // The key test: equals sign should come BETWEEN i and fraction in horizontal position
        // OR if on different lines, equals should not come after fraction
        if let eqX = equalsX, let eqY = equalsY, let fracX = fractionX, let fracY = fractionY {
            if abs(eqY - fracY) < 1.0 {
                // Same line: equals must be to the left of fraction
                #expect(
                    eqX < fracX,
                    "Equals sign (x=\(eqX)) should be to the left of fraction (x=\(fracX)) on same line",
                )
            }

            // Equals should never be to the right of the fraction's right edge
            #expect(
                eqX < fracX + display.width,
                "Equals sign should not appear after the fraction",
            )
        }
    }

    // MARK: - Improved Script Handling Tests

    @Test func scriptedAtoms_StayInlineWhenFit() throws {
        // Test that atoms with superscripts stay inline when they fit
        let latex = "a^{2}+b^{2}+c^{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        // Wide enough to fit everything on one line
        let maxWidth: CGFloat = 200
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: maxWidth,
        ))
        // Check for line breaks (large y position gaps indicate line breaks)
        // Note: Superscripts/subscripts have different y positions but are on same "line"
        // Line breaks use fontSize * 1.5 spacing, so look for gaps > fontSize
        let yPositions = display.subDisplays.map(\.position.y).sorted()
        var lineBreakCount = 0
        for i in 1 ..< yPositions.count {
            let gap = abs(yPositions[i] - yPositions[i - 1])
            if gap > font.fontSize {
                lineBreakCount += 1
            }
        }

        #expect(lineBreakCount == 0, "Should have no line breaks when content fits within width")

        // Total width should be within constraint
        #expect(
            display.width < maxWidth,
            "Expression should fit within width constraint",
        )
    }

    @Test func scriptedAtoms_BreakWhenTooWide() throws {
        // Test that atoms with superscripts break when width is exceeded
        let latex = "a^{2}+b^{2}+c^{2}+d^{2}+e^{2}+f^{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        // Narrow width should force breaking
        let maxWidth: CGFloat = 100
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: maxWidth,
        ))
        // Should have multiple lines (different y positions)
        var uniqueYPositions = Set<CGFloat>()
        for subDisplay in display.subDisplays {
            uniqueYPositions
                .insert(round(subDisplay.position.y * 10) /
                    10) // Round to avoid floating point issues
        }

        #expect(uniqueYPositions.count > 1, "Should have multiple lines due to width constraint")

        // Each subdisplay should respect width constraint
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) width (\(subDisplay.width)) should respect constraint",
            )
        }
    }

    @Test func mixedScriptedAndNonScripted() throws {
        // Test mixing scripted and non-scripted atoms
        let latex = "a+b^{2}+c+d^{2}+e"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 180
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: maxWidth,
        ))
        // Should fit on one or few lines
        // Note: subdisplay count may be higher with tokenization
        // Count unique y-positions for actual line count
        let uniqueYPositions = Set(display.subDisplays.map(\.position.y))
        #expect(uniqueYPositions.count <= 8, "Mixed expression should have reasonable line count")

        // Verify width constraints
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) should respect width constraint",
            )
        }
    }

    @Test func subscriptsAndSuperscripts() throws {
        // Test atoms with both subscripts and superscripts
        let latex = "x_{1}^{2}+x_{2}^{2}+x_{3}^{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 200
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: maxWidth,
        ))
        // Should fit on reasonable number of lines
        #expect(!display.subDisplays.isEmpty, "Should have content")

        // Verify width constraints
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) should respect width constraint",
            )
        }
    }

    @Test func realWorld_QuadraticExpansion() throws {
        // Real-world test: quadratic expansion with exponents
        let latex = "(a+b)^{2}=a^{2}+2ab+b^{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 250
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: maxWidth,
        ))
        // Should fit on reasonable number of lines
        #expect(!display.subDisplays.isEmpty, "Quadratic expansion should render")

        // Verify width constraints
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) should respect width constraint",
            )
        }
    }

    @Test func realWorld_Polynomial() throws {
        // Real-world test: polynomial with multiple terms
        let latex = "x^{4}+x^{3}+x^{2}+x+1"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 180
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: maxWidth,
        ))
        // Should have reasonable structure
        #expect(!display.subDisplays.isEmpty, "Polynomial should render")

        // Verify width constraints
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.2,
                "Line \(index) should respect width constraint",
            )
        }
    }

    @Test func scriptedAtoms_NoBreakingWithoutConstraint() throws {
        // Test that scripted atoms don't break unnecessarily without width constraint
        let latex = "a^{2}+b^{2}+c^{2}+d^{2}+e^{2}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        // No width constraint (maxWidth = 0)
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: 0,
        ))
        // Check for line breaks - should have none without width constraint
        let yPositions = display.subDisplays.map(\.position.y).sorted()
        var lineBreakCount = 0
        for i in 1 ..< yPositions.count {
            let gap = abs(yPositions[i] - yPositions[i - 1])
            if gap > font.fontSize {
                lineBreakCount += 1
            }
        }

        #expect(lineBreakCount == 0, "Without width constraint, should have no line breaks")
    }

    @Test func complexScriptedExpression() throws {
        // Test complex expression mixing fractions and scripts
        let latex = "\\frac{x^{2}}{y^{2}}+a^{2}+\\sqrt{b^{2}}"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 220
        let display = try #require(Typesetter.makeLineDisplay(
            for: mathList, font: font, style: .display, maxWidth: maxWidth,
        ))
        // Should render successfully
        #expect(!display.subDisplays.isEmpty, "Complex expression should render")

        // Verify width constraints
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.3,
                "Line \(index) should respect width constraint (with tolerance for complex atoms)",
            )
        }
    }
}
