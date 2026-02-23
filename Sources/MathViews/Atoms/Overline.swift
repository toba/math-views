/// An atom with a line over the contained math list.
public final class Overline: MathAtom {
    public var innerList: MathList?

    override public var finalized: MathAtom {
        let finalized = Overline(self)
        finalized.innerList = finalized.innerList?.finalized
        return finalized
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
