public import Foundation

/// An inner atom. This denotes an atom which contains a math list inside it. An inner atom
/// has optional boundaries. Note: Only one boundary may be present, it is not required to have
/// both.
public final class Inner: MathAtom {
    /// The inner math list
    public var innerList: MathList?
    /// The left boundary atom. This must be a node of type MathAtomType.boundary
    public var leftBoundary: MathAtom? {
        didSet {
            if let left = leftBoundary, left.type != .boundary {
                leftBoundary = nil
                preconditionFailure("Left boundary must be of type .boundary")
            }
        }
    }

    /// The right boundary atom. This must be a node of type MathAtomType.boundary
    public var rightBoundary: MathAtom? {
        didSet {
            if let right = rightBoundary, right.type != .boundary {
                rightBoundary = nil
                preconditionFailure("Right boundary must be of type .boundary")
            }
        }
    }

    /// Optional explicit delimiter height (in points). When set, this overrides the automatic
    /// delimiter sizing based on inner content. Used by \big, \Big, \bigg, \Bigg commands.
    public var delimiterHeight: CGFloat?

    init(_ source: Inner?) {
        super.init(source)
        type = .inner
        innerList = MathList(source?.innerList)
        leftBoundary = MathAtom(source?.leftBoundary)
        rightBoundary = MathAtom(source?.rightBoundary)
        delimiterHeight = source?.delimiterHeight
    }

    override init() {
        super.init()
        type = .inner
    }

    override public var description: String {
        var string = "\\inner"
        if leftBoundary != nil { string += "[\(leftBoundary!.nucleus)]" }
        string += "{\(innerList!.description)}"
        if rightBoundary != nil { string += "[\(rightBoundary!.nucleus)]" }
        if superScript != nil { string += "^{\(superScript!.description)}" }
        if subScript != nil { string += "_{\(subScript!.description)}" }
        return string
    }

    override public var finalized: MathAtom {
        guard let newInner = super.finalized as? Inner else { return super.finalized }
        newInner.innerList = newInner.innerList?.finalized
        return newInner
    }
}
