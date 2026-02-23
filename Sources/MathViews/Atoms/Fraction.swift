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
        if !leftDelimiter.isEmpty { string += "[\(leftDelimiter)]" }
        if !rightDelimiter.isEmpty { string += "[\(rightDelimiter)]" }
        string +=
            "{\(numerator?.description ?? "placeholder")}{\(denominator?.description ?? "placeholder")}"

        if superScript != nil { string += "^{\(superScript!.description)}" }
        if subScript != nil { string += "_{\(subScript!.description)}"
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
