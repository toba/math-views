/// An atom of type radical (square root).
public final class Radical: MathAtom {
    /// Denotes the term under the square root sign
    public var radicand: MathList?

    /// Denotes the degree of the radical, i.e. the value to the top left of the radical sign
    /// This can be null if there is no degree.
    public var degree: MathList?

    init(_ source: Radical?) {
        super.init(source)
        type = .radical
        radicand = MathList(source?.radicand)
        degree = MathList(source?.degree)
        nucleus = ""
    }

    override init() {
        super.init()
        type = .radical
        nucleus = ""
    }

    override public var description: String {
        var string = "\\sqrt"
        if degree != nil { string += "[\(degree!.description)]" }
        if radicand != nil { string += "{\(radicand?.description ?? "placeholder")}" }
        if superScript != nil { string += "^{\(superScript!.description)}" }
        if subScript != nil { string += "_{\(subScript!.description)}" }
        return string
    }

    override public var finalized: MathAtom {
        guard let newRad = super.finalized as? Radical else { return super.finalized }
        newRad.radicand = newRad.radicand?.finalized
        newRad.degree = newRad.degree?.finalized
        return newRad
    }
}
