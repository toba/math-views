/// An atom representing a style change.
/// Note: None of the usual fields of the `MathAtom` apply even though this
/// class inherits from `MathAtom`. i.e. it is meaningless to have a value
/// in the nucleus, subscript or superscript fields.
public final class MathStyle: MathAtom {
    public var style: LineStyle = .display

    init(_ source: MathStyle?) {
        super.init(source)
        type = .style
        style = source!.style
    }

    init(style: LineStyle) {
        super.init()
        type = .style
        self.style = style
    }
}
