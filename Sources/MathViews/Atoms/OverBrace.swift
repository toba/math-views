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
