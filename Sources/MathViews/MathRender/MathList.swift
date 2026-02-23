public import Foundation

/// The type of atom in a `MathList`.
///
/// The type of the atom determines how it is rendered, and spacing between the atoms.
public enum MathAtomType: Int, CustomStringConvertible, Comparable, Sendable {
    /// A number or text in ordinary format - Ord in TeX
    case ordinary = 1
    /// A number - Does not exist in TeX
    case number
    /// A variable (i.e. text in italic format) - Does not exist in TeX
    case variable
    /// A large operator such as (sin/cos, integral etc.) - Op in TeX
    case largeOperator
    /// A binary operator - Bin in TeX
    case binaryOperator
    /// A unary operator - Does not exist in TeX.
    case unaryOperator
    /// A relation, e.g. = > < etc. - Rel in TeX
    case relation
    /// Open brackets - Open in TeX
    case open
    /// Close brackets - Close in TeX
    case close
    /// A fraction e.g 1/2 - generalized fraction node in TeX
    case fraction
    /// A radical operator e.g. sqrt(2)
    case radical
    /// Punctuation such as , - Punct in TeX
    case punctuation
    /// A placeholder square for future input. Does not exist in TeX
    case placeholder
    /// An inner atom, i.e. an embedded math list - Inner in TeX
    case inner
    /// An underlined atom - Under in TeX
    case underline
    /// An overlined atom - Over in TeX
    case overline
    /// An accented atom - Accent in TeX
    case accent

    // Atoms after this point do not support subscripts or superscripts

    /// A left atom - Left & Right in TeX. We don't need two since we track boundaries separately.
    case boundary = 101

    // Atoms after this are non-math TeX nodes that are still useful in math mode. They do not have
    // the usual structure.

    /// Spacing between math atoms. This denotes both glue and kern for TeX. We do not
    /// distinguish between glue and kern.
    case space = 201

    /// Denotes style changes during rendering.
    case style
    case color
    case textColor
    case colorBox

    // Atoms after this point are not part of TeX and do not have the usual structure.

    /// An table atom. This atom does not exist in TeX. It is equivalent to the TeX command
    /// halign which is handled outside of the TeX math rendering engine. We bring it into our
    /// math typesetting to handle matrices and other tables.
    case table = 1001

    func isNotBinaryOperator() -> Bool {
        switch self {
            case .binaryOperator, .relation, .open, .punctuation, .largeOperator: return true
            default: return false
        }
    }

    func isScriptAllowed() -> Bool { self < .boundary }

    // we want string representations to be capitalized
    public var description: String {
        switch self {
            case .ordinary: return "Ordinary"
            case .number: return "Number"
            case .variable: return "Variable"
            case .largeOperator: return "Large Operator"
            case .binaryOperator: return "Binary Operator"
            case .unaryOperator: return "Unary Operator"
            case .relation: return "Relation"
            case .open: return "Open"
            case .close: return "Close"
            case .fraction: return "Fraction"
            case .radical: return "Radical"
            case .punctuation: return "Punctuation"
            case .placeholder: return "Placeholder"
            case .inner: return "Inner"
            case .underline: return "Underline"
            case .overline: return "Overline"
            case .accent: return "Accent"
            case .boundary: return "Boundary"
            case .space: return "Space"
            case .style: return "Style"
            case .color: return "Color"
            case .textColor: return "TextColor"
            case .colorBox: return "Colorbox"
            case .table: return "Table"
        }
    }

