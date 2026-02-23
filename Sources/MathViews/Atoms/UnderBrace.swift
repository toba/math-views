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
