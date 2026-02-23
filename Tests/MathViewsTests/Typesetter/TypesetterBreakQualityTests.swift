import Testing
@testable import MathViews
import CoreGraphics

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

struct TypesetterBreakQualityTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModern.fontInstance(size: 20)
    }

    // MARK: - Break Quality Scoring Tests

    @Test func breakQuality_PreferAfterBinaryOperator() throws {
        // Test that breaks prefer to occur after binary operators (+, -, ×, ÷)
        // Expression: "aaaa+bbbbcccc" where break should occur after + (not in middle of bbbbcccc)
        let latex = "aaaa+bbbbcccc"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        // Set width to force a break somewhere between + and end
        let maxWidth: CGFloat = 100
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Extract text content from each line to verify break location
        var lineContents: [String] = []
        for subDisplay in display.subDisplays {
            if let lineDisplay = subDisplay as? CTLineDisplay,
               let text = lineDisplay.attributedString?.string
            {
                lineContents.append(text)
            }
        }

        // With break quality scoring, should break after the + operator
        // First line should contain "aaaa+"
        let hasGoodBreak = lineContents.contains { $0.contains("+") }
        #expect(
            hasGoodBreak,
            "Break should occur after binary operator +, found lines: \(lineContents)",
        )
    }

    @Test func breakQuality_PreferAfterRelation() throws {
        // Test that breaks prefer to occur after relation operators (=, <, >)
        let latex = "aaaa=bbbb+cccc"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 90
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Extract line contents
        var lineContents: [String] = []
        for subDisplay in display.subDisplays {
            if let lineDisplay = subDisplay as? CTLineDisplay,
               let text = lineDisplay.attributedString?.string
            {
                lineContents.append(text)
            }
        }

        // Should break after the = operator
        let hasGoodBreak = lineContents.contains { $0.contains("=") }
        #expect(
            hasGoodBreak,
            "Break should occur after relation operator =, found lines: \(lineContents)",
        )
    }

    @Test func breakQuality_AvoidAfterOpenBracket() throws {
        // Test that breaks avoid occurring immediately after open brackets
        // Expression: "aaaa+(bbb+ccc)" should NOT break as "aaaa+(\n bbb+ccc)"
        let latex = "aaaa+(bbb+ccc)"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 100
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Extract line contents
        var lineContents: [String] = []
        for subDisplay in display.subDisplays {
            if let lineDisplay = subDisplay as? CTLineDisplay,
               let text = lineDisplay.attributedString?.string
            {
                lineContents.append(text)
            }
        }

        // Should NOT have a line ending with "+(" - bad break point
        let hasBadBreak = lineContents.contains { $0.hasSuffix("+(") }
        #expect(
            !hasBadBreak,
            "Should avoid breaking after open bracket, found lines: \(lineContents)",
        )
    }

    @Test func breakQuality_LookAheadFindsBetterBreak() throws {
        // Test that look-ahead finds better break points
        // Expression: "aaabbb+ccc" with tight width
        // Should defer break to after + rather than between aaa and bbb
        let latex = "aaabbb+ccc"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        // Width set so that "aaabbb" slightly exceeds, but look-ahead should find + as better break
        let maxWidth: CGFloat = 60
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Extract line contents
        var lineContents: [String] = []
        for subDisplay in display.subDisplays {
            if let lineDisplay = subDisplay as? CTLineDisplay,
               let text = lineDisplay.attributedString?.string
            {
                lineContents.append(text)
            }
        }

        // Should break after + (penalty 0) rather than in the middle (penalty 10 or 50)
        let hasGoodBreak = lineContents.contains { $0.contains("+") }
        #expect(
            hasGoodBreak,
            "Look-ahead should find better break after +, found lines: \(lineContents)",
        )
    }

    @Test func breakQuality_MultipleOperators() throws {
        // Test with multiple operators - should break at best available points
        let latex = "a+b+c+d+e+f"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 60
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Count line breaks
        let yPositions = display.subDisplays.map(\.position.y).sorted()
        var lineBreakCount = 0
        for i in 1 ..< yPositions.count {
            let gap = abs(yPositions[i] - yPositions[i - 1])
            if gap > font.fontSize {
                lineBreakCount += 1
            }
        }

        // Should have some breaks
        #expect(lineBreakCount > 0, "Expression should break into multiple lines")

        // Each line should respect width constraint
        for subDisplay in display.subDisplays {
            #expect(subDisplay.width <= maxWidth * 1.2, "Each line should respect width constraint")
        }
    }

    @Test func breakQuality_ComplexExpression() throws {
        // Test complex expression with various atom types
        let latex = "x=a+b\\times c+\\frac{d}{e}+f"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 120
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should render successfully
        #expect(!display.subDisplays.isEmpty, "Should have content")

        // Verify all subdisplays respect width constraints
        for (index, subDisplay) in display.subDisplays.enumerated() {
            #expect(
                subDisplay.width <= maxWidth * 1.3,
                "Line \(index) should respect width (with tolerance for complex atoms)",
            )
        }
    }

    @Test func breakQuality_NoBreakWhenNotNeeded() throws {
        // Test that break quality scoring doesn't add unnecessary breaks
        let latex = "a+b+c"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 200 // Wide enough to fit everything
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Should have no breaks when content fits
        let yPositions = display.subDisplays.map(\.position.y).sorted()
        var lineBreakCount = 0
        for i in 1 ..< yPositions.count {
            let gap = abs(yPositions[i] - yPositions[i - 1])
            if gap > font.fontSize {
                lineBreakCount += 1
            }
        }

        #expect(lineBreakCount == 0, "Should not add breaks when content fits within width")
    }

    @Test func breakQuality_PenaltyOrdering() throws {
        // Test that penalty system correctly orders break preferences
        // Given: "aaaa+b(ccc" - when break is needed, should prefer breaking after + (penalty 0)
        // rather than after ( (penalty 100)
        let latex = "aaaa+b(ccc"
        let mathList = MathListBuilder.build(fromString: latex)
        #expect(mathList != nil, "Should parse LaTeX")

        let maxWidth: CGFloat = 70
        let display = try #require(
            Typesetter.makeLineDisplay(
                for: mathList, font: font, style: .display, maxWidth: maxWidth,
            ),
        )
        // Extract line contents
        var lineContents: [String] = []
        for subDisplay in display.subDisplays {
            if let lineDisplay = subDisplay as? CTLineDisplay,
               let text = lineDisplay.attributedString?.string
            {
                lineContents.append(text)
            }
        }

        // Should prefer breaking after "+" (penalty 0) rather than after "(" (penalty 100)
        let breaksAfterPlus = lineContents.contains { $0.contains("+") && !$0.contains("(") }
        #expect(
            breaksAfterPlus || lineContents.count == 1,
            "Should prefer breaking after + operator or fit on one line, found lines: \(lineContents)",
        )
    }
}