    // comparable support
    public static func < (lhs: MathAtomType, rhs: MathAtomType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// The font style of a character.
///
/// The fontstyle of the atom determines what style the character is rendered in. This only applies to atoms
/// of type MathAtomType.variable and MathAtomType.number. None of the other atom types change their font style.
public enum FontStyle: Int, Sendable {
    /// The default latex rendering style. i.e. variables are italic and numbers are roman.
    case defaultStyle = 0
    case
        /// Roman font style i.e. \mathrm
        roman,
        /// Bold font style i.e. \mathbf
        bold,
        /// Caligraphic font style i.e. \mathcal
        caligraphic,
        /// Typewriter (monospace) style i.e. \mathtt
        typewriter,
        /// Italic style i.e. \mathit
        italic,
        /// San-serif font i.e. \mathss
        sansSerif,
        /// Fractur font i.e \mathfrak
        fraktur,
        /// Blackboard font i.e. \mathbb
        blackboard,
        /// Bold italic
        boldItalic
}

// MARK: - MathAtom

/// A `MathAtom` is the basic unit of a math list. Each atom represents a single character
/// or mathematical operator in a list. However certain atoms can represent more complex structures
/// such as fractions and radicals. Each atom has a type which determines how the atom is rendered and
/// a nucleus. The nucleus contains the character(s) that need to be rendered. However the nucleus may
/// be empty for certain types of atoms. An atom has an optional subscript or superscript which represents
/// the subscript or superscript that is to be rendered.
///
/// Certain types of atoms inherit from `MathAtom` and may have additional fields.
public class MathAtom: CustomStringConvertible, Equatable, @unchecked Sendable {
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
            case .largeOperator:
                return LargeOperator(self as? LargeOperator)
            case .fraction:
                return Fraction(self as? Fraction)
            case .radical:
                return Radical(self as? Radical)
            case .style:
                return MathStyle(self as? MathStyle)
            case .inner:
                return Inner(self as? Inner)
            case .underline:
                return UnderLine(self as? UnderLine)
            case .overline:
                return OverLine(self as? OverLine)
            case .accent:
                return Accent(self as? Accent)
            case .space:
                return MathSpace(self as? MathSpace)
            case .color:
                return MathColorAtom(self as? MathColorAtom)
            case .textColor:
                return MathTextColor(self as? MathTextColor)
            case .colorBox:
                return MathColorbox(self as? MathColorbox)
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
        if superScript != nil {
            string += "^{\(superScript!.description)}"
        }
        if subScript != nil {
            string += "_{\(subScript!.description)}"
        }
        return string
    }

    /// Returns a finalized copy of the atom
    public var finalized: MathAtom {
        let finalized: MathAtom = copy()
        finalized.superScript = finalized.superScript?.finalized
        finalized.subScript = finalized.subScript?.finalized
        return finalized
    }

    public var string: String {
        var str = nucleus
        if let superScript {
            str.append("^{\(superScript.string)}")
        }
        if let subScript {
            str.append("_{\(subScript.string)}")
        }
        return str
    }

    // Fuse the given atom with this one by combining their nucleii.
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
        indexRange =
            indexRange.lowerBound ..< (indexRange.upperBound + atom.indexRange.count)

        // Update super/subscript:
        superScript = atom.superScript
        subScript = atom.subScript
    }

    /// Returns true if this atom allows scripts (sub or super).
    func isScriptAllowed() -> Bool { type.isScriptAllowed() }

    func isNotBinaryOperator() -> Bool { type.isNotBinaryOperator() }
}

func isNotBinaryOperator(_ prevNode: MathAtom?) -> Bool {
    guard let prevNode else { return true }
    return prevNode.type.isNotBinaryOperator()
}

// MARK: - Fraction

public final class Fraction: MathAtom {
    public var hasRule: Bool = true
    public var leftDelimiter = ""
    public var rightDelimiter = ""
    public var numerator: MathList?
    public var denominator: MathList?

    // Continued fraction properties
    public var isContinuedFraction: Bool = false
    public var alignment: String = "c" // "l", "r", "c" for left, right, center

    init(_ frac: Fraction?) {
        super.init(frac)
        type = .fraction
        if let frac {
            numerator = MathList(frac.numerator)
            denominator = MathList(frac.denominator)
            hasRule = frac.hasRule
            leftDelimiter = frac.leftDelimiter
            rightDelimiter = frac.rightDelimiter
            isContinuedFraction = frac.isContinuedFraction
            alignment = frac.alignment
        }
    }

