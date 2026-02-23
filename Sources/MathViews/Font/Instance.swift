public import CoreGraphics
public import CoreText
import Foundation

/// A loaded math font at a specific point size, wrapping a Core Text `CTFont` with math-specific metrics.
///
/// `FontInstance` provides access to the font's glyph data and its ``FontMathTable`` —
/// the parsed OpenType MATH table containing constants for script positioning, fraction
/// layout, radical construction, and delimiter sizing.
///
/// Use ``withSize(_:)`` to create a copy at a different size (needed when the typesetter
/// switches to script or script-of-script style).
public final class FontInstance {
  let font: MathFont
  let size: CGFloat
  private let _graphicsFont: CGFont
  private let _coreTextFont: CTFont
  private let unitsPerEm: UInt
  private var _mathTable: FontMathTable?

  /// Fallback font for characters not supported by the main math font.
  /// Defaults to the system font at the same size. This is particularly useful
  /// for rendering text in \text{} commands with characters outside the math font's coverage
  /// (e.g., Chinese, Japanese, Korean, emoji, etc.)
  public var fallbackFont: CTFont?

  init(font: MathFont = .latinModern, size: CGFloat) {
    self.font = font
    self.size = size
    _graphicsFont = font.graphicsFont()
    _coreTextFont = font.coreTextFont(size: size)
    unitsPerEm = _coreTextFont.unitsPerEm
  }

  var defaultGraphicsFont: CGFont { _graphicsFont }
  var coreTextFont: CTFont { _coreTextFont }

  var mathTable: FontMathTable? {
    if _mathTable == nil {
      _mathTable = FontMathTable(mathFont: font, size: size, unitsPerEm: unitsPerEm)
    }
    return _mathTable
  }

  /// Returns a copy of this font but with a different size.
  public func withSize(_ size: CGFloat) -> FontInstance {
    FontInstance(font: font, size: size)
  }

  func glyphName(for glyph: CGGlyph) -> String {
    let name = defaultGraphicsFont.name(for: glyph) as? String
    return name ?? ""
  }

  func glyph(named name: String) -> CGGlyph {
    defaultGraphicsFont.getGlyphWithGlyphName(name: name as CFString)
  }

  /// The size of this font in points.
  public var fontSize: CGFloat { CTFontGetSize(coreTextFont) }
}
