import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// Renders an overline (`\overline{x}`) or underline (`\underline{x}`) decoration.
///
/// Draws the inner content and a horizontal rule line at a vertical offset determined
/// by OpenType MATH overbar/underbar metrics. The line position and thickness are set
/// by the typesetter based on the current style.
final class LineDisplay: Display {
  /// The rendered inner content that the line decorates.
  /// Positioned relative to the parent, not as a sub-display.
  var inner: MathListDisplay?
  /// Vertical offset of the line from the baseline (positive = above).
  var lineShiftUp: CGFloat = 0
  /// Stroke width of the horizontal rule line.
  var lineThickness: CGFloat = 0

  init(inner: MathListDisplay?, position: CGPoint, range: Range<Int>) {
    super.init()
    self.inner = inner

    self.position = position
    self.range = range
  }

  override var textColor: PlatformColor? {
    get { super.textColor }
    set {
      super.textColor = newValue
      inner?.textColor = newValue
    }
  }

  override var position: CGPoint {
    get { super.position }
    set {
      super.position = newValue
      updateInnerPosition()
    }
  }

  override func draw(_ context: CGContext) {
    super.draw(context)
    inner?.draw(context)

    context.saveGState()

    context.setStrokeColor(textColor?.cgColor ?? PlatformColor.black.cgColor)

    // draw the horizontal line
    let lineStart = CGPoint(x: position.x, y: position.y + lineShiftUp)
    let lineEnd = CGPoint(x: lineStart.x + inner!.width, y: lineStart.y)
    context.setLineWidth(lineThickness)
    context.move(to: lineStart)
    context.addLine(to: lineEnd)
    context.strokePath()

    context.restoreGState()
  }

  func updateInnerPosition() {
    inner?.position = CGPoint(x: position.x, y: position.y)
  }
}
