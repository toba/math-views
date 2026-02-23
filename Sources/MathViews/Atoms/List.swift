import Foundation

// MARK: - MathList

extension MathList: CustomStringConvertible {
    public var description: String { atoms.description }
    /// converts the MathList to a string form. Note: This is not the LaTeX form.
    public var latexString: String { description }
}

/// An ordered list of ``MathAtom`` objects representing a mathematical expression.
///
/// A `MathList` is the abstract syntax tree (AST) produced by ``MathListBuilder`` from
/// a LaTeX string. It does not need to represent valid mathematics — it can hold any
/// sequence of atoms.
///
/// Before typesetting, call ``finalized`` to produce a copy with adjacent digits fused
/// and binary operators reclassified where appropriate. The typesetter requires a
/// finalized list.
public final class MathList: Equatable {
    public static func == (lhs: MathList, rhs: MathList) -> Bool { lhs === rhs }

    init?(_ list: MathList?) {
        guard let list else { return nil }
        for atom in list.atoms {
            atoms.append(atom.copy())
        }
    }

    /// A list of MathAtoms
    public var atoms = [MathAtom]()

    /// Create a new math list as a final expression and update atoms
    /// by combining like atoms that occur together and converting unary operators to binary operators.
    /// This function does not modify the current MathList
    public var finalized: MathList {
        let finalizedList = MathList()
        var prevNode: MathAtom?
        for atom in atoms {
            let newNode = atom.finalized

            if atom.indexRange.isEmpty {
                let index = prevNode?.indexRange.upperBound ?? 0
                newNode.indexRange = index ..< (index + 1)
            }

            switch newNode.type {
                case .binaryOperator:
                    if isBinaryOperator(prevNode) {
                        newNode.type = .unaryOperator
                    }
                case .relation, .punctuation, .close:
                    if prevNode != nil, prevNode!.type == .binaryOperator {
                        prevNode!.type = .unaryOperator
                    }
                case .number:
                    if prevNode != nil, prevNode!.type == .number, prevNode!.subScript == nil,
                       prevNode!.superScript == nil
                    {
                        prevNode!.fuse(with: newNode)
                        continue // skip the current node, we are done here.
                    }
                default: break
            }
            finalizedList.add(newNode)
            prevNode = newNode
        }
        if prevNode != nil, prevNode!.type == .binaryOperator {
            prevNode!.type = .unaryOperator
        }
        return finalizedList
    }

    public init(atoms: [MathAtom]) {
        self.atoms.append(contentsOf: atoms)
    }

    public init(atom: MathAtom) {
        atoms.append(atom)
    }

    public init() {}

    private func checkIndex(_ index: Int) {
        precondition(atoms.indices.contains(index), "Index \(index) out of bounds")
    }

    /// Add an atom to the end of the list.
    /// - parameter atom: The atom to be inserted. This cannot be `nil` and cannot have the type `MathAtomType.boundary`.
    public func add(_ atom: MathAtom?) {
        guard let atom else { return }
        precondition(
            isAtomAllowed(atom), "Cannot add atom of type \(atom.type.rawValue) into mathlist",
        )
        atoms.append(atom)
    }

    /// Inserts an atom at the given index. If index is already occupied, the objects at index and beyond are
    /// shifted by adding 1 to their indices to make room. An insert to an `index` greater than the number of atoms
    /// is ignored. Insertions of nil atoms is ignored.
    /// - parameter atom: The atom to be inserted. This cannot be `nil` and cannot have the type `MathAtomType.boundary`.
    /// - parameter index: The index where the atom is to be inserted. The index should be less than or equal to the
    ///  number of elements in the math list.
    public func insert(_ atom: MathAtom?, at index: Int) {
        guard let atom else { return }
        guard atoms.indices.contains(index) || index == atoms.endIndex else { return }
        precondition(
            isAtomAllowed(atom), "Cannot add atom of type \(atom.type.rawValue) into mathlist",
        )
        atoms.insert(atom, at: index)
    }

    /// Append the given list to the end of the current list.
    /// - parameter list: The list to append.
    public func append(_ list: MathList?) {
        guard let list else { return }
        atoms += list.atoms
    }

    /// Removes the last atom from the math list. If there are no atoms in the list this does nothing.
    public func removeLastAtom() {
        if !atoms.isEmpty {
            atoms.removeLast()
        }
    }

    /// Removes the atom at the given index.
    /// - parameter index: The index at which to remove the atom. Must be less than the number of atoms
    /// in the list.
    public func removeAtom(at index: Int) {
        checkIndex(index)
        atoms.remove(at: index)
    }

    /// Removes all the atoms within the given range.
    public func removeAtoms(in range: ClosedRange<Int>) {
        checkIndex(range.lowerBound)
        checkIndex(range.upperBound)
        atoms.removeSubrange(range)
    }

    func isAtomAllowed(_ atom: MathAtom?) -> Bool { atom?.type != .boundary }
}
