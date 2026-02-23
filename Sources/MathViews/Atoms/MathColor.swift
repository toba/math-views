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
