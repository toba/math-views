public import CoreGraphics
public import CoreText
public import Foundation
import Synchronization

public final class FontInstance: @unchecked Sendable {
    let font: MathFont
    let size: CGFloat
    private let _cgFont: CGFont
    private let _ctFont: CTFont
    private let unitsPerEm: UInt
    private let _mathTab = Mutex<FontMathTable?>(nil)

    /// Fallback font for characters not supported by the main math font.
    /// Defaults to the system font at the same size. This is particularly useful
    /// for rendering text in \text{} commands with characters outside the math font's coverage
    /// (e.g., Chinese, Japanese, Korean, emoji, etc.)
    public var fallbackFont: CTFont?

    init(font: MathFont = .latinModern, size: CGFloat) {
        self.font = font
        self.size = size
        _cgFont = font.cgFont()
        _ctFont = font.ctFont(size: size)
        unitsPerEm = _ctFont.unitsPerEm
    }

    var defaultCGFont: CGFont { _cgFont }
    var ctFont: CTFont { _ctFont }

    var mathTable: FontMathTable? {
        _mathTab.withLock { cached in
            if cached == nil {
                cached = FontMathTable(mathFont: font, size: size, unitsPerEm: unitsPerEm)
            }
            return cached
        }
    }

    /// Returns a copy of this font but with a different size.
    public func withSize(_ size: CGFloat) -> FontInstance {
        FontInstance(font: font, size: size)
    }

    func glyphName(for glyph: CGGlyph) -> String {
        let name = defaultCGFont.name(for: glyph) as? String
        return name ?? ""
    }

    func glyph(named name: String) -> CGGlyph {
        defaultCGFont.getGlyphWithGlyphName(name: name as CFString)
    }

    /// The size of this font in points.
    public var fontSize: CGFloat { CTFontGetSize(ctFont) }
}