    init(hasRule rule: Bool = true) {
        super.init()
        type = .fraction
        hasRule = rule
    }

    override public var description: String {
        var string = hasRule ? "\\frac" : "\\atop"
        if !leftDelimiter.isEmpty {
            string += "[\(leftDelimiter)]"
        }
        if !rightDelimiter.isEmpty {
            string += "[\(rightDelimiter)]"
        }
        string +=
            "{\(numerator?.description ?? "placeholder")}{\(denominator?.description ?? "placeholder")}"
        if superScript != nil {
            string += "^{\(superScript!.description)}"
        }
        if subScript != nil {
            string += "_{\(subScript!.description)}"
        }
        return string
    }

    override public var finalized: MathAtom {
        guard let newFrac = super.finalized as? Fraction else { return super.finalized }
        newFrac.numerator = newFrac.numerator?.finalized
        newFrac.denominator = newFrac.denominator?.finalized
        return newFrac
    }
}

// MARK: - Radical

/// An atom of type radical (square root).
public final class Radical: MathAtom {
    /// Denotes the term under the square root sign
    public var radicand: MathList?

    /// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
    /// This can be null if there is no degree.
    public var degree: MathList?

    init(_ rad: Radical?) {
        super.init(rad)
        type = .radical
        radicand = MathList(rad?.radicand)
        degree = MathList(rad?.degree)
        nucleus = ""
    }

    override init() {
        super.init()
        type = .radical
        nucleus = ""
    }

    override public var description: String {
        var string = "\\sqrt"
        if degree != nil {
            string += "[\(degree!.description)]"
        }
        if radicand != nil {
            string += "{\(radicand?.description ?? "placeholder")}"
        }
        if superScript != nil {
            string += "^{\(superScript!.description)}"
        }
        if subScript != nil {
            string += "_{\(subScript!.description)}"
        }
        return string
    }

    override public var finalized: MathAtom {
        guard let newRad = super.finalized as? Radical else { return super.finalized }
        newRad.radicand = newRad.radicand?.finalized
        newRad.degree = newRad.degree?.finalized
        return newRad
    }
}

// MARK: - LargeOperator

/// A `MathAtom` of type `MathAtomType.largeOperator`.
public final class LargeOperator: MathAtom {
    /// Indicates whether the limits (if present) should be displayed
    /// above and below the operator in display mode. If limits is false
    /// then the limits (if present) are displayed like a regular subscript/superscript.
    public var limits: Bool = false

    init(_ op: LargeOperator?) {
        super.init(op)
        type = .largeOperator
        limits = op!.limits
    }

    init(value: String, limits: Bool) {
        super.init(type: .largeOperator, value: value)
        self.limits = limits
    }
}

// MARK: - Inner

/// An inner atom. This denotes an atom which contains a math list inside it. An inner atom
/// has optional boundaries. Note: Only one boundary may be present, it is not required to have
/// both.
public final class Inner: MathAtom {
    /// The inner math list
    public var innerList: MathList?
    /// The left boundary atom. This must be a node of type MathAtomType.boundary
    public var leftBoundary: MathAtom? {
        didSet {
            if let left = leftBoundary, left.type != .boundary {
                leftBoundary = nil
                preconditionFailure("Left boundary must be of type .boundary")
            }
        }
    }

    /// The right boundary atom. This must be a node of type MathAtomType.boundary
    public var rightBoundary: MathAtom? {
        didSet {
            if let right = rightBoundary, right.type != .boundary {
                rightBoundary = nil
                preconditionFailure("Right boundary must be of type .boundary")
            }
        }
    }

    /// Optional explicit delimiter height (in points). When set, this overrides the automatic
    /// delimiter sizing based on inner content. Used by \big, \Big, \bigg, \Bigg commands.
    public var delimiterHeight: CGFloat?

    init(_ inner: Inner?) {
        super.init(inner)
        type = .inner
        innerList = MathList(inner?.innerList)
        leftBoundary = MathAtom(inner?.leftBoundary)
        rightBoundary = MathAtom(inner?.rightBoundary)
        delimiterHeight = inner?.delimiterHeight
    }

