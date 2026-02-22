import Foundation

/**
 The type of atom in a `MathList`.
 
 The type of the atom determines how it is rendered, and spacing between the atoms.
 */
public enum MathAtomType: Int, CustomStringConvertible, Comparable {
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
    case textcolor
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
            case .ordinary:       return "Ordinary"
            case .number:         return "Number"
            case .variable:       return "Variable"
            case .largeOperator:  return "Large Operator"
            case .binaryOperator: return "Binary Operator"
            case .unaryOperator:  return "Unary Operator"
            case .relation:       return "Relation"
            case .open:           return "Open"
            case .close:          return "Close"
            case .fraction:       return "Fraction"
            case .radical:        return "Radical"
            case .punctuation:    return "Punctuation"
            case .placeholder:    return "Placeholder"
            case .inner:          return "Inner"
            case .underline:      return "Underline"
            case .overline:       return "Overline"
            case .accent:         return "Accent"
            case .boundary:       return "Boundary"
            case .space:          return "Space"
            case .style:          return "Style"
            case .color:          return "Color"
            case .textcolor:      return "TextColor"
            case .colorBox:       return "Colorbox"
            case .table:          return "Table"
        }
    }
    
    // comparable support
    public static func < (lhs: MathAtomType, rhs: MathAtomType) -> Bool { lhs.rawValue < rhs.rawValue }
}

/**
 The font style of a character.

 The fontstyle of the atom determines what style the character is rendered in. This only applies to atoms
 of type MathAtomType.variable and MathAtomType.number. None of the other atom types change their font style.
 */
public enum FontStyle:Int {
    /// The default latex rendering style. i.e. variables are italic and numbers are roman.
    case defaultStyle = 0,
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

/** A `MathAtom` is the basic unit of a math list. Each atom represents a single character
 or mathematical operator in a list. However certain atoms can represent more complex structures
 such as fractions and radicals. Each atom has a type which determines how the atom is rendered and
 a nucleus. The nucleus contains the character(s) that need to be rendered. However the nucleus may
 be empty for certain types of atoms. An atom has an optional subscript or superscript which represents
 the subscript or superscript that is to be rendered.
 
 Certain types of atoms inherit from `MathAtom` and may have additional fields.
 */
public class MathAtom: NSObject {
    /** The type of the atom. */
    public var type = MathAtomType.ordinary
    /** An optional subscript. */
    public var subScript: MathList? {
        didSet {
            if subScript != nil && !self.isScriptAllowed() {
                subScript = nil
                NSException(name: NSExceptionName(rawValue: "Error"), reason: "Subscripts not allowed for atom of type \(self.type)").raise()
            }
        }
    }
    /** An optional superscript. */
    public var superScript: MathList? {
        didSet {
            if superScript != nil && !self.isScriptAllowed() {
                superScript = nil
                NSException(name: NSExceptionName(rawValue: "Error"), reason: "Superscripts not allowed for atom of type \(self.type)").raise()
            }
        }
    }
    
    /** The nucleus of the atom. */
    public var nucleus: String = ""
    
    /// The index range in the MathList this MathAtom tracks. This is used by the finalizing and preprocessing steps
    /// which fuse MathAtoms to track the position of the current MathAtom in the original list.
    public var indexRange = NSRange(location: 0, length: 0) // indexRange in list that this atom tracks:
    
    /** The font style to be used for the atom. */
    var fontStyle: FontStyle = .defaultStyle
    
    /// If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one.
    /// This is used in the finalizing and preprocessing steps.
    var fusedAtoms = [MathAtom]()
    
    init(_ atom:MathAtom?) {
        guard let atom = atom else { return }
        self.type = atom.type
        self.nucleus = atom.nucleus
        self.subScript = MathList(atom.subScript)
        self.superScript = MathList(atom.superScript)
        self.indexRange = atom.indexRange
        self.fontStyle = atom.fontStyle
        self.fusedAtoms = atom.fusedAtoms
    }
    
    override init() { }
    
