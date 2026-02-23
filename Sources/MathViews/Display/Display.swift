public import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// A display that can be shifted vertically, used by glyphs that need baseline adjustment
/// (e.g. delimiters centered on the math axis).
protocol Shiftable {
  var shiftDown: CGFloat { get set }
}

/// The base class for a rendered math element, analogous to a `CALayer` in a view hierarchy.
///
/// Each `Display` node knows how to draw itself into a `CGContext` via Core Graphics.
/// The typesetter builds a tree of `Display` objects from a ``MathList``, positioning each
/// node relative to its parent. The tree is then drawn in a single pass.
///
/// Subclasses include ``CTLineDisplay`` (character sequences), ``MathListDisplay``
/// (container of sub-displays), and ``FractionDisplay`` (numerator + denominator + rule line).
public class Display {
  init() {}

  /// Draws itself in the given graphics context.
  public func draw(_ context: CGContext) {
    if localBackgroundColor != nil {
      context.saveGState()
      context.setBlendMode(.normal)
      context.setFillColor(localBackgroundColor!.cgColor)
      context.fill(displayBounds())
      context.restoreGState()
    }
  }

  /// Gets the bounding rectangle for the Display
  func displayBounds() -> CGRect {
    CGRect(
      x:
        position.x, y: position.y - descent, width: width,
      height: ascent + descent,
    )
  }

  /// The distance from the axis to the top of the display
  public var ascent: CGFloat = 0
  /// The distance from the axis to the bottom of the display
  public var descent: CGFloat = 0
  /// The width of the display
  public var width: CGFloat = 0
  /// Position of the display with respect to the parent view or display.
  var position = CGPoint.zero
  /// The range of characters supported by this item
  public var range = 0..<0
  /// Whether the display has a subscript/superscript following it.
  public var hasScript: Bool = false
  /// The text color for this display
  var textColor: PlatformColor?
  /// The local color, if the color was mutated local with the color command
  var localTextColor: PlatformColor?
  /// The background color for this display
  var localBackgroundColor: PlatformColor?
}

/// Base class for displays that support vertical baseline shifting via ``Shiftable``.
class ShiftableDisplay: Display, Shiftable {
  var shiftDown: CGFloat = 0
}
