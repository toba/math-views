import Testing
@testable import MathViews
import CoreGraphics

//
//  MathRenderSwiftTests.swift
//  MathRenderSwiftTests
//
//  Created by Mike Griebling on 2023-01-02.
//

struct MathListTests {
    @Test func subScript() throws {
        let str = "-52x^{13+y}_{15-} + (-12.3 *)\\frac{-12}{15.2}"
        let list = try #require(MathListBuilder.build(fromString: str))
        let finalized = list.finalized
        try checkListContents(finalized)
        // refinalizing a finalized list should not cause any more changes
        try checkListContents(finalized.finalized)
    }

    func checkListContents(_ finalized: MathList) throws {
        // check
        #expect((finalized.atoms.count) == 10, "Num atoms")
        var atom = finalized.atoms[0]
        #expect(atom.type == .unaryOperator, "Atom 0")
        #expect(atom.nucleus == "−", "Atom 0 value")
        #expect(atom.indexRange == 0 ..< 1, "Range")
        atom = finalized.atoms[1]
        #expect(atom.type == .number, "Atom 1")
        #expect(atom.nucleus == "52", "Atom 1 value")
        #expect(atom.indexRange == 1 ..< 3, "Range")
        atom = finalized.atoms[2]
        #expect(atom.type == .variable, "Atom 2")
        #expect(atom.nucleus == "x", "Atom 2 value")
        #expect(atom.indexRange == 3 ..< 4, "Range")

        let superScr = atom.superScript!
        #expect((superScr.atoms.count) == 3, "Super script")
        atom = superScr.atoms[0]
        #expect(atom.type == .number, "Super Atom 0")
        #expect(atom.nucleus == "13", "Super Atom 0 value")
        #expect(atom.indexRange == 0 ..< 2, "Range")
        atom = superScr.atoms[1]
        #expect(atom.type == .binaryOperator, "Super Atom 1")
        #expect(atom.nucleus == "+", "Super Atom 1 value")
        #expect(atom.indexRange == 2 ..< 3, "Range")
        atom = superScr.atoms[2]
        #expect(atom.type == .variable, "Super Atom 2")
        #expect(atom.nucleus == "y", "Super Atom 2 value")
        #expect(atom.indexRange == 3 ..< 4, "Range")

        atom = finalized.atoms[2]
        let subScr = atom.subScript!
        #expect((subScr.atoms.count) == 2, "Sub script")
        atom = subScr.atoms[0]
        #expect(atom.type == .number, "Sub Atom 0")
        #expect(atom.nucleus == "15", "Sub Atom 0 value")
        #expect(atom.indexRange == 0 ..< 2, "Range")
        atom = subScr.atoms[1]
        #expect(atom.type == .unaryOperator, "Sub Atom 1")
        #expect(atom.nucleus == "−", "Sub Atom 1 value")
        #expect(atom.indexRange == 2 ..< 3, "Range")

        atom = finalized.atoms[3]
        #expect(atom.type == .binaryOperator, "Atom 3")
        #expect(atom.nucleus == "+", "Atom 3 value")
        #expect(atom.indexRange == 4 ..< 5, "Range")
        atom = finalized.atoms[4]
        #expect(atom.type == .open, "Atom 4")
        #expect(atom.nucleus == "(", "Atom 4 value")
        #expect(atom.indexRange == 5 ..< 6, "Range")
        atom = finalized.atoms[5]
        #expect(atom.type == .unaryOperator, "Atom 5")
        #expect(atom.nucleus == "−", "Atom 5 value")
        #expect(atom.indexRange == 6 ..< 7, "Range")
        atom = finalized.atoms[6]
        #expect(atom.type == .number, "Atom 6")
        #expect(atom.nucleus == "12.3", "Atom 6 value")
        #expect(atom.indexRange == 7 ..< 11, "Range")
        atom = finalized.atoms[7]
        #expect(atom.type == .unaryOperator, "Atom 7")
        #expect(atom.nucleus == "*", "Atom 7 value")
        #expect(atom.indexRange == 11 ..< 12, "Range")
        atom = finalized.atoms[8]
        #expect(atom.type == .close, "Atom 8")
        #expect(atom.nucleus == ")", "Atom 8 value")
        #expect(atom.indexRange == 12 ..< 13, "Range")

        let frac = try #require(finalized.atoms[9] as? Fraction)
        #expect(frac.type == .fraction, "Atom 9")
        #expect(frac.nucleus.isEmpty, "Atom 9 value")
        #expect(frac.indexRange == 13 ..< 14, "Range")

        let numer = frac.numerator!
        #expect(numer != nil, "Numerator")
        #expect((numer.atoms.count) == 2, "Numer script")
        atom = numer.atoms[0]
        #expect(atom.type == .unaryOperator, "Numer Atom 0")
        #expect(atom.nucleus == "−", "Numer Atom 0 value")
        #expect(atom.indexRange == 0 ..< 1, "Range")
        atom = numer.atoms[1]
        #expect(atom.type == .number, "Numer Atom 1")
        #expect(atom.nucleus == "12", "Numer Atom 1 value")
        #expect(atom.indexRange == 1 ..< 3, "Range")

        let denom = frac.denominator!
        #expect(denom != nil, "Denominator")
        #expect((denom.atoms.count) == 1, "Denom script")
        atom = denom.atoms[0]
        #expect(atom.type == .number, "Denom Atom 0")
        #expect(atom.nucleus == "15.2", "Denom Atom 0 value")
        #expect(atom.indexRange == 0 ..< 4, "Range")
    }

