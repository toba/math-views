import Testing
@testable import MathViews
import Foundation
import CoreGraphics

struct LineFitterTests {
    let font: FontInstance

    init() {
        font = MathFont.latinModernFont.fontInstance(size: 20)
    }

    // MARK: - Basic Fitting Tests

    @Test func fitEmptyList() {
        let fitter = LineFitter(maxWidth: 100)
        let lines = fitter.fitLines([])
        #expect(lines.isEmpty)
    }

    @Test func fitSingleElement() {
        let element = createTextElement("x", width: 10)
        let fitter = LineFitter(maxWidth: 100)
        let lines = fitter.fitLines([element])

        #expect(lines.count == 1)
        #expect(lines[0].count == 1)
    }

    @Test func fitElementsThatFitOnOneLine() {
        let elements = [
            createTextElement("x", width: 20),
            createTextElement("+", width: 20),
            createTextElement("y", width: 20),
        ]
        let fitter = LineFitter(maxWidth: 100)
        let lines = fitter.fitLines(elements)

        #expect(lines.count == 1, "All elements should fit on one line")
        #expect(lines[0].count == 3)
    }

    @Test func fitElementsThatRequireMultipleLines() {
        let elements = [
            createTextElement("a", width: 40),
            createTextElement("+", width: 40),
            createTextElement("b", width: 40),
            createTextElement("=", width: 40),
            createTextElement("c", width: 40),
        ]
        let fitter = LineFitter(maxWidth: 100)
        let lines = fitter.fitLines(elements)

        #expect(lines.count > 1, "Should require multiple lines")
    }

    @Test func noWidthConstraint() {
        let elements = [
            createTextElement("x", width: 200),
            createTextElement("+", width: 200),
            createTextElement("y", width: 200),
        ]
        let fitter = LineFitter(maxWidth: 0) // No constraint
        let lines = fitter.fitLines(elements)

        #expect(lines.count == 1, "With no width constraint, all elements on one line")
    }

    // MARK: - Break Point Tests

    @Test func breakAtOperator() {
        let elements = [
            createTextElement("x", width: 30),
            createOperatorElement("+", width: 30), // Good break point
            createTextElement("y", width: 30),
            createTextElement("z", width: 30),
        ]
        let fitter = LineFitter(maxWidth: 80)
        let lines = fitter.fitLines(elements)

        #expect(lines.count > 1, "Should break at operator")
    }

    @Test func respectGrouping() {
        let groupId = UUID()

        let elements = [
            createGroupedElement("x", width: 20, groupId: groupId, isLast: false),
            createGroupedElement("²", width: 15, groupId: groupId, isLast: true),
            createOperatorElement("+", width: 20),
            createTextElement("y", width: 20),
        ]

        let fitter = LineFitter(maxWidth: 50)
        let lines = fitter.fitLines(elements)

        // x² should stay together (35px), even if it means starting a new line
        if lines.count > 1 {
            // If broken, x² should be together
            for line in lines {
                let groupedCount = line.count(where: { $0.groupId == groupId })
                // Either all grouped elements together or none
                #expect(groupedCount == 0 || groupedCount == 2)
            }
        }
    }

    // MARK: - Margin Tests

    @Test func margin() {
        let elements = [
            createTextElement("x", width: 40),
            createTextElement("y", width: 40),
            createTextElement("z", width: 40),
        ]

        let fitter = LineFitter(maxWidth: 100, margin: 10)
        let lines = fitter.fitLines(elements)

        // With margin, effective width is 90, so should break earlier
        #expect(lines.count > 1)
    }

    // MARK: - Helper Methods

    private func createTextElement(_ text: String, width: CGFloat) -> BreakableElement {
        let atom = MathAtom(type: .ordinary, value: text)
        return BreakableElement(
            content: .text(text),
            width: width,
            height: 10,
            ascent: 8,
            descent: 2,
            isBreakBefore: true,
            isBreakAfter: true,
            penaltyBefore: BreakPenalty.good,
            penaltyAfter: BreakPenalty.good,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: 0 ..< 1,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }

    private func createOperatorElement(_ op: String, width: CGFloat) -> BreakableElement {
        let atom = MathAtom(type: .binaryOperator, value: op)
        return BreakableElement(
            content: .operator(op, type: .binaryOperator),
            width: width,
            height: 10,
            ascent: 8,
            descent: 2,
            isBreakBefore: true,
            isBreakAfter: true,
            penaltyBefore: BreakPenalty.best,
            penaltyAfter: BreakPenalty.best,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: 0 ..< 1,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }

    private func createGroupedElement(_ text: String, width: CGFloat, groupId: UUID, isLast: Bool)
        -> BreakableElement
    {
        let atom = MathAtom(type: .ordinary, value: text)
        return BreakableElement(
            content: .text(text),
            width: width,
            height: 10,
            ascent: 8,
            descent: 2,
            isBreakBefore: !isLast, // First element can break before
            isBreakAfter: isLast, // Last element can break after
            penaltyBefore: isLast ? BreakPenalty.never : BreakPenalty.good,
            penaltyAfter: isLast ? BreakPenalty.good : BreakPenalty.never,
            groupId: groupId,
            parentId: nil,
            originalAtom: atom,
            indexRange: 0 ..< 1,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }
}
