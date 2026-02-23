import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// Renders an extensible glyph assembled from multiple parts (e.g. tall delimiters, large braces).
///
/// When a single glyph variant isn't tall enough, the font's OpenType MATH table provides
/// an assembly recipe: top cap, bottom cap, optional mid section, and repeatable extender
/// pieces. This display draws all the assembled glyph parts at their computed vertical
/// offsets using `CTFontDrawGlyphs`. Supports vertical baseline shifting via ``ShiftableDisplay``.
final class GlyphConstructionDisplay: ShiftableDisplay {
  /// The glyph identifiers for each assembled piece.
  var glyphs = [CGGlyph]()
  /// Vertical offsets for each piece, stored as `CGPoint(x: 0, y: offset)`.
  var positions = [CGPoint]()
  /// The font instance providing the glyphs.
  var font: FontInstance?
  /// Number of glyph parts in the assembly.
  var numGlyphs: Int = 0

  init(glyphs: [CGGlyph], offsets: [CGFloat], font: FontInstance?) {
    super.init()
    assert(glyphs.count == offsets.count, "Glyphs and offsets need to match")
    numGlyphs = glyphs.count
    self.glyphs = glyphs
    positions = offsets.map { CGPoint(x: 0, y: $0) }
    self.font = font
    position = CGPoint.zero
  }

  override func draw(_ context: CGContext) {
    super.draw(context)
    context.saveGState()

    context.setFillColor(textColor?.cgColor ?? PlatformColor.black.cgColor)

    // Make the current position the origin as all the positions of the sub atoms are relative to the origin.
    context.translateBy(x: position.x, y: position.y - shiftDown)
    context.textPosition = CGPoint.zero

    // Draw the glyphs.
    CTFontDrawGlyphs(font!.coreTextFont, glyphs, positions, numGlyphs, context)

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
