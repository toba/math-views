public final class Accent: MathAtom {
    public var innerList: MathList?
    /// Indicates if this accent should use stretchy arrow behavior (for \overrightarrow, etc.)
    /// vs short accent behavior (for \vec). Only applies to arrow accents.
    public var isStretchy: Bool = false
    /// Indicates if this accent should use wide stretching behavior (for \widehat, \widetilde)
    /// vs regular fixed-size accent behavior (for \hat, \tilde).
    public var isWide: Bool = false

    override public var finalized: MathAtom {
        guard let newAccent = super.finalized as? Accent else { return super.finalized }
        newAccent.innerList = newAccent.innerList?.finalized
        newAccent.isStretchy = isStretchy
        newAccent.isWide = isWide
        return newAccent
    }

    init(_ source: Accent?) {
        super.init(source)
        type = .accent
        innerList = MathList(source?.innerList)
        isStretchy = source?.isStretchy ?? false
        isWide = source?.isWide ?? false
    }

    init(value: String) {
        super.init()
        type = .accent
        nucleus = value
    }
}
