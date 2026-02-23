import Testing
@testable import MathViews
import Foundation

// MARK: - Dirac Notation Tests

struct MathListBuilderDiracTests {
    @Test func braCommand() {
        // Test \bra{psi} -> <psi|
        let list = MathListBuilder.build(fromString: "\\bra{\\psi}")
        #expect(list != nil)
        #expect(list?.atoms.count == 1)

        // Should be an Inner
        let inner = list?.atoms.first as? Inner
        #expect(inner != nil)
        #expect(inner?.type == .inner)

        // Check left boundary is langle
        #expect(inner?.leftBoundary != nil)
        #expect(inner?.leftBoundary?.nucleus == "\u{2329}")

        // Check right boundary is vert (|)
        #expect(inner?.rightBoundary != nil)
        #expect(inner?.rightBoundary?.nucleus == "|")

        // Check inner content is psi
        #expect(inner?.innerList != nil)
        #expect(inner?.innerList?.atoms.count == 1)
        #expect(inner?.innerList?.atoms.first?.nucleus == "\u{03C8}") // psi
    }

    @Test func ketCommand() {
        // Test \ket{psi} -> |psi>
        let list = MathListBuilder.build(fromString: "\\ket{\\psi}")
        #expect(list != nil)
        #expect(list?.atoms.count == 1)

        // Should be an Inner
        let inner = list?.atoms.first as? Inner
        #expect(inner != nil)
        #expect(inner?.type == .inner)

        // Check left boundary is vert (|)
        #expect(inner?.leftBoundary != nil)
        #expect(inner?.leftBoundary?.nucleus == "|")

        // Check right boundary is rangle
        #expect(inner?.rightBoundary != nil)
        #expect(inner?.rightBoundary?.nucleus == "\u{232A}")

        // Check inner content is psi
        #expect(inner?.innerList != nil)
        #expect(inner?.innerList?.atoms.count == 1)
        #expect(inner?.innerList?.atoms.first?.nucleus == "\u{03C8}") // psi
    }

    @Test func braketCommand() {
        // Test \braket{phi}{psi} -> <phi|psi>
        let list = MathListBuilder.build(fromString: "\\braket{\\phi}{\\psi}")
        #expect(list != nil)
        #expect(list?.atoms.count == 1)

        // Should be an Inner
        let inner = list?.atoms.first as? Inner
        #expect(inner != nil)
        #expect(inner?.type == .inner)

        // Check left boundary is langle
        #expect(inner?.leftBoundary != nil)
        #expect(inner?.leftBoundary?.nucleus == "\u{2329}")

        // Check right boundary is rangle
        #expect(inner?.rightBoundary != nil)
        #expect(inner?.rightBoundary?.nucleus == "\u{232A}")

        // Check inner content is phi | psi (3 atoms)
        #expect(inner?.innerList != nil)
        #expect(inner?.innerList?.atoms.count == 3)
        #expect(inner?.innerList?.atoms[0].nucleus == "\u{0001D719}") // phi
        #expect(inner?.innerList?.atoms[1].nucleus == "|") // separator
        #expect(inner?.innerList?.atoms[2].nucleus == "\u{03C8}") // psi
    }

    @Test func diracInExpression() {
        // Test Dirac notation in a larger expression
        let list = MathListBuilder.build(fromString: "H\\ket{\\psi}=E\\ket{\\psi}")
        #expect(list != nil)
        #expect(list?.atoms.count == 5)

        // H, ket{psi}, =, E, ket{psi}
        #expect(list?.atoms[0].type == .variable) // H
        #expect(list?.atoms[1].type == .inner) // \ket{psi}
        #expect(list?.atoms[2].type == .relation) // =
        #expect(list?.atoms[3].type == .variable) // E
        #expect(list?.atoms[4].type == .inner) // \ket{psi}
    }

    @Test func braketWithComplexContent() {
        // Test with more complex content inside
        let list = MathListBuilder.build(fromString: "\\braket{n}{m}")
        #expect(list != nil)

        let inner = list?.atoms.first as? Inner
        #expect(inner != nil)

        // Inner content should have n | m
        #expect(inner?.innerList?.atoms.count == 3)
        #expect(inner?.innerList?.atoms[0].nucleus == "n")
        #expect(inner?.innerList?.atoms[1].nucleus == "|")
        #expect(inner?.innerList?.atoms[2].nucleus == "m")
    }

    // MARK: - Operatorname Tests

    @Test func operatornameCommand() {
        // Test \operatorname{lcm} creates a large operator
        let list = MathListBuilder.build(fromString: "\\operatorname{lcm}")
        #expect(list != nil)
        #expect(list?.atoms.count == 1)

        // Should be an LargeOperator
        let op = list?.atoms.first as? LargeOperator
        #expect(op != nil)
        #expect(op?.type == .largeOperator)
        #expect(op?.nucleus == "lcm")
        #expect(!(op?.hasLimits ?? true))
    }

    @Test func operatornameStarCommand() {
        // Test \operatorname*{argmax} creates a large operator with limits
        let list = MathListBuilder.build(fromString: "\\operatorname*{argmax}")
        #expect(list != nil)
        #expect(list?.atoms.count == 1)

        // Should be an LargeOperator with limits
        let op = list?.atoms.first as? LargeOperator
        #expect(op != nil)
        #expect(op?.type == .largeOperator)
        #expect(op?.nucleus == "argmax")
        #expect(op?.hasLimits ?? false)
    }

    @Test func operatornameInExpression() {
        // Test operatorname in a larger expression
        let list = MathListBuilder.build(fromString: "\\operatorname{Tr}(A)")
        #expect(list != nil)
        #expect(list?.atoms.count == 4)

        // Tr, (, A, )
        #expect(list?.atoms[0].type == .largeOperator) // Tr
        #expect(list?.atoms[0].nucleus == "Tr")
        #expect(list?.atoms[1].type == .open) // (
        #expect(list?.atoms[2].type == .variable) // A
        #expect(list?.atoms[3].type == .close) // )
    }

    @Test func operatornameWithSubscript() {
        // Test \operatorname*{arg\,min}_{x} with limits
        let list = MathListBuilder.build(fromString: "\\operatorname*{argmax}_x")
        #expect(list != nil)
        #expect(list?.atoms.count == 1)

        let op = list?.atoms.first as? LargeOperator
        #expect(op != nil)
        #expect(op?.nucleus == "argmax")

        // Check subscript
        #expect(op?.subScript != nil)
        #expect(op?.subScript?.atoms.count == 1)
        #expect(op?.subScript?.atoms.first?.nucleus == "x")
    }
}
