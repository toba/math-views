import Foundation

/// An index that points to a particular character in the MathList. The index is a LinkedList that represents
/// a path from the beginning of the MathList to reach a particular atom in the list. The next node of the path
/// is represented by the subIndex. The path terminates when the subIndex is nil.
///
/// If there is a subIndex, the subIndexType denotes what branch the path takes (i.e. superscript, subscript,
/// numerator, denominator etc.).
/// e.g in the expression 25^{2/4} the index of the character 4 is represented as:
/// (1, superscript) -> (0, denominator) -> (0, none)
/// This can be interpreted as start at index 1 (i.e. the 5) go up to the superscript.
/// Then look at index 0 (i.e. 2/4) and go to the denominator. Then look up index 0 (i.e. the 4) which this final
/// index.
///
/// The level of an index is the number of nodes in the LinkedList to get to the final path.
public final class MathListIndex {
    /// The type of the subindex.
    ///
    /// The type of the subindex denotes what branch the path to the atom that this index points to takes.
    public enum MathListSubIndexType: Int {
        /// The index denotes the whole atom, subIndex is nil.
        case none = 0
        /// The position in the subindex is an index into the nucleus
        case nucleus
        /// The subindex indexes into the superscript.
        case superscript
        /// The subindex indexes into the subscript
        case `subscript`
        /// The subindex indexes into the numerator (only valid for fractions)
        case numerator
        /// The subindex indexes into the denominator (only valid for fractions)
        case denominator
        /// The subindex indexes into the radicand (only valid for radicals)
        case radicand
        /// The subindex indexes into the degree (only valid for radicals)
        case degree
    }

    /// The index of the associated atom.
    var atomIndex: Int

    /// The type of subindex, e.g. superscript, numerator etc.
    var subIndexType: MathListSubIndexType = .none

    /// The index into the sublist.
    var subIndex: MathListIndex?

    var finalIndex: Int {
        if subIndexType == .none {
            return atomIndex
        } else {
            return subIndex?.finalIndex ?? 0
        }
    }

    /// Returns the previous index if present. Returns `nil` if there is no previous index.
    func prevIndex() -> MathListIndex? {
        if subIndexType == .none {
            if atomIndex > 0 {
                return MathListIndex(level0Index: atomIndex - 1)
            }
        } else {
            if let prevSubIndex = subIndex?.prevIndex() {
                return MathListIndex(at: atomIndex, with: prevSubIndex, type: subIndexType)
            }
        }
        return nil
    }

    /// Returns the next index.
    func nextIndex() -> MathListIndex {
        if subIndexType == .none {
            return MathListIndex(level0Index: atomIndex + 1)
        } else if subIndexType == .nucleus {
            return MathListIndex(at: atomIndex + 1, with: subIndex, type: subIndexType)
        } else {
            return MathListIndex(
                at: atomIndex, with: subIndex?.nextIndex(), type: subIndexType,
            )
        }
    }

    /// Returns true if this index represents the beginning of a line. Note there may be multiple lines in a MathList,
    /// e.g. a superscript or a fraction numerator. This returns true if the innermost subindex points to the beginning of a
    /// line.
    func isBeginningOfLine() -> Bool { finalIndex == 0 }

    func isAtSameLevel(with index: MathListIndex?) -> Bool {
        if subIndexType != index?.subIndexType {
            return false
        } else if subIndexType == .none {
            // No subindexes, they are at the same level.
            return true
        } else if atomIndex != index?.atomIndex {
            return false
        } else {
            return subIndex?.isAtSameLevel(with: index?.subIndex) ?? false
        }
    }

    /// Returns the type of the innermost sub index.
    func finalSubIndexType() -> MathListSubIndexType {
        if subIndex?.subIndex != nil {
            return subIndex!.finalSubIndexType()
        } else {
            return subIndexType
        }
    }

    /// Returns true if any of the subIndexes of this index have the given type.
    func hasSubIndex(ofType type: MathListSubIndexType) -> Bool {
        if subIndexType == type {
            return true
        } else {
            return subIndex?.hasSubIndex(ofType: type) ?? false
        }
    }

    func levelUp(with subIndex: MathListIndex?, type: MathListSubIndexType) -> MathListIndex {
        if subIndexType == .none {
            return MathListIndex(at: atomIndex, with: subIndex, type: type)
        }

        return MathListIndex(
            at: atomIndex, with: self.subIndex?.levelUp(with: subIndex, type: type),
            type: subIndexType,
        )
    }

    func levelDown() -> MathListIndex? {
        if subIndexType == .none {
            return nil
        }

        if let subIndexDown = subIndex?.levelDown() {
            return MathListIndex(at: atomIndex, with: subIndexDown, type: subIndexType)
        } else {
            return MathListIndex(level0Index: atomIndex)
        }
    }

    /// Factory function to create a `MathListIndex` with no subindexes.
    /// @param index The index of the atom that the `MathListIndex` points at.
    public init(level0Index: Int) {
        atomIndex = level0Index
    }

    public convenience init(
        at location: Int, with subIndex: MathListIndex?, type: MathListSubIndexType,
    ) {
        self.init(level0Index: location)
        subIndexType = type
        self.subIndex = subIndex
    }
}

extension MathListIndex: CustomStringConvertible {
    public var description: String {
        if subIndex != nil {
            return "[\(atomIndex), \(subIndexType.rawValue):\(subIndex!)]"
        }
        return "[\(atomIndex)]"
    }
}

extension MathListIndex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(atomIndex)
        hasher.combine(subIndexType)
        hasher.combine(subIndex)
    }
}

extension MathListIndex: Equatable {
    public static func == (lhs: MathListIndex, rhs: MathListIndex) -> Bool {
        if lhs.atomIndex != rhs.atomIndex || lhs.subIndexType != rhs.subIndexType {
            return false
        }

        if rhs.subIndex != nil {
            return rhs.subIndex == lhs.subIndex
        } else {
            return lhs.subIndex == nil
        }
    }
}
