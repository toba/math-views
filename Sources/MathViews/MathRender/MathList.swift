public import Foundation

/// The type of atom in a ``MathList``.
///
/// Each atom type maps to a TeX category that controls both rendering and the spacing
/// inserted between adjacent atoms (the "inter-element spacing matrix").
/// See <doc:RenderingPipeline> for how atom types flow through the pipeline.
public enum MathAtomType: Int, CustomStringConvertible, Comparable, Sendable {
    /// An ordinary symbol with no special spacing — letters, digits, and miscellaneous
    /// symbols that don't fit another category. TeX's *Ord* class.
    case ordinary = 1
    /// A numeric digit (`0`–`9` and `.`). Not a native TeX category — MathViews
    /// distinguishes numbers so the finalizer can fuse adjacent digits (e.g. "1" + "2" → "12").
    case number
    /// A variable rendered in italic by default. Not a native TeX category — MathViews
    /// separates variables from ordinary atoms so font-style commands like `\mathbf` apply correctly.
    case variable
    /// A large operator like `∑` (sum), `∫` (integral), or named functions (`\sin`, `\cos`).
    /// In TeX these are *Op* atoms. In display mode they render larger and can have
    /// limits placed above and below rather than as sub/superscripts.
    case largeOperator
    /// A binary operator such as `+`, `−`, `×`, `∪`. TeX's *Bin* class.
    /// Medium spacing is inserted on both sides (except in script styles).
    /// The finalizer reclassifies leading or trailing binary operators as ``unaryOperator``.
    case binaryOperator
    /// A unary operator — a binary operator that was reclassified during finalization
    /// because it appeared at the start of a list or after an open delimiter. For example,
    /// the `−` in `−x` is unary, not binary. Does not exist in TeX's original grammar.
    case unaryOperator
    /// A relation symbol such as `=`, `<`, `>`, `≤`, `≥`, `≠`. TeX's *Rel* class.
    /// Thick spacing is inserted on both sides (except in script styles).
    case relation
    /// An opening delimiter: `(`, `[`, `{`, `⟨`. TeX's *Open* class.
    /// No spacing after an open delimiter.
    case open
    /// A closing delimiter: `)`, `]`, `}`, `⟩`. TeX's *Close* class.
    /// No spacing before a close delimiter.
    case close
    /// A fraction with numerator and denominator, optionally separated by a rule line.
    /// TeX's generalized fraction node. Covers `\frac`, `\over`, `\atop`, `\choose`, `\binom`.
    case fraction
    /// A radical (root) symbol, e.g. `\sqrt{2}` or `\sqrt[3]{x}`.
    /// Contains a radicand (the expression under the root) and an optional degree.
    case radical
    /// Punctuation such as commas and semicolons. TeX's *Punct* class.
    /// Thin spacing is inserted after punctuation.
    case punctuation
    /// A placeholder square (`■`) for interactive editing — marks where the user can type.
    /// Does not exist in TeX.
    case placeholder
    /// An inner atom containing a nested ``MathList``, with optional left and right
    /// boundary delimiters. TeX's *Inner* class. Produced by `\left...\right` grouping.
    case inner
    /// An atom with a horizontal line drawn under the contained math list.
    /// Produced by `\underline{...}`. TeX's *Under* class.
    case underline
    /// An atom with a horizontal line drawn over the contained math list.
    /// Produced by `\overline{...}`. TeX's *Over* class.
    case overline
    /// An accented atom — a combining accent mark placed above or below the base.
    /// Produced by commands like `\hat`, `\bar`, `\vec`, `\tilde`. TeX's *Accent* class.
    case accent

    // Atoms after this point do not support subscripts or superscripts

    /// A boundary delimiter used internally by ``Inner`` atoms.
    /// Represents the `\left` and `\right` delimiters. Not rendered independently.
    case boundary = 101

    // Atoms after this are non-math TeX nodes that are still useful in math mode. They do not have
    // the usual structure.

    /// Explicit spacing between atoms, measured in mu units (1 mu = 1/18 em).
    /// Produced by commands like `\quad` (18 mu), `\,` (3 mu), `\!` (−3 mu).
    /// Represents both TeX *glue* and *kern* — MathViews does not distinguish between them.
    case space = 201

    /// A style-change command that switches the math style for subsequent atoms.
    /// Produced by `\displaystyle`, `\textstyle`, `\scriptstyle`, `\scriptscriptstyle`.
    case style
    /// A color command that sets both text and background color for its inner list.
    case color
    /// A text-color command (`\textcolor{color}{content}`) that colors only the text.
    case textColor
    /// A background-color command (`\colorbox{color}{content}`) that fills behind the text.
    case colorBox

    // Atoms after this point are not part of TeX and do not have the usual structure.

    /// A table (matrix or alignment environment). Not a native TeX atom — in TeX, tables
    /// are handled by `\halign` outside the math engine. MathViews brings them into the
    /// typesetting pipeline to support `matrix`, `pmatrix`, `eqalign`, `cases`, etc.
    case table = 1001