    /// Factory function to create an atom with a given type and value.
    /// - parameter type: The type of the atom to instantiate.
    /// - parameter value: The value of the atoms nucleus. The value is ignored for fractions and radicals.
    init(type:MathAtomType, value:String) {
        self.type = type
        self.nucleus = type == .radical ? "" : value
    }
    
    /// Returns a copy of `self`.
    public func copy() -> MathAtom {
        switch self.type {
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
            case .textcolor:
                return MathTextColor(self as? MathTextColor)
            case .colorBox:
                return MathColorbox(self as? MathColorbox)
            case .table:
                return MathTable(self as! MathTable)
            default:
                return MathAtom(self)
        }
    }
    
    public override var description: String {
        var string = ""
        string += self.nucleus
        if self.superScript != nil {
            string += "^{\(self.superScript!.description)}"
        }
        if self.subScript != nil {
            string += "_{\(self.subScript!.description)}"
        }
        return string
    }
    
    /// Returns a finalized copy of the atom
    public var finalized: MathAtom {
        let finalized : MathAtom = self.copy()
        finalized.superScript = finalized.superScript?.finalized
        finalized.subScript = finalized.subScript?.finalized
        return finalized
    }
    
    public var string:String {
        var str = self.nucleus
        if let superScript = self.superScript {
            str.append("^{\(superScript.string)}")
        }
        if let subScript = self.subScript {
            str.append("_{\(subScript.string)}")
        }
        return str
    }
    
    // Fuse the given atom with this one by combining their nucleii.
    func fuse(with atom: MathAtom) {
        assert(self.subScript == nil, "Cannot fuse into an atom which has a subscript: \(self)");
        assert(self.superScript == nil, "Cannot fuse into an atom which has a superscript: \(self)");
        assert(atom.type == self.type, "Only atoms of the same type can be fused. \(self), \(atom)");
        guard self.subScript == nil, self.superScript == nil, self.type == atom.type
        else { return }
        
        // Update the fused atoms list
        if self.fusedAtoms.isEmpty {
            self.fusedAtoms.append(MathAtom(self))
        }
        if atom.fusedAtoms.count > 0 {
            self.fusedAtoms.append(contentsOf: atom.fusedAtoms)
        } else {
            self.fusedAtoms.append(atom)
        }
        
        // Update nucleus:
        self.nucleus += atom.nucleus
        
        // Update range:
        self.indexRange.length += atom.indexRange.length
        
        // Update super/subscript:
        self.superScript = atom.superScript
        self.subScript = atom.subScript
    }
    
    /** Returns true if this atom allows scripts (sub or super). */
    func isScriptAllowed() -> Bool { self.type.isScriptAllowed() }
    
    func isNotBinaryOperator() -> Bool { self.type.isNotBinaryOperator() }
    
}

func isNotBinaryOperator(_ prevNode:MathAtom?) -> Bool {
    guard let prevNode = prevNode else { return true }
    return prevNode.type.isNotBinaryOperator()
}

// MARK: - Fraction

public class Fraction: MathAtom {
    public var hasRule: Bool = true
    public var leftDelimiter = ""
    public var rightDelimiter = ""
    public var numerator: MathList?
    public var denominator: MathList?

    // Continued fraction properties
    public var isContinuedFraction: Bool = false
    public var alignment: String = "c"  // "l", "r", "c" for left, right, center
    
    init(_ frac: Fraction?) {
        super.init(frac)
        self.type = .fraction
        if let frac = frac {
            self.numerator = MathList(frac.numerator)
            self.denominator = MathList(frac.denominator)
            self.hasRule = frac.hasRule
            self.leftDelimiter = frac.leftDelimiter
            self.rightDelimiter = frac.rightDelimiter
            self.isContinuedFraction = frac.isContinuedFraction
            self.alignment = frac.alignment
        }
    }
    
    init(hasRule rule:Bool = true) {
        super.init()
        self.type = .fraction
        self.hasRule = rule
    }
    
