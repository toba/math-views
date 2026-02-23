public import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A container display that holds an array of child ``Display`` objects, similar to a view hierarchy.
///
/// Each child is positioned relative to this display's origin. The container computes its
/// own ascent, descent, and width from the union of its children's bounds.
public final class MathListDisplay: Display {
    ///     The type of position for a line, i.e. subscript/superscript or regular.
    public enum LinePosition: Int {
        /// Regular
        case regular
        /// Positioned at a subscript
        case `subscript`
        /// Positioned at a superscript
        case superscript
    }

    /// Where the line is positioned
    public var type: LinePosition = .regular
    /// An array of displays which are positioned relative to the position of the
    /// the current display.
    public fileprivate(set) var subDisplays = [Display]()
    /// If a subscript or superscript this denotes the location in the parent MathList.
    /// `nil` for regular (non-script) lists.
    public var index: Int?

    init(displays: [Display], range: Range<Int>) {
        super.init()
        subDisplays = displays
        position = CGPoint.zero
        type = .regular
        index = nil
        self.range = range
        recomputeDimensions()
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            for displayAtom in subDisplays {
                displayAtom.textColor =
                    displayAtom.localTextColor == nil
                        ? newValue
                        : displayAtom.localTextColor
            }
        }
    }

    override public func draw(_ context: CGContext) {
        super.draw(context)
        context.saveGState()

        // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
        context.translateBy(x: position.x, y: position.y)
        context.textPosition = CGPoint.zero

        // draw each atom separately
        for displayAtom in subDisplays { displayAtom.draw(context) }

        context.restoreGState()
    }

    func recomputeDimensions() {
        var maxAscent: CGFloat = 0
        var maxDescent: CGFloat = 0
        var maxWidth: CGFloat = 0

        for atom in subDisplays {
            let ascent = max(0, atom.position.y + atom.ascent)
            if ascent > maxAscent { maxAscent = ascent }

            let descent = max(0, 0 - (atom.position.y - atom.descent))
            if descent > maxDescent { maxDescent = descent }

            let width = atom.width + atom.position.x
            if width > maxWidth { maxWidth = width }
        }
        ascent = maxAscent
        descent = maxDescent
        width = maxWidth
    }
}
