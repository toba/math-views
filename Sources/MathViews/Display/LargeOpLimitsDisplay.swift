import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// Renders a large operator (e.g. `\sum`, `\int`, `\prod`) with above/below limits in display style.
///
/// In display style, limits are stacked vertically above and below the operator nucleus,
/// centered horizontally and shifted by the operator's italic correction. The gaps between
/// the nucleus and limits are controlled by OpenType MATH metrics. In text style, limits
/// are rendered as regular superscripts/subscripts instead (handled by the typesetter before
/// this display is created).
final class LargeOpLimitsDisplay: Display {
  /// The rendered upper limit (e.g. `n` in `\sum_{i=0}^{n}`).
  /// Positioned relative to the parent, not as a sub-display.
  var upperLimit: MathListDisplay?
  /// The rendered lower limit (e.g. `i=0` in `\sum_{i=0}^{n}`).
  /// Positioned relative to the parent, not as a sub-display.
  var lowerLimit: MathListDisplay?

  /// Horizontal shift for limits, derived from the operator's italic correction.
  /// Upper limit shifts right, lower limit shifts left.
  var limitShift: CGFloat = 0
  /// Vertical gap between the nucleus ascent and the upper limit descent.
  var upperLimitGap: CGFloat = 0 { didSet { updateUpperLimitPosition() } }
  /// Vertical gap between the nucleus descent and the lower limit ascent.
  var lowerLimitGap: CGFloat = 0 { didSet { updateLowerLimitPosition() } }
  /// Extra vertical padding above/below the composite display (TeX's ξ₁₃).
  var extraPadding: CGFloat = 0

  /// The rendered operator glyph (e.g. the `∑` symbol).
  var nucleus: Display?

  init(
    nucleus: Display?,
    upperLimit: MathListDisplay?,
    lowerLimit: MathListDisplay?,
    limitShift: CGFloat,
    extraPadding: CGFloat,
  ) {
    super.init()
    self.upperLimit = upperLimit
    self.lowerLimit = lowerLimit
    self.nucleus = nucleus

    var maxWidth = max(nucleus!.width, upperLimit?.width ?? 0)
    maxWidth = max(maxWidth, lowerLimit?.width ?? 0)

    self.limitShift = limitShift
    upperLimitGap = 0
    lowerLimitGap = 0
    self.extraPadding = extraPadding  // corresponds to \xi_13 in TeX
    width = maxWidth
  }

  override var ascent: CGFloat {
    get {
      if upperLimit != nil {
        return nucleus!.ascent + extraPadding + upperLimit!.ascent + upperLimitGap
          + upperLimit!.descent
      } else {
        return nucleus!.ascent
      }
    }
    set { super.ascent = newValue }
  }

  override var descent: CGFloat {
    get {
      if lowerLimit != nil {
        return nucleus!.descent + extraPadding + lowerLimitGap + lowerLimit!.descent
          + lowerLimit!.ascent
      } else {
        return nucleus!.descent
      }
    }
    set { super.descent = newValue }
  }

  override var position: CGPoint {
    get { super.position }
    set {
      super.position = newValue
      updateLowerLimitPosition()
      updateUpperLimitPosition()
      updateNucleusPosition()
    }
  }

  func updateLowerLimitPosition() {
    if lowerLimit != nil {
      // The position of the lower limit includes the position of the LargeOpLimitsDisplay
      // This is to make the positioning of the radical consistent with fractions and radicals
      // Move the starting point to below the nucleus leaving a gap of _lowerLimitGap and subtract
      // the ascent to to get the baseline. Also center and shift it to the left by _limitShift.
      lowerLimit!.position = CGPoint(
        x: position.x - limitShift + (width - lowerLimit!.width) / 2,
        y: position.y - nucleus!.descent - lowerLimitGap - lowerLimit!.ascent,
      )
    }
  }

  func updateUpperLimitPosition() {
    if upperLimit != nil {
      // The position of the upper limit includes the position of the LargeOpLimitsDisplay
      // This is to make the positioning of the radical consistent with fractions and radicals
      // Move the starting point to above the nucleus leaving a gap of _upperLimitGap and add
      // the descent to to get the baseline. Also center and shift it to the right by _limitShift.
      upperLimit!.position = CGPoint(
        x: position.x + limitShift + (width - upperLimit!.width) / 2,
        y: position.y + nucleus!.ascent + upperLimitGap + upperLimit!.descent,
      )
    }
  }

  func updateNucleusPosition() {
    // Center the nucleus
    nucleus?.position = CGPoint(
      x:
        position.x + (width - nucleus!.width) / 2, y: position.y,
    )
  }

  override var textColor: PlatformColor? {
    get { super.textColor }
    set {
      super.textColor = newValue
      upperLimit?.textColor = newValue
      lowerLimit?.textColor = newValue
      nucleus?.textColor = newValue
    }
  }

  override func draw(_ context: CGContext) {
    super.draw(context)
    // Draw the elements.
    upperLimit?.draw(context)
    lowerLimit?.draw(context)
    nucleus?.draw(context)
  }
}
