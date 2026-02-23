import Foundation

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
