import Foundation

// MARK: - MathAtom

/// The basic unit of a ``MathList``.
///
/// Each atom represents one mathematical element — a character, operator, delimiter, or
/// structural construct (fraction, radical, etc.). The atom's ``type`` determines how it
/// is rendered and what inter-element spacing the typesetter inserts around it.
///
/// - ``nucleus`` contains the character(s) to render. For simple atoms this is a single
///   character like `"x"` or `"+"`. For large operators it can be a multi-character name
///   like `"sin"`. For structural atoms (fractions, radicals) the nucleus is empty.
/// - ``subScript`` and ``superScript`` are optional nested ``MathList``s for subscript
///   and superscript content. Not all atom types allow scripts (e.g. ``MathAtomType/boundary``
///   does not).
/// - ``indexRange`` tracks this atom's position in the original list, used during
///   finalization when atoms are fused.
///
/// Subclasses like ``Fraction``, ``Radical``, ``Accent``, and ``MathTable`` add fields
/// for their specific structure (numerator/denominator, radicand/degree, inner lists, etc.).
public class MathAtom: CustomStringConvertible, Equatable {
    public static func == (lhs: MathAtom, rhs: MathAtom) -> Bool { lhs === rhs }
    /// The type of the atom.
    public var type = MathAtomType.ordinary
    /// An optional subscript.
    public var subScript: MathList? {
        didSet {
            if subScript != nil, !isScriptAllowed() {
                subScript = nil
                preconditionFailure("Subscripts not allowed for atom of type \(type)")
            }
        }
    }

    /// An optional superscript.
    public var superScript: MathList? {
        didSet {
            if superScript != nil, !isScriptAllowed() {
                superScript = nil
                preconditionFailure("Superscripts not allowed for atom of type \(type)")
            }
        }
    }

    /// The nucleus of the atom.
    public var nucleus: String = ""

    /// The index range in the MathList this MathAtom tracks. This is used by the finalizing and preprocessing steps
    /// which fuse MathAtoms to track the position of the current MathAtom in the original list.
    public var indexRange = 0 ..< 0

    /// The font style to be used for the atom.
    var fontStyle: FontStyle = .defaultStyle

    /// If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one.
    /// This is used in the finalizing and preprocessing steps.
    var fusedAtoms = [MathAtom]()

    init(_ atom: MathAtom?) {
        guard let atom else { return }
        type = atom.type
        nucleus = atom.nucleus
        subScript = MathList(atom.subScript)
        superScript = MathList(atom.superScript)
        indexRange = atom.indexRange
        fontStyle = atom.fontStyle
        fusedAtoms = atom.fusedAtoms
    }

    init() {}

    /// Factory function to create an atom with a given type and value.
    /// - parameter type: The type of the atom to instantiate.
    /// - parameter value: The value of the atoms nucleus. The value is ignored for fractions and radicals.
    init(type: MathAtomType, value: String) {
        self.type = type
        nucleus = type == .radical ? "" : value
    }

    /// Returns a copy of `self`.
    public func copy() -> MathAtom {
        switch type {
            case .largeOperator: return LargeOperator(self as? LargeOperator)
            case .fraction: return Fraction(self as? Fraction)
            case .radical: return Radical(self as? Radical)
            case .style: return MathStyle(self as? MathStyle)
            case .inner: return Inner(self as? Inner)
            case .underline: return Underline(self as? Underline)
            case .overline: return Overline(self as? Overline)
            case .accent: return Accent(self as? Accent)
            case .space: return MathSpace(self as? MathSpace)
            case .color: return MathColorAtom(self as? MathColorAtom)
            case .textColor: return MathTextColor(self as? MathTextColor)
            case .colorBox: return MathColorBox(self as? MathColorBox)
            case .table:
                guard let table = self as? MathTable else { return MathAtom(self) }
                return MathTable(table)
            default:
                return MathAtom(self)
        }
    }

    public var description: String {
        var string = ""
        string += nucleus
        if superScript != nil { string += "^{\(superScript!.description)}" }
        if subScript != nil { string += "_{\(subScript!.description)}" }
        return string
    }

    /// Returns a finalized copy of the atom
    public var finalized: MathAtom {
        let finalized: MathAtom = copy()
        finalized.superScript = finalized.superScript?.finalized
        finalized.subScript = finalized.subScript?.finalized
        return finalized
    }

    public var latexString: String {
        var str = nucleus
        if let superScript { str.append("^{\(superScript.latexString)}") }
        if let subScript { str.append("_{\(subScript.latexString)}") }
        return str
    }

    // Fuse the given atom with this one by combining their nuclei.
    func fuse(with atom: MathAtom) {
        assert(subScript == nil, "Cannot fuse into an atom which has a subscript: \(self)")
        assert(superScript == nil, "Cannot fuse into an atom which has a superscript: \(self)")
        assert(atom.type == type, "Only atoms of the same type can be fused. \(self), \(atom)")
        guard subScript == nil, superScript == nil, type == atom.type
        else { return }

        // Update the fused atoms list
        if fusedAtoms.isEmpty {
            fusedAtoms.append(MathAtom(self))
        }
        if !atom.fusedAtoms.isEmpty {
            fusedAtoms.append(contentsOf: atom.fusedAtoms)
        } else {
            fusedAtoms.append(atom)
        }

        // Update nucleus:
        nucleus += atom.nucleus

        // Update range:
        indexRange = indexRange.lowerBound ..< (indexRange.upperBound + atom.indexRange.count)

        // Update super/subscript:
        superScript = atom.superScript
        subScript = atom.subScript
    }

    /// Returns true if this atom allows scripts (sub or super).
    func isScriptAllowed() -> Bool { type.isScriptAllowed() }

    func isBinaryOperator() -> Bool { type.isBinaryOperator() }
}

func isBinaryOperator(_ prevNode: MathAtom?) -> Bool {
    guard let prevNode else { return true }
    return prevNode.type.isBinaryOperator()
}
