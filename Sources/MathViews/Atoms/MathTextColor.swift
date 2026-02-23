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