    override public var description: String {
        var string = self.hasRule ? "\\frac" : "\\atop"
        if !self.leftDelimiter.isEmpty {
            string += "[\(self.leftDelimiter)]"
        }
        if !self.rightDelimiter.isEmpty {
            string += "[\(self.rightDelimiter)]"
        }
        string += "{\(self.numerator?.description ?? "placeholder")}{\(self.denominator?.description ?? "placeholder")}"
        if self.superScript != nil {
            string += "^{\(self.superScript!.description)}"
        }
        if self.subScript != nil {
            string += "_{\(self.subScript!.description)}"
        }
        return string
    }
    
    override public var finalized: MathAtom {
        let newFrac = super.finalized as! Fraction
        newFrac.numerator = newFrac.numerator?.finalized
        newFrac.denominator = newFrac.denominator?.finalized
        return newFrac
    }
    
}

// MARK: - Radical
/** An atom of type radical (square root). */
public class Radical: MathAtom {
    /// Denotes the term under the square root sign
    public var radicand:  MathList?
    
    /// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
    /// This can be null if there is no degree.
    public var degree:  MathList?
    
    init(_ rad:Radical?) {
        super.init(rad)
        self.type = .radical
        self.radicand = MathList(rad?.radicand)
        self.degree = MathList(rad?.degree)
        self.nucleus = ""
    }
    
    override init() {
        super.init()
        self.type = .radical
        self.nucleus = ""
    }
    
    override public var description: String {
        var string = "\\sqrt"
        if self.degree != nil {
            string += "[\(self.degree!.description)]"
        }
        if self.radicand != nil {
            string += "{\(self.radicand?.description ?? "placeholder")}"
        }
        if self.superScript != nil {
            string += "^{\(self.superScript!.description)}"
        }
        if self.subScript != nil {
            string += "_{\(self.subScript!.description)}"
        }
        return string
    }
    
    override public var finalized: MathAtom {
        let newRad = super.finalized as! Radical
        newRad.radicand = newRad.radicand?.finalized
        newRad.degree = newRad.degree?.finalized
        return newRad
    }
}

// MARK: - LargeOperator
/** A `MathAtom` of type `MathAtomType.largeOperator`. */
public class LargeOperator: MathAtom {
    
    /** Indicates whether the limits (if present) should be displayed
     above and below the operator in display mode.  If limits is false
     then the limits (if present) are displayed like a regular subscript/superscript.
     */
    public var limits: Bool = false
    
    init(_ op:LargeOperator?) {
        super.init(op)
        self.type = .largeOperator
        self.limits = op!.limits
    }
    
    init(value: String, limits: Bool) {
        super.init(type: .largeOperator, value: value)
        self.limits = limits
    }
}

// MARK: - Inner
/** An inner atom. This denotes an atom which contains a math list inside it. An inner atom
 has optional boundaries. Note: Only one boundary may be present, it is not required to have
 both. */
public class Inner: MathAtom {
    /// The inner math list
    public var innerList: MathList?
    /// The left boundary atom. This must be a node of type MathAtomType.boundary
    public var leftBoundary: MathAtom? {
        didSet {
            if let left = leftBoundary, left.type != .boundary {
                leftBoundary = nil
                NSException(name: NSExceptionName(rawValue: "Error"), reason: "Left boundary must be of type .boundary").raise()
            }
        }
    }
    /// The right boundary atom. This must be a node of type MathAtomType.boundary
    public var rightBoundary: MathAtom? {
        didSet {
            if let right = rightBoundary, right.type != .boundary {
                rightBoundary = nil
                NSException(name: NSExceptionName(rawValue: "Error"), reason: "Right boundary must be of type .boundary").raise()
            }
        }
    }

    /// Optional explicit delimiter height (in points). When set, this overrides the automatic
    /// delimiter sizing based on inner content. Used by \big, \Big, \bigg, \Bigg commands.
    public var delimiterHeight: CGFloat?

    init(_ inner:Inner?) {
        super.init(inner)
        self.type = .inner
        self.innerList = MathList(inner?.innerList)
        self.leftBoundary = MathAtom(inner?.leftBoundary)
        self.rightBoundary = MathAtom(inner?.rightBoundary)
        self.delimiterHeight = inner?.delimiterHeight
    }
    
