import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// Renders a radical (square root / nth root) expression: `√` glyph + overbar + radicand + optional degree.
///
/// Layout from left to right: optional degree (e.g. the `n` in `\sqrt[n]{x}`),
/// the radical sign glyph, and the radicand content with a horizontal overbar.
/// The degree is positioned using OpenType MATH metrics for kern-before, kern-after,
/// and bottom-raise percentage.
final class RadicalDisplay: Display {
  /// The rendered content under the radical sign.
  /// Positioned relative to the parent, not as a sub-display.
  fileprivate(set) var radicand: MathListDisplay?
  /// The optional rendered degree (e.g. `3` in `\sqrt[3]{x}`).
  /// Positioned relative to the parent, not as a sub-display.
  fileprivate(set) var degree: MathListDisplay?

  override var position: CGPoint {
    get { super.position }
    set {
      super.position = newValue
      updateRadicandPosition()
    }
  }

  override var textColor: PlatformColor? {
    get { super.textColor }
    set {
      super.textColor = newValue
      radicand?.textColor = newValue
      degree?.textColor = newValue
    }
  }

  private var _radicalGlyph: Display?
  private var _radicalShift: CGFloat = 0

  /// Vertical gap between the top of the radicand and the overbar line.
  var topKern: CGFloat = 0
  /// Stroke width of the horizontal overbar line.
  var lineThickness: CGFloat = 0

  init(
    radicand: MathListDisplay?,
    glyph: Display,
    position: CGPoint,
    range: Range<Int>,
  ) {
    super.init()
    self.radicand = radicand
    _radicalGlyph = glyph
    _radicalShift = 0

    self.position = position
    self.range = range
  }

  /// Attaches a degree display (the `n` in `\sqrt[n]{x}`) and adjusts layout accordingly.
  ///
  /// Positions the degree using font metrics for kern-before-degree, kern-after-degree,
  /// and the bottom-raise percentage. Updates the total width to account for the degree.
  func setDegree(_ degree: MathListDisplay?, fontMetrics: FontMathTable?) {
    // sets up the degree of the radical
    var kernBefore = fontMetrics!.radicalKernBeforeDegree
    let kernAfter = fontMetrics!.radicalKernAfterDegree
    let raise = fontMetrics!.radicalDegreeBottomRaisePercent * (ascent - descent)

    // The layout is:
    // kernBefore, raise, degree, kernAfter, radical
    self.degree = degree

    // the radical is now shifted by kernBefore + degree.width + kernAfter
    _radicalShift = kernBefore + degree!.width + kernAfter
    if _radicalShift < 0 {
      // we can't have the radical shift backwards, so instead we increase the kernBefore such
      // that _radicalShift will be 0.
      kernBefore -= _radicalShift
      _radicalShift = 0
    }

    // Note: position of degree is relative to parent.
    self.degree!.position = CGPoint(x: position.x + kernBefore, y: position.y + raise)
    // Update the width by the _radicalShift
    width = _radicalShift + _radicalGlyph!.width + radicand!.width
    // update the position of the radicand
    updateRadicandPosition()
  }

  func updateRadicandPosition() {
    // The position of the radicand includes the position of the RadicalDisplay
    // This is to make the positioning of the radical consistent with fractions and
    // have the cursor position finding algorithm work correctly.
    // move the radicand by the width of the radical sign
    radicand!.position = CGPoint(
      x:
        position.x + _radicalShift + _radicalGlyph!.width, y: position.y,
    )
  }

  override func draw(_ context: CGContext) {
    super.draw(context)

    // draw the radicand & degree at its position
    radicand?.draw(context)
    degree?.draw(context)

    context.saveGState()
    let color = textColor?.cgColor ?? PlatformColor.black.cgColor
    context.setStrokeColor(color)
    context.setFillColor(color)

    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    context.translateBy(x: position.x + _radicalShift, y: position.y)
    context.textPosition = CGPoint.zero

    // Draw the glyph.
    _radicalGlyph?.draw(context)

    // Draw the VBOX
    // for the kern of, we don't need to draw anything.
    let heightFromTop = topKern

    // draw the horizontal line with the given thickness
    let lineStart = CGPoint(
      x:
        _radicalGlyph!.width,
      y: ascent - heightFromTop - lineThickness / 2,
    )

    // subtract half the line thickness to center the line
    let lineEnd = CGPoint(x: lineStart.x + radicand!.width, y: lineStart.y)
    context.setLineWidth(lineThickness)
    context.setLineCap(.round)
    context.move(to: lineStart)
    context.addLine(to: lineEnd)
    context.strokePath()

    context.restoreGState()
  }
}