    @Test func add() {
        let list = MathList()
        #expect(list.atoms.isEmpty)
        let atom = MathAtomFactory.placeholder()
        list.add(atom)
        #expect(list.atoms.count == 1)
        #expect(list.atoms[0] == atom)
        let atom2 = MathAtomFactory.placeholder()
        list.add(atom2)
        #expect(list.atoms.count == 2)
        #expect(list.atoms[0] == atom)
        #expect(list.atoms[1] == atom2)
    }

    @Test func addErrors() {
        // Test adding nil atom (should be silently ignored)
        let list = MathList()
        let atom: MathAtom? = nil
        list.add(atom)
        #expect(list.atoms.isEmpty, "Adding nil should not add to list")
        // Note: Adding a boundary atom triggers preconditionFailure which is not testable in-process
    }

    @Test func insert() {
        let list = MathList()
        #expect(list.atoms.isEmpty)
        let atom = MathAtomFactory.placeholder()
        list.insert(atom, at: 0)
        #expect(list.atoms.count == 1)
        #expect(list.atoms[0] == atom)
        let atom2 = MathAtomFactory.placeholder()
        list.insert(atom2, at: 0)
        #expect(list.atoms.count == 2)
        #expect(list.atoms[0] == atom2)
        #expect(list.atoms[1] == atom)
        let atom3 = MathAtomFactory.placeholder()
        list.insert(atom3, at: 2)
        #expect(list.atoms.count == 3)
        #expect(list.atoms[0] == atom2)
        #expect(list.atoms[1] == atom)
        #expect(list.atoms[2] == atom3)
    }

    @Test func insertErrors() {
        // Test inserting nil atom (should be silently ignored)
        let list = MathList()
        let atom: MathAtom? = nil
        list.insert(atom, at: 0)
        #expect(list.atoms.isEmpty, "Inserting nil should not add to list")
        // Note: Inserting a boundary atom triggers preconditionFailure which is not testable in-process
    }

    @Test func append() {
        let list1 = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.placeholder()
        let atom3 = MathAtomFactory.placeholder()
        list1.add(atom)
        list1.add(atom2)
        list1.add(atom3)

        let list2 = MathList()
        let atom5 = MathAtomFactory.times()
        let atom6 = MathAtomFactory.divide()
        list2.add(atom5)
        list2.add(atom6)

        #expect(list1.atoms.count == 3)
        #expect(list2.atoms.count == 2)

        list1.append(list2)
        #expect(list1.atoms.count == 5)
        #expect(list1.atoms[3] == atom5)
        #expect(list1.atoms[4] == atom6)
    }