    override init() {
        super.init()
        self.type = .inner
    }
    
    override public var description: String {
        var string = "\\inner"
        if self.leftBoundary != nil {
            string += "[\(self.leftBoundary!.nucleus)]"
        }
        string += "{\(self.innerList!.description)}"
        if self.rightBoundary != nil {
            string += "[\(self.rightBoundary!.nucleus)]"
        }
        if self.superScript != nil {
            string += "^{\(self.superScript!.description)}"
        }
        if self.subScript != nil {
            string += "_{\(self.subScript!.description)}"
        }
        return string
    }
    
    override public var finalized: MathAtom {
        let newInner = super.finalized as! Inner
        newInner.innerList = newInner.innerList?.finalized
        return newInner
    }
}

// MARK: - OverLine
/** An atom with a line over the contained math list. */
public class OverLine: MathAtom {
    public var innerList:  MathList?
    
    override public var finalized: MathAtom {
        let newOverline = OverLine(self)
        newOverline.innerList = newOverline.innerList?.finalized
        return newOverline
    }
    
    init(_ over: OverLine?) {
        super.init(over)
        self.type = .overline
        self.innerList = MathList(over!.innerList)
    }
    
    override init() {
        super.init()
        self.type = .overline
    }
}

// MARK: - UnderLine
/** An atom with a line under the contained math list. */
public class UnderLine: MathAtom {
    public var innerList:  MathList?
    
    override public var finalized: MathAtom {
        let newUnderline = super.finalized as! UnderLine
        newUnderline.innerList = newUnderline.innerList?.finalized
        return newUnderline
    }
    
    init(_ under: UnderLine?) {
        super.init(under)
        self.type = .underline
        self.innerList = MathList(under?.innerList)
    }
    
    override init() {
        super.init()
        self.type = .underline
    }
}

// MARK: - Accent

public class Accent: MathAtom {
    public var innerList:  MathList?
    /// Indicates if this accent should use stretchy arrow behavior (for \overrightarrow, etc.)
    /// vs short accent behavior (for \vec). Only applies to arrow accents.
    public var isStretchy: Bool = false
    /// Indicates if this accent should use wide stretching behavior (for \widehat, \widetilde)
    /// vs regular fixed-size accent behavior (for \hat, \tilde).
    public var isWide: Bool = false

    override public var finalized: MathAtom {
        let newAccent = super.finalized as! Accent
        newAccent.innerList = newAccent.innerList?.finalized
        newAccent.isStretchy = self.isStretchy
        newAccent.isWide = self.isWide
        return newAccent
    }

    init(_ accent: Accent?) {
        super.init(accent)
        self.type = .accent
        self.innerList = MathList(accent?.innerList)
        self.isStretchy = accent?.isStretchy ?? false
        self.isWide = accent?.isWide ?? false
    }

    init(value: String) {
        super.init()
        self.type = .accent
        self.nucleus = value
    }
}

// MARK: - MathSpace
/** An atom representing space.
 Note: None of the usual fields of the `MathAtom` apply even though this
 class inherits from `MathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
public class MathSpace: MathAtom {
    /** The amount of space represented by this object in mu units. */
    public var space: CGFloat = 0
    
    /// Creates a new `MathSpace` with the given spacing.
    /// - parameter space: The amount of space in mu units.
    init(_ space: MathSpace?) {
        super.init(space)
        self.type = .space
        self.space = space?.space ?? 0
    }
    
    init(space:CGFloat) {
        super.init()
        self.type = .space
        self.space = space
    }
}

/**
 Styling of a line of math
 */
public enum LineStyle:Int, Comparable {
    /// Display style
    case display
    /// Text style (inline)
    case text
    /// Script style (for sub/super scripts)
    case script
    /// Script script style (for scripts of scripts)
    case scriptOfScript
    
    public func inc() -> LineStyle {
        let raw = self.rawValue + 1
        if let style = LineStyle(rawValue: raw) { return style }
        return .display
    }
    