    override init() {
        super.init()
        type = .inner
    }

    override public var description: String {
        var string = "\\inner"
        if leftBoundary != nil {
            string += "[\(leftBoundary!.nucleus)]"
        }
        string += "{\(innerList!.description)}"
        if rightBoundary != nil {
            string += "[\(rightBoundary!.nucleus)]"
        }
        if superScript != nil {
            string += "^{\(superScript!.description)}"
        }
        if subScript != nil {
            string += "_{\(subScript!.description)}"
        }
        return string
    }

    override public var finalized: MathAtom {
        guard let newInner = super.finalized as? Inner else { return super.finalized }
        newInner.innerList = newInner.innerList?.finalized
        return newInner
    }
}

// MARK: - OverLine

/// An atom with a line over the contained math list.
public final class OverLine: MathAtom {
    public var innerList: MathList?

    override public var finalized: MathAtom {
        let newOverline = OverLine(self)
        newOverline.innerList = newOverline.innerList?.finalized
        return newOverline
    }

    init(_ over: OverLine?) {
        super.init(over)
        type = .overline
        innerList = MathList(over!.innerList)
    }

    override init() {
        super.init()
        type = .overline
    }
}

// MARK: - UnderLine

/// An atom with a line under the contained math list.
public final class UnderLine: MathAtom {
    public var innerList: MathList?

    override public var finalized: MathAtom {
        guard let newUnderline = super.finalized as? UnderLine else { return super.finalized }
        newUnderline.innerList = newUnderline.innerList?.finalized
        return newUnderline
    }

    init(_ under: UnderLine?) {
        super.init(under)
        type = .underline
        innerList = MathList(under?.innerList)
    }

    override init() {
        super.init()
        type = .underline
    }
}

// MARK: - Accent

public final class Accent: MathAtom {
    public var innerList: MathList?
    /// Indicates if this accent should use stretchy arrow behavior (for \overrightarrow, etc.)
    /// vs short accent behavior (for \vec). Only applies to arrow accents.
    public var isStretchy: Bool = false
    /// Indicates if this accent should use wide stretching behavior (for \widehat, \widetilde)
    /// vs regular fixed-size accent behavior (for \hat, \tilde).
    public var isWide: Bool = false

    override public var finalized: MathAtom {
        guard let newAccent = super.finalized as? Accent else { return super.finalized }
        newAccent.innerList = newAccent.innerList?.finalized
        newAccent.isStretchy = isStretchy
        newAccent.isWide = isWide
        return newAccent
    }

    init(_ accent: Accent?) {
        super.init(accent)
        type = .accent
        innerList = MathList(accent?.innerList)
        isStretchy = accent?.isStretchy ?? false
        isWide = accent?.isWide ?? false
    }

    init(value: String) {
        super.init()
        type = .accent
        nucleus = value
    }
}

// MARK: - MathSpace

/// An atom representing space.
/// Note: None of the usual fields of the `MathAtom` apply even though this
/// class inherits from `MathAtom`. i.e. it is meaningless to have a value
/// in the nucleus, subscript or superscript fields.
public final class MathSpace: MathAtom {
    /// The amount of space represented by this object in mu units.
    public var space: CGFloat = 0

    /// Creates a new `MathSpace` with the given spacing.
    /// - parameter space: The amount of space in mu units.
    init(_ space: MathSpace?) {
        super.init(space)
        type = .space
        self.space = space?.space ?? 0
    }

    init(space: CGFloat) {
        super.init()
        type = .space
        self.space = space
    }
}

/// Styling of a line of math
public enum LineStyle: Int, Comparable, Sendable {
    /// Display style
    case display
    /// Text style (inline)
    case text
    /// Script style (for sub/super scripts)
    case script
    /// Script script style (for scripts of scripts)
    case scriptOfScript

