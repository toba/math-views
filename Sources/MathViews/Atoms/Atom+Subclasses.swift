public import Foundation

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

  init(_ source: Fraction?) {
    super.init(source)
    type = .fraction
    if let source {
      numerator = MathList(source.numerator)
      denominator = MathList(source.denominator)
      hasRule = source.hasRule
      leftDelimiter = source.leftDelimiter
      rightDelimiter = source.rightDelimiter
      isContinuedFraction = source.isContinuedFraction
      alignment = source.alignment
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

  init(_ source: Radical?) {
    super.init(source)
    type = .radical
    radicand = MathList(source?.radicand)
    degree = MathList(source?.degree)
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

  init(_ source: LargeOperator?) {
    super.init(source)
    type = .largeOperator
    hasLimits = source!.hasLimits
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

  init(_ source: Inner?) {
    super.init(source)
    type = .inner
    innerList = MathList(source?.innerList)
    leftBoundary = MathAtom(source?.leftBoundary)
    rightBoundary = MathAtom(source?.rightBoundary)
    delimiterHeight = source?.delimiterHeight
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

  init(_ source: Overline?) {
    super.init(source)
    type = .overline
    innerList = MathList(source!.innerList)
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

  init(_ source: Underline?) {
    super.init(source)
    type = .underline
    innerList = MathList(source?.innerList)
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

  init(_ source: Accent?) {
    super.init(source)
    type = .accent
    innerList = MathList(source?.innerList)
    isStretchy = source?.isStretchy ?? false
    isWide = source?.isWide ?? false
  }

  init(value: String) {
    super.init()
    type = .accent
    nucleus = value
  }
}

// MARK: - OverBrace

/// An atom with a horizontal curly brace drawn over the contained math list.
///
/// The superscript (if present) is rendered as an annotation centered above the brace.
/// Produced by `\overbrace{x+y+z}^{3 \text{ terms}}`.
public final class OverBrace: MathAtom {
  /// The content under the brace.
  public var innerList: MathList?

  override public var finalized: MathAtom {
    let newAtom = OverBrace(self)
    newAtom.innerList = newAtom.innerList?.finalized
    return newAtom
  }

  init(_ source: OverBrace?) {
    super.init(source)
    type = .overbrace
    innerList = MathList(source?.innerList)
  }

  override init() {
    super.init()
    type = .overbrace
  }
}

// MARK: - UnderBrace

/// An atom with a horizontal curly brace drawn under the contained math list.
///
/// The subscript (if present) is rendered as an annotation centered below the brace.
/// Produced by `\underbrace{a+b+c}_{3 \text{ terms}}`.
public final class UnderBrace: MathAtom {
  /// The content above the brace.
  public var innerList: MathList?

  override public var finalized: MathAtom {
    let newAtom = UnderBrace(self)
    newAtom.innerList = newAtom.innerList?.finalized
    return newAtom
  }

  init(_ source: UnderBrace?) {
    super.init(source)
    type = .underbrace
    innerList = MathList(source?.innerList)
  }

  override init() {
    super.init()
    type = .underbrace
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
  init(_ source: MathSpace?) {
    super.init(source)
    type = .space
    self.space = source?.space ?? 0
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

  init(_ source: MathStyle?) {
    super.init(source)
    type = .style
    self.style = source!.style
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

  init(_ source: MathColorAtom?) {
    super.init(source)
    type = .color
    colorString = source?.colorString ?? ""
    innerList = MathList(source?.innerList)
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

  init(_ source: MathTextColor?) {
    super.init(source)
    type = .textColor
    colorString = source?.colorString ?? ""
    innerList = MathList(source?.innerList)
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

  init(_ source: MathColorBox?) {
    super.init(source)
    type = .colorBox
    colorString = source?.colorString ?? ""
    innerList = MathList(source?.innerList)
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