    public var isNotScript:Bool { self < .script }
    public static func < (lhs: LineStyle, rhs: LineStyle) -> Bool { lhs.rawValue < rhs.rawValue }
}

// MARK: - MathStyle
/** An atom representing a style change.
 Note: None of the usual fields of the `MathAtom` apply even though this
 class inherits from `MathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
public class MathStyle: MathAtom {
    public var style: LineStyle = .display
    
    init(_ style:MathStyle?) {
        super.init(style)
        self.type = .style
        self.style = style!.style
    }
    
    init(style:LineStyle) {
        super.init()
        self.type = .style
        self.style = style
    }
}

// MARK: - MathColorAtom
/** An atom representing an color element.
 Note: None of the usual fields of the `MathAtom` apply even though this
 class inherits from `MathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
public class MathColorAtom: MathAtom {
    public var colorString:String=""
    public var innerList:MathList?
    
    init(_ color: MathColorAtom?) {
        super.init(color)
        self.type = .color
        self.colorString = color?.colorString ?? ""
        self.innerList = MathList(color?.innerList)
    }
    
    override init() {
        super.init()
        self.type = .color
    }
    
    public override var string: String {
        "\\color{\(self.colorString)}{\(self.innerList!.string)}"
    }
    
    override public var finalized: MathAtom {
        let newColor = super.finalized as! MathColorAtom
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
}

// MARK: - MathTextColor
/** An atom representing an textcolor element.
 Note: None of the usual fields of the `MathAtom` apply even though this
 class inherits from `MathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
public class MathTextColor: MathAtom {
    public var colorString:String=""
    public var innerList:MathList?

    init(_ color: MathTextColor?) {
        super.init(color)
        self.type = .textcolor
        self.colorString = color?.colorString ?? ""
        self.innerList = MathList(color?.innerList)
    }

    override init() {
        super.init()
        self.type = .textcolor
    }

    public override var string: String {
        "\\textcolor{\(self.colorString)}{\(self.innerList!.string)}"
    }

    override public var finalized: MathAtom {
        let newColor = super.finalized as! MathTextColor
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
}

// MARK: - MathColorbox
/** An atom representing an colorbox element.
 Note: None of the usual fields of the `MathAtom` apply even though this
 class inherits from `MathAtom`. i.e. it is meaningless to have a value
 in the nucleus, subscript or superscript fields. */
public class MathColorbox: MathAtom {
    public var colorString=""
    public var innerList:MathList?
    
    init(_ cbox: MathColorbox?) {
        super.init(cbox)
        self.type = .colorBox
        self.colorString = cbox?.colorString ?? ""
        self.innerList = MathList(cbox?.innerList)
    }
    
    override init() {
        super.init()
        self.type = .colorBox
    }
    
    public override var string: String {
        "\\colorbox{\(self.colorString)}{\(self.innerList!.string)}"
    }
    
    override public var finalized: MathAtom {
        let newColor = super.finalized as! MathColorbox
        newColor.innerList = newColor.innerList?.finalized
        return newColor
    }
}

/**
    Alignment for a column of MathTable
 */
public enum ColumnAlignment {
    case left
    case center
    case right
}

// MARK: - MathTable
/** An atom representing an table element. This atom is not like other
 atoms and is not present in TeX. We use it to represent the `\halign` command
 in TeX with some simplifications. This is used for matrices, equation
 alignments and other uses of multiline environments.
 
 The cells in the table are represented as a two dimensional array of
 `MathList` objects. The `MathList`s could be empty to denote a missing
 value in the cell. Additionally an array of alignments indicates how each
 column will be aligned.
 */
