public import Foundation

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
        space = source?.space ?? 0
    }

    init(space: CGFloat) {
        super.init()
        type = .space
        self.space = space
    }
}
