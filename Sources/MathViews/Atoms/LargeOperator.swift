/// A `MathAtom` of type `MathAtomType.largeOperator`.
public final class LargeOperator: MathAtom {
    /// Indicates whether the limits (if present) should be displayed
    /// above and below the operator in display mode. If limits is false
    /// then the limits (if present) are displayed like a regular subscript/superscript.
    public var hasLimits: Bool = false

    init(_ source: LargeOperator?) {
        super.init(source)
        type = .largeOperator
        hasLimits = source!.hasLimits
    }

    init(value: String, hasLimits: Bool) {
        super.init(type: .largeOperator, value: value)
        self.hasLimits = hasLimits
    }
}