public class MathTable: MathAtom {
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
        let table = super.finalized as! MathTable
        for var row in table.cells {
            for i in 0..<row.count {
                row[i] = row[i].finalized
            }
        }
        return table
    }
    
    init(environment: String?) {
        super.init()
        self.type = .table
        self.environment = environment ?? ""
    }
    
    init(_ table:MathTable) {
        super.init(table)
        self.type = .table
        self.alignments = table.alignments
        self.interRowAdditionalSpacing = table.interRowAdditionalSpacing
        self.interColumnSpacing = table.interColumnSpacing
        self.environment = table.environment
        var cellCopy = [[MathList]]()
        for row in table.cells {
            var newRow = [MathList]()
            for col in row {
                newRow.append(MathList(col)!)
            }
            cellCopy.append(newRow)
        }
        self.cells = cellCopy
    }
    
    override init() {
        super.init()
        self.type = .table
    }
    
    /// Set the value of a given cell. The table is automatically resized to contain this cell.
    public func set(cell list: MathList, forRow row:Int, column:Int) {
        if self.cells.count <= row {
            for _ in self.cells.count...row {
                self.cells.append([])
            }
        }
        let rows = self.cells[row].count
        if rows <= column {
            for _ in rows...column {
                self.cells[row].append(MathList())
            }
        }
        self.cells[row][column] = list
    }
    
    /// Set the alignment of a particular column. The table is automatically resized to
    /// contain this column and any new columns added have their alignment set to center.
    public func set(alignment: ColumnAlignment, forColumn col: Int) {
        if self.alignments.count <= col {
            for _ in self.alignments.count...col {
                self.alignments.append(ColumnAlignment.center)
            }
        }
        
        self.alignments[col] = alignment
    }
    
    /// Gets the alignment for a given column. If the alignment is not specified it defaults
    /// to center.
    public func get(alignmentForColumn col: Int) -> ColumnAlignment {
        if self.alignments.count <= col {
            return ColumnAlignment.center
        } else {
            return self.alignments[col]
        }
    }
    
    public var numColumns: Int {
        var numberOfCols = 0
        for row in self.cells {
            numberOfCols = max(numberOfCols, row.count)
        }
        return numberOfCols
    }
    
    public var numRows: Int { self.cells.count }
}

// MARK: - MathList

extension MathList {
    public override var description: String { self.atoms.description }
    /// converts the MathList to a string form. Note: This is not the LaTeX form.
    public var string: String { self.description }
}

/** A representation of a list of math objects.

    This list can be constructed directly or built with
    the help of the MathListBuilder. It is not required that the mathematics represented make sense
    (i.e. this can represent something like "x 2 = +". This list can be used for display using MathListDisplay
    or can be a list of tokens to be used by a parser after finalizedMathList is called.
 
    Note: This class is for **advanced** usage only.
 */
public class MathList : NSObject {
    
    init?(_ list:MathList?) {
        guard let list = list else { return nil }
        for atom in list.atoms {
            self.atoms.append(atom.copy())
        }
    }

    /// A list of MathAtoms
    public var atoms = [MathAtom]()
    
    /// Create a new math list as a final expression and update atoms
    /// by combining like atoms that occur together and converting unary operators to binary operators.
    /// This function does not modify the current MathList
    public var finalized: MathList {
        let finalizedList = MathList()
        let zeroRange = NSMakeRange(0, 0)
        
        var prevNode: MathAtom? = nil
        for atom in self.atoms {
            let newNode = atom.finalized
            
            if NSEqualRanges(zeroRange, atom.indexRange) {
                // CRITICAL FIX: Check if prevNode has a valid range location before using it
                // If location is NSNotFound, treat as if there's no prevNode
                // This prevents negative overflow when creating NSMakeRange
                let index: Int
                if prevNode == nil || prevNode!.indexRange.location == NSNotFound {
                    index = 0
                } else {
                    // Additional safety: check for potential overflow
                    let location = prevNode!.indexRange.location
                    let length = prevNode!.indexRange.length
                    // If either value is suspicious (negative or too large), reset to 0
                    if location < 0 || length < 0 || location > Int.max - length {
                        index = 0
                    } else {
                        index = location + length
                    }
                }
                newNode.indexRange = NSMakeRange(index, 1)
            }
            
            switch newNode.type {
            case .binaryOperator:
                if isNotBinaryOperator(prevNode)  {
                    newNode.type = .unaryOperator
                }
            case .relation, .punctuation, .close:
                if prevNode != nil && prevNode!.type == .binaryOperator {
                    prevNode!.type = .unaryOperator
                }
            case .number:
                if prevNode != nil && prevNode!.type == .number && prevNode!.subScript == nil && prevNode!.superScript == nil {
                    prevNode!.fuse(with: newNode)
                    continue // skip the current node, we are done here.
                }
            default: break
            }
            finalizedList.add(newNode)
            prevNode = newNode
        }
        if prevNode != nil && prevNode!.type == .binaryOperator {
            prevNode!.type = .unaryOperator
        }
        return finalizedList
    }
    