    @Test func removeLast() {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        list.add(atom)
        #expect(list.atoms.count == 1)
        list.removeLastAtom()
        #expect(list.atoms.isEmpty)
        // Removing from empty list.
        list.removeLastAtom()
        #expect(list.atoms.isEmpty)
        let atom2 = MathAtomFactory.placeholder()
        list.add(atom)
        list.add(atom2)
        #expect(list.atoms.count == 2)
        list.removeLastAtom()
        #expect(list.atoms.count == 1)
        #expect(list.atoms[0] == atom)
    }

    @Test func removeAtomAtIndex() {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.placeholder()
        list.add(atom)
        list.add(atom2)
        #expect(list.atoms.count == 2)
        list.removeAtom(at: 0)
        #expect(list.atoms.count == 1)
        #expect(list.atoms[0] == atom2)

        // Note: Removing at out-of-bounds index triggers precondition which is not testable in-process
    }

    @Test func removeAtomsInRange() {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.placeholder()
        let atom3 = MathAtomFactory.placeholder()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)
        #expect(list.atoms.count == 3)
        list.removeAtoms(in: 1 ... 2)
        #expect(list.atoms.count == 1)
        #expect(list.atoms[0] == atom)
        // Note: Removing out-of-bounds range triggers precondition which is not testable in-process
    }

    //    func assertEqual(test, expression1, expression2, ...) \
    //    _XCTPrimitiveAssertEqual(test, expression1, @#expression1, expression2, @#expression2, __VA_ARGS__)
    //
    //    func assertNotEqual(test, expression1, expression2, ...) \
    //    _XCTPrimitiveAssertNotEqual(test, expression1, @#expression1, expression2, @#expression2, __VA_ARGS__)

    func checkAtomCopy(_ copy: MathAtom?, original: MathAtom?, forTest test: String) {
        guard let copy, let original else { return }
        #expect(copy.type == original.type, "\(test)")
        #expect(copy.nucleus == original.nucleus, "\(test)")
        // Should be different objects with the same content
        #expect(copy != original, "\(test)")
    }

    func checkListCopy(_ copy: MathList?, original: MathList?, forTest test: String) throws {
        guard let copy, let original else { return }
        #expect(copy.atoms.count == original.atoms.count, "\(test)")
        for (i, copyAtom) in copy.atoms.enumerated() {
            let origAtom = original.atoms[i]
            try checkAtomCopy(copyAtom, original: origAtom, forTest: test)
        }
    }

    @Test func copy() throws {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let list2 = MathList(list)
        try checkListCopy(list2, original: list, forTest: "MathListTests")
    }

    @Test func atomInit() {
        var atom = MathAtom(type: .open, value: "(")
        #expect(atom.nucleus == "(")
        #expect(atom.type == .open)

        atom = MathAtom(type: .radical, value: "(")
        #expect(atom.nucleus.isEmpty)
        #expect(atom.type == .radical)
    }

    @Test func atomScripts() {
        var atom = MathAtom(type: .open, value: "(")
        #expect(atom.isScriptAllowed())
        atom.subScript = MathList()
        #expect(atom.subScript != nil)
        atom.superScript = MathList()
        #expect(atom.superScript != nil)

        atom = MathAtom(type: .boundary, value: "(")
        #expect(!atom.isScriptAllowed())
        // Can set to nil
        atom.subScript = nil
        #expect(atom.subScript == nil)
        atom.superScript = nil
        #expect(atom.superScript == nil)
        // Can't set to value
        let list = MathList()

        // Note: Setting sub/super-script on boundary atoms triggers preconditionFailure
        // which is not testable in-process
    }

    @Test func atomCopy() throws {
        let list = MathList()
        let atom1 = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom1)
        list.add(atom2)
        list.add(atom3)

        let list2 = MathList()
        list2.add(atom3)
        list2.add(atom2)

        let atom = MathAtom(type: .open, value: "(")
        atom.subScript = list
        atom.superScript = list2
        let copy: MathAtom = atom.copy()

        try checkAtomCopy(copy, original: atom, forTest: "MathListTests")
        try checkListCopy(copy.superScript, original: atom.superScript, forTest: "MathListTests")
        try checkListCopy(copy.subScript, original: atom.subScript, forTest: "MathListTests")
    }

    @Test func copyFraction() throws {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let list2 = MathList()
        list2.add(atom3)
        list2.add(atom2)

        let frac = Fraction(hasRule: false)
        #expect(frac.type == .fraction)
        frac.numerator = list
        frac.denominator = list2
        frac.leftDelimiter = "a"
        frac.rightDelimiter = "b"

        let copy = Fraction(frac)
        try checkAtomCopy(copy, original: frac, forTest: "MathListTests")
        try checkListCopy(copy.numerator, original: frac.numerator, forTest: "MathListTests")
        try checkListCopy(copy.denominator, original: frac.denominator, forTest: "MathListTests")
        #expect(!copy.hasRule)
        #expect(copy.leftDelimiter == "a")
        #expect(copy.rightDelimiter == "b")
    }

    @Test func copyRadical() throws {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let list2 = MathList()
        list2.add(atom3)
        list2.add(atom2)

        let rad = Radical()
        #expect(rad.type == .radical)
        rad.radicand = list
        rad.degree = list2

        let copy = Radical(rad)
        try checkAtomCopy(copy, original: rad, forTest: "MathListTests")
        try checkListCopy(copy.radicand, original: rad.radicand, forTest: "MathListTests")
        try checkListCopy(copy.degree, original: rad.degree, forTest: "MathListTests")
    }

    @Test func copyLargeOperator() throws {
        let lg = LargeOperator(value: "lim", hasLimits: true)
        #expect(lg.type == .largeOperator)
        #expect(lg.hasLimits)

        let copy = LargeOperator(lg)
        try checkAtomCopy(copy, original: lg, forTest: "MathListTests")
        #expect(copy.hasLimits == lg.hasLimits)
    }

    @Test func copyInner() throws {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let inner = Inner()
        inner.innerList = list
        inner.leftBoundary = MathAtom(type: .boundary, value: "(")
        inner.rightBoundary = MathAtom(type: .boundary, value: ")")
        #expect(inner.type == .inner)

        let copy = Inner(inner)
        try checkAtomCopy(copy, original: inner, forTest: "MathListTests")
        try checkListCopy(copy.innerList, original: inner.innerList, forTest: "MathListTests")
        try checkAtomCopy(
            #require(copy.leftBoundary),
            original: inner.leftBoundary,
            forTest: "MathListTests",
        )
        try checkAtomCopy(
            copy.rightBoundary,
            original: inner.rightBoundary,
            forTest: "MathListTests",
        )
    }

    @Test func setInnerBoundary() {
        let inner = Inner()

        // Can set non-nil
        inner.leftBoundary = MathAtom(type: .boundary, value: "(")
        inner.rightBoundary = MathAtom(type: .boundary, value: ")")
        #expect(inner.leftBoundary != nil)
        #expect(inner.rightBoundary != nil)
        // Can set nil
        inner.leftBoundary = nil
        inner.rightBoundary = nil
        #expect(inner.leftBoundary == nil)
        #expect(inner.rightBoundary == nil)
        // Note: Setting non-boundary atoms as boundaries triggers preconditionFailure
        // which is not testable in-process
    }

    @Test func copyOverline() throws {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let over = OverLine()
        #expect(over.type == .overline)
        over.innerList = list

        let copy = OverLine(over)
        try checkAtomCopy(copy, original: over, forTest: "MathListTests")
        try checkListCopy(copy.innerList, original: over.innerList, forTest: "MathListTests")
    }

    @Test func copyUnderline() throws {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let under = UnderLine()
        #expect(under.type == .underline)
        under.innerList = list

        let copy = UnderLine(under)
        try checkAtomCopy(copy, original: under, forTest: "MathListTests")
        try checkListCopy(copy.innerList, original: under.innerList, forTest: "MathListTests")
    }

    @Test func copyAcccent() throws {
        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let accent = Accent(value: "^")
        #expect(accent.type == .accent)
        accent.innerList = list

        let copy = Accent(accent)
        try checkAtomCopy(copy, original: accent, forTest: "MathListTests")
        try checkListCopy(copy.innerList, original: accent.innerList, forTest: "MathListTests")
    }

    @Test func copySpace() throws {
        let space = MathSpace(space: 3)
        #expect(space.type == .space)

        let copy = MathSpace(space)
        try checkAtomCopy(copy, original: space, forTest: "MathListTests")
        #expect(space.space == copy.space)
    }

    @Test func copyStyle() throws {
        let style = MathStyle(style: .script)
        #expect(style.type == .style)

        let copy = MathStyle(style)
        try checkAtomCopy(copy, original: style, forTest: "MathListTests")
        #expect(style.style == copy.style)
    }

    @Test func createMathTable() {
        let table = MathTable()
        #expect(table.type == .table)

        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let list2 = MathList()
        list2.add(atom3)
        list2.add(atom2)

        table.setCell(list, row: 3, column: 2)
        table.setCell(list2, row: 1, column: 0)

        table.setAlignment(.left, forColumn: 2)
        table.setAlignment(.right, forColumn: 1)

        // Verify that everything is created correctly
        #expect(table.cells.count == 4) // 4 rows
        #expect(table.cells[0] != nil)
        #expect(table.cells[0].isEmpty) // 0 elements in row 0
        #expect(table.cells[1].count == 1) // 1 element in row 1
        #expect(table.cells[2] != nil)
        #expect(table.cells[2].isEmpty)
        #expect(table.cells[3].count == 3)

        // Verify the elements in the rows
        #expect(table.cells[1][0].atoms.count == 2)
        #expect(table.cells[1][0] == list2)
        #expect(table.cells[3][0] != nil)
        #expect(table.cells[3][0].atoms.isEmpty)

        #expect(table.cells[3][0] != nil)
        #expect(table.cells[3][0].atoms.isEmpty)

        #expect(table.cells[3][1] != nil)
        #expect(table.cells[3][1].atoms.isEmpty)

        #expect(table.cells[3][2] == list)

        #expect(table.numRows == 4)
        #expect(table.numColumns == 3)

        // Verify the alignments
        #expect(table.alignments.count == 3)
        #expect(table.alignments[0] == .center)
        #expect(table.alignments[1] == .right)
        #expect(table.alignments[2] == .left)
    }

    @Test func copyMathTable() throws {
        let table = MathTable()
        #expect(table.type == .table)

        let list = MathList()
        let atom = MathAtomFactory.placeholder()
        let atom2 = MathAtomFactory.times()
        let atom3 = MathAtomFactory.divide()
        list.add(atom)
        list.add(atom2)
        list.add(atom3)

        let list2 = MathList()
        list2.add(atom3)
        list2.add(atom2)

        table.setCell(list, row: 0, column: 1)
        table.setCell(list2, row: 0, column: 2)

        table.setAlignment(.left, forColumn: 2)
        table.setAlignment(.right, forColumn: 1)
        table.interRowAdditionalSpacing = 3
        table.interColumnSpacing = 10

        let copy = MathTable(table)
        try checkAtomCopy(copy, original: table, forTest: "MathListTests")
        #expect(copy.interColumnSpacing == table.interColumnSpacing)
        #expect(copy.interRowAdditionalSpacing == table.interRowAdditionalSpacing)
        #expect(copy.alignments == table.alignments)

        #expect(copy.cells != table.cells)
        #expect(copy.cells[0] != table.cells[0])
        #expect(copy.cells[0].count == table.cells[0].count)
        #expect(copy.cells[0][0].atoms.isEmpty)
        #expect(copy.cells[0][0] != table.cells[0][0])
        try checkListCopy(copy.cells[0][1], original: list, forTest: "MathListTests")
        try checkListCopy(copy.cells[0][2], original: list2, forTest: "MathListTests")
    }
}
