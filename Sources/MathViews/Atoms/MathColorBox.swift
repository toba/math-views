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