    func isBinaryOperator() -> Bool {
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

/// The font style applied to a character when rendering.
///
/// Font style only affects atoms of type ``MathAtomType/variable`` and ``MathAtomType/number``.
/// Other atom types ignore this property. The typesetter maps each style to a Unicode
/// Mathematical Alphanumeric Symbols block offset (see ``UnicodeSymbol``) to select the
/// correct glyph from the font.
public enum FontStyle: Int, Sendable {
    /// The default LaTeX rendering style: variables are italic, numbers are roman (upright).
    case defaultStyle = 0
    /// Upright (roman) style. LaTeX: `\mathrm{x}` renders *x* upright.
    case roman
    /// Bold style. LaTeX: `\mathbf{x}` renders **x** in bold upright.
    case bold
    /// Calligraphic (script) style. LaTeX: `\mathcal{A}` renders 𝒜.
    /// Only available for uppercase Latin letters in most fonts.
    case calligraphic
    /// Typewriter (monospace) style. LaTeX: `\mathtt{x}` renders x in monospace.
    case typewriter
    /// Explicit italic style. LaTeX: `\mathit{x}`. Unlike ``defaultStyle``, this applies
    /// italic to all characters including digits and multi-letter sequences.
    case italic
    /// Sans-serif style. LaTeX: `\mathsf{x}` renders x in sans-serif.
    case sansSerif
    /// Fraktur (blackletter) style. LaTeX: `\mathfrak{x}` renders 𝔵.
    case fraktur
    /// Blackboard bold (double-struck) style. LaTeX: `\mathbb{R}` renders ℝ.
    case blackboard
    /// Bold italic style. LaTeX: `\boldsymbol{x}` or `\bm{x}` renders ***x***.
    case boldItalic
}

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

    public var latexString: String {
        var str = nucleus
        if let superScript {
            str.append("^{\(superScript.latexString)}")
        }
        if let subScript {
            str.append("_{\(subScript.latexString)}")
        }
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
        indexRange =
            indexRange.lowerBound ..< (indexRange.upperBound + atom.indexRange.count)

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

// MARK: - Fraction

/// A fraction atom representing `\frac{numerator}{denominator}` and related constructs.
///
/// - ``hasRule`` controls whether a horizontal line separates numerator and denominator.
///   `\frac` sets this to `true`; `\atop` and `\choose` set it to `false`.
/// - ``leftDelimiter`` and ``rightDelimiter`` add enclosing delimiters.
///   `\choose` sets these to `(` and `)`, `\binom` does the same.
///   `\brack` uses `[` and `]`, `\brace` uses `{` and `}`.
/// - ``isContinuedFraction`` marks `\cfrac` fractions which render with
///   display-style numerators and adjusted alignment.
public final class Fraction: MathAtom {
    /// Whether to draw the fraction rule line between numerator and denominator.
    /// `true` for `\frac` and `\over`; `false` for `\atop`, `\choose`, `\binom`.
    public var hasRule: Bool = true
    /// Optional left delimiter string (e.g. `"("` for `\choose`).
    public var leftDelimiter = ""
    /// Optional right delimiter string (e.g. `")"` for `\choose`).
    public var rightDelimiter = ""
    /// The math list above the fraction line (or above the gap for no-rule fractions).
    public var numerator: MathList?
    /// The math list below the fraction line.
    public var denominator: MathList?

    /// Whether this is a continued fraction (`\cfrac`), which renders the numerator
    /// in display style and supports left/right/center alignment.
    public var isContinuedFraction: Bool = false
    /// Alignment for continued fractions: `"l"` (left), `"r"` (right), or `"c"` (center).
    public var alignment: String = "c"

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
    public var hasLimits: Bool = false

    init(_ op: LargeOperator?) {
        super.init(op)
        type = .largeOperator
        hasLimits = op!.hasLimits
    }

    init(value: String, hasLimits: Bool) {
        super.init(type: .largeOperator, value: value)
        self.hasLimits = hasLimits
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

// MARK: - Overline

/// An atom with a line over the contained math list.
public final class Overline: MathAtom {
    public var innerList: MathList?

    override public var finalized: MathAtom {
        let newOverline = Overline(self)
        newOverline.innerList = newOverline.innerList?.finalized
        return newOverline
    }

    init(_ over: Overline?) {
        super.init(over)
        type = .overline
        innerList = MathList(over!.innerList)
    }

    override init() {
        super.init()
        type = .overline
    }
}

// MARK: - Underline

/// An atom with a line under the contained math list.
public final class Underline: MathAtom {
    public var innerList: MathList?

    override public var finalized: MathAtom {
        guard let newUnderline = super.finalized as? Underline else { return super.finalized }
        newUnderline.innerList = newUnderline.innerList?.finalized
        return newUnderline
    }

    init(_ under: Underline?) {
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

/// Explicit horizontal spacing between atoms, measured in mu units.
///
/// One mu ("math unit") equals 1/18 of an em, so spacing scales automatically with
/// font size. Common LaTeX spacing commands and their mu values:
/// - `\!` = −3 mu (negative thin space)
/// - `\,` = 3 mu (thin space)
/// - `\:` or `\>` = 4 mu (medium space)
/// - `\;` = 5 mu (thick space)
/// - `\quad` = 18 mu (1 em)
/// - `\qquad` = 36 mu (2 em)
///
/// > Note: The usual ``MathAtom`` fields (nucleus, subscript, superscript) are
/// > meaningless on this subclass — only ``space`` is used.
public final class MathSpace: MathAtom {
    /// The amount of space in mu units (1 mu = 1/18 em). Negative values pull atoms closer.
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

/// The TeX math style that controls sizing and layout of math content.
///
/// Despite the name, this is *not* about visual line styling (solid, dashed, etc.) — it's
/// TeX's concept of "math style" which determines how large atoms render. Each level
/// renders progressively smaller. The typesetter automatically steps down one level for
/// fraction numerators/denominators and for sub/superscripts.
public enum LineStyle: Int, Comparable, Sendable {
    /// Display style — the largest, used for standalone equations (`$$...$$`).
    /// Large operators render at full size with limits above/below.
    case display
    /// Text style — used for inline math (`$...$`).
    /// Large operators render smaller with limits as sub/superscripts.
    case text
    /// Script style — used for first-level sub/superscripts.
    /// Content renders at roughly 70% of text size.
    case script
    /// Script-of-script style — used for nested scripts (e.g. superscript of a superscript).
    /// The smallest level, roughly 50% of text size.
    case scriptOfScript

    public func incremented() -> LineStyle {
        let raw = rawValue + 1
        if let style = LineStyle(rawValue: raw) { return style }
        return .display
    }

    public var isAboveScript: Bool { self < .script }
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

    override public var latexString: String {
        "\\color{\(colorString)}{\(innerList!.latexString)}"
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

    override public var latexString: String {
        "\\textcolor{\(colorString)}{\(innerList!.latexString)}"
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
public final class MathColorBox: MathAtom {
    public var colorString = ""
    public var innerList: MathList?

    init(_ colorBox: MathColorBox?) {
        super.init(colorBox)
        type = .colorBox
        colorString = colorBox?.colorString ?? ""
        innerList = MathList(colorBox?.innerList)
    }

    override init() {
        super.init()
        type = .colorBox
    }

    override public var latexString: String {
        "\\colorbox{\(colorString)}{\(innerList!.latexString)}"
    }

    override public var finalized: MathAtom {
        guard let newColor = super.finalized as? MathColorBox else { return super.finalized }
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

/// A table or matrix environment such as `matrix`, `pmatrix`, `eqalign`, `cases`, or `split`.
///
/// Not a native TeX atom — in TeX, tables are handled by `\halign` outside the math engine.
/// MathViews brings them into the typesetting pipeline for convenience.
///
/// Cells are stored as a two-dimensional array of ``MathList`` objects. Empty lists represent
/// missing values. Column alignment defaults to center if not explicitly set.
///
/// The ``environment`` property records which LaTeX environment created this table,
/// controlling its visual style (e.g. `matrix` environments add `\textstyle` to each cell;
/// `pmatrix` wraps the table in parentheses via an ``Inner`` atom).
public final class MathTable: MathAtom {
    /// Per-column alignment (left, right, center). Defaults to center for unset columns.
    public var alignments = [ColumnAlignment]()
    /// The cells as a two-dimensional array indexed `[row][column]`.
    public var cells = [[MathList]]()
    /// The LaTeX environment name (e.g. `"matrix"`, `"eqalign"`, `"cases"`).
    public var environment = ""
    /// Horizontal spacing between columns in mu units (1 mu = 1/18 em).
    /// `matrix` environments use 18 mu (= 1 em); alignment environments use 0.
    public var interColumnSpacing: CGFloat = 0
    /// Extra vertical spacing between rows in jots (1 jot = 0.3 × font size).
    /// Zero means only the natural row height is used; `eqalign` environments use 1 jot.
    public var interRowAdditionalSpacing: CGFloat = 0

    override public var finalized: MathAtom {
        guard let table = super.finalized as? MathTable else { return super.finalized }
        for rowIndex in table.cells.indices {
            for colIndex in table.cells[rowIndex].indices {
                table.cells[rowIndex][colIndex] = table.cells[rowIndex][colIndex].finalized
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
    public func setCell(_ list: MathList, row: Int, column: Int) {
        if cells.count <= row {
            for _ in cells.count ... row { cells.append([]) }
        }
        let rows = cells[row].count
        if rows <= column {
            for _ in rows ... column { cells[row].append(MathList()) }
        }
        cells[row][column] = list
    }

    /// Set the alignment of a particular column. The table is automatically resized to
    /// contain this column and any new columns added have their alignment set to center.
    public func setAlignment(_ alignment: ColumnAlignment, forColumn col: Int) {
        if alignments.count <= col {
            for _ in alignments.count ... col {
                alignments.append(ColumnAlignment.center)
            }
        }

        alignments[col] = alignment
    }

    /// Gets the alignment for a given column. If the alignment is not specified it defaults
    /// to center.
    public func alignment(forColumn col: Int) -> ColumnAlignment {
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