    public func inc() -> LineStyle {
        let raw = rawValue + 1
        if let style = LineStyle(rawValue: raw) { return style }
        return .display
    }

    public var isNotScript: Bool { self < .script }
    public static func < (lhs: LineStyle, rhs: LineStyle) -> Bool { lhs.rawValue < rhs.rawValue }
}

// MARK: - MathStyle

/// An atom representing a style change.
/// Note: None of the usual fields of the `MathAtom` apply even though this
/// class inherits from `MathAtom`. i.e. it is meaningless to have a value
/// in the nucleus, subscript or superscript fields.
public final class MathStyle: MathAtom {
    public var style: LineStyle = .display

    init(_ style: MathStyle?) {
        super.init(style)
        type = .style
        self.style = style!.style
    }

    init(style: LineStyle) {
        super.init()
        type = .style
        self.style = style
    }
}

// MARK: - MathColorAtom

/// An atom representing an color element.
/// Note: None of the usual fields of the `MathAtom` apply even though this
/// class inherits from `MathAtom`. i.e. it is meaningless to have a value
/// in the nucleus, subscript or superscript fields.
public final class MathColorAtom: MathAtom {
    public var colorString: String = ""
    public var innerList: MathList?

    init(_ color: MathColorAtom?) {
        super.init(color)
        type = .color
        colorString = color?.colorString ?? ""
        innerList = MathList(color?.innerList)
    }

    override init() {
        super.init()
        type = .color
    }

    override public var string: String {
        "\\color{\(colorString)}{\(innerList!.string)}"
    }

    override public var finalized: MathAtom {
        guard let newColor = super.finalized as? MathColorAtom else { return super.finalized }
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
}

// MARK: - MathTextColor

/// An atom representing an textcolor element.
/// Note: None of the usual fields of the `MathAtom` apply even though this
/// class inherits from `MathAtom`. i.e. it is meaningless to have a value
/// in the nucleus, subscript or superscript fields.
public final class MathTextColor: MathAtom {
    public var colorString: String = ""
    public var innerList: MathList?

    init(_ color: MathTextColor?) {
        super.init(color)
        type = .textColor
        colorString = color?.colorString ?? ""
        innerList = MathList(color?.innerList)
    }

    override init() {
        super.init()
        type = .textColor
    }

    override public var string: String {
        "\\textcolor{\(colorString)}{\(innerList!.string)}"
    }

    override public var finalized: MathAtom {
        guard let newColor = super.finalized as? MathTextColor else { return super.finalized }
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
}

// MARK: - MathColorbox

/// An atom representing an colorbox element.
/// Note: None of the usual fields of the `MathAtom` apply even though this
/// class inherits from `MathAtom`. i.e. it is meaningless to have a value
/// in the nucleus, subscript or superscript fields.
public final class MathColorbox: MathAtom {
    public var colorString = ""
    public var innerList: MathList?

    init(_ cbox: MathColorbox?) {
        super.init(cbox)
        type = .colorBox
        colorString = cbox?.colorString ?? ""
        innerList = MathList(cbox?.innerList)
    }

    override init() {
        super.init()
        type = .colorBox
    }

    override public var string: String {
        "\\colorbox{\(colorString)}{\(innerList!.string)}"
    }

    override public var finalized: MathAtom {
        guard let newColor = super.finalized as? MathColorbox else { return super.finalized }
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
}

/// Alignment for a column of MathTable
public enum ColumnAlignment {
    case left
    case center
    case right
}

// MARK: - MathTable

/// An atom representing an table element. This atom is not like other
/// atoms and is not present in TeX. We use it to represent the `\halign` command
/// in TeX with some simplifications. This is used for matrices, equation
/// alignments and other uses of multiline environments.
///
/// The cells in the table are represented as a two dimensional array of
/// `MathList` objects. The `MathList`s could be empty to denote a missing
/// value in the cell. Additionally an array of alignments indicates how each
/// column will be aligned.
public final class MathTable: MathAtom {
    /// The alignment for each column (left, right, center). The default alignment
    /// for a column (if not set) is center.
    public var alignments = [ColumnAlignment]()
    /// The cells in the table as a two dimensional array.
    public var cells = [[MathList]]()
    /// The name of the environment that this table denotes.
    public var environment = ""
    /// Spacing between each column in mu units.
    public var interColumnSpacing: CGFloat = 0
    /// Additional spacing between rows in jots (one jot is 0.3 times font size).
    /// If the additional spacing is 0, then normal row spacing is used are used.
    public var interRowAdditionalSpacing: CGFloat = 0

