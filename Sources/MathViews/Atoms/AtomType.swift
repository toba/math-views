import Foundation

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
  /// A horizontal curly brace drawn over the contained math list, with an optional
  /// annotation above the brace (attached as a superscript). Produced by `\overbrace{...}^{...}`.
  case overbrace
  /// A horizontal curly brace drawn under the contained math list, with an optional
  /// annotation below the brace (attached as a subscript). Produced by `\underbrace{...}_{...}`.
  case underbrace

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
    case .overbrace: return "Overbrace"
    case .underbrace: return "Underbrace"
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
