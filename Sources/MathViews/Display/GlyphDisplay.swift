import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// Renders a single glyph from a math font using `CTFontDrawGlyphs`.
///
/// Used for standalone glyphs such as delimiters, radical signs, and large operators
/// that are drawn as individual font glyphs rather than as attributed-string text runs.
/// Supports vertical baseline shifting (via ``ShiftableDisplay``) for centering on
/// the math axis, and horizontal scaling for stretchy arrows.
final class GlyphDisplay: ShiftableDisplay {
  /// The CoreGraphics glyph identifier to draw.
  var glyph: CGGlyph!
  /// The font instance providing the glyph and its metrics.
  var font: FontInstance?
  /// Horizontal scale factor for stretching glyphs (1.0 = no scaling).
  /// Applied via `CGContext.scaleBy` during drawing for stretchy arrows.
  var scaleX: CGFloat = 1.0

  init(glyph: CGGlyph, range: Range<Int>, font: FontInstance?) {
    super.init()
    self.font = font
    self.glyph = glyph

    position = CGPoint.zero
    self.range = range
  }

  override func draw(_ context: CGContext) {
    super.draw(context)
    context.saveGState()

    context.setFillColor(textColor?.cgColor ?? PlatformColor.black.cgColor)

    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    context.translateBy(x: position.x, y: position.y - shiftDown)

    // Apply horizontal scaling if needed (for stretchy arrows)
    if scaleX != 1.0 { context.scaleBy(x: scaleX, y: 1.0) }

    context.textPosition = CGPoint.zero

    var pos = CGPoint.zero
    CTFontDrawGlyphs(font!.coreTextFont, &glyph, &pos, 1, context)

    context.restoreGState()
  }

  override var ascent: CGFloat {
    get { super.ascent - shiftDown }
    set { super.ascent = newValue }
  }

  override var descent: CGFloat {
    get { super.descent + shiftDown }
    set { super.descent = newValue }
  }
}