    override public var finalized: MathAtom {
        guard let table = super.finalized as? MathTable else { return super.finalized }
        for var row in table.cells {
            for i in 0 ..< row.count {
                row[i] = row[i].finalized
            }
        }
        return table
    }

    init(environment: String?) {
        super.init()
        type = .table
        self.environment = environment ?? ""
    }

    init(_ table: MathTable) {
        super.init(table)
        type = .table
        alignments = table.alignments
        interRowAdditionalSpacing = table.interRowAdditionalSpacing
        interColumnSpacing = table.interColumnSpacing
        environment = table.environment
        var cellCopy = [[MathList]]()
        for row in table.cells {
            var newRow = [MathList]()
            for col in row {
                newRow.append(MathList(col)!)
            }
            cellCopy.append(newRow)
        }
        cells = cellCopy
    }

    override init() {
        super.init()
        type = .table
    }

    /// Set the value of a given cell. The table is automatically resized to contain this cell.
    public func set(cell list: MathList, forRow row: Int, column: Int) {
        if cells.count <= row {
            for _ in cells.count ... row {
                cells.append([])
            }
        }
        let rows = cells[row].count
        if rows <= column {
            for _ in rows ... column {
                cells[row].append(MathList())
            }
        }
        cells[row][column] = list
    }

    /// Set the alignment of a particular column. The table is automatically resized to
    /// contain this column and any new columns added have their alignment set to center.
    public func set(alignment: ColumnAlignment, forColumn col: Int) {
        if alignments.count <= col {
            for _ in alignments.count ... col {
                alignments.append(ColumnAlignment.center)
            }
        }

        alignments[col] = alignment
    }

    /// Gets the alignment for a given column. If the alignment is not specified it defaults
    /// to center.
    public func get(alignmentForColumn col: Int) -> ColumnAlignment {
        if alignments.count <= col {
            return ColumnAlignment.center
        } else {
            return alignments[col]
        }
    }

    public var numColumns: Int {
        var numberOfCols = 0
        for row in cells {
            numberOfCols = max(numberOfCols, row.count)
        }
        return numberOfCols
    }

    public var numRows: Int { cells.count }
}

// MARK: - MathList

extension MathList: CustomStringConvertible {
    public var description: String { atoms.description }
    /// converts the MathList to a string form. Note: This is not the LaTeX form.
    public var string: String { description }
}

/// A representation of a list of math objects.
///
///    This list can be constructed directly or built with
///    the help of the MathListBuilder. It is not required that the mathematics represented make sense
///    (i.e. this can represent something like "x 2 = +". This list can be used for display using MathListDisplay
///    or can be a list of tokens to be used by a parser after finalizedMathList is called.
///
///    Note: This class is for **advanced** usage only.
public final class MathList: Equatable, @unchecked Sendable {
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
                    if isNotBinaryOperator(prevNode) {
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

    func checkIndex(_ array: [Any], index: Int) {
        precondition(array.indices.contains(index), "Index \(index) out of bounds")
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
        checkIndex(atoms, index: index)
        atoms.remove(at: index)
    }

    /// Removes all the atoms within the given range.
    public func removeAtoms(in range: ClosedRange<Int>) {
        checkIndex(atoms, index: range.lowerBound)
        checkIndex(atoms, index: range.upperBound)
        atoms.removeSubrange(range)
    }

    func isAtomAllowed(_ atom: MathAtom?) -> Bool { atom?.type != .boundary }
}
