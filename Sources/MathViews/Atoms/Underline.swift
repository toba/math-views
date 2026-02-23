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