    public init(atoms: [MathAtom]) {
        self.atoms.append(contentsOf: atoms)
    }
    
    public init(atom: MathAtom) {
        self.atoms.append(atom)
    }
    
    public override init() { super.init() }
    
    func NSParamException(_ param:Any?) {
        if param == nil {
            NSException(name: NSExceptionName(rawValue: "Error"), reason: "Parameter cannot be nil").raise()
        }
    }
    
    func NSIndexException(_ array:[Any], index: Int) {
        guard !array.indices.contains(index) else { return }
        NSException(name: NSExceptionName(rawValue: "Error"), reason: "Index \(index) out of bounds").raise()
    }
    
    /// Add an atom to the end of the list.
    /// - parameter atom: The atom to be inserted. This cannot be `nil` and cannot have the type `MathAtomType.boundary`.
    /// - throws NSException if the atom is of type `MathAtomType.boundary`
    public func add(_ atom: MathAtom?) {
        guard let atom = atom else { return }
        if self.isAtomAllowed(atom) {
            self.atoms.append(atom)
        } else {
            NSException(name: NSExceptionName(rawValue: "Error"), reason: "Cannot add atom of type \(atom.type.rawValue) into mathlist").raise()
        }
    }
    
    /// Inserts an atom at the given index. If index is already occupied, the objects at index and beyond are
    /// shifted by adding 1 to their indices to make room. An insert to an `index` greater than the number of atoms
    /// is ignored.  Insertions of nil atoms is ignored.
    /// - parameter atom: The atom to be inserted. This cannot be `nil` and cannot have the type `MathAtomType.boundary`.
    /// - parameter index: The index where the atom is to be inserted. The index should be less than or equal to the
    ///  number of elements in the math list.
    /// - throws NSException if the atom is of type MathAtomType.boundary
    public func insert(_ atom: MathAtom?, at index: Int) {
        // NSParamException(atom)
        guard let atom = atom else { return }
        guard self.atoms.indices.contains(index) || index == self.atoms.endIndex else { return }
        // guard self.atoms.endIndex >= index else { NSIndexException(); return }
        if self.isAtomAllowed(atom) {
            // NSIndexException(self.atoms, index: index)
            self.atoms.insert(atom, at: index)
        } else {
            NSException(name: NSExceptionName(rawValue: "Error"), reason: "Cannot add atom of type \(atom.type.rawValue) into mathlist").raise()
        }
    }
    
    /// Append the given list to the end of the current list.
    /// - parameter list: The list to append.
    public func append(_ list: MathList?) {
        guard let list = list else { return }
        self.atoms += list.atoms
    }
    
    /** Removes the last atom from the math list. If there are no atoms in the list this does nothing. */
    public func removeLastAtom() {
        if !self.atoms.isEmpty {
            self.atoms.removeLast()
        }
    }
    
    /// Removes the atom at the given index.
    /// - parameter index: The index at which to remove the atom. Must be less than the number of atoms
    /// in the list.
    public func removeAtom(at index: Int) {
        NSIndexException(self.atoms, index:index)
        self.atoms.remove(at: index)
    }
    
    /** Removes all the atoms within the given range. */
    public func removeAtoms(in range: ClosedRange<Int>) {
        NSIndexException(self.atoms, index: range.lowerBound)
        NSIndexException(self.atoms, index: range.upperBound)
        self.atoms.removeSubrange(range)
    }
    
    func isAtomAllowed(_ atom: MathAtom?) -> Bool { atom?.type != .boundary }
}
