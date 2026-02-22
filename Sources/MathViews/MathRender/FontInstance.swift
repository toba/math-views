public import Foundation
public import CoreGraphics
public import CoreText

public final class FontInstance {
    let font: MathFont
    let size: CGFloat
    private let _cgFont: CGFont
    private let _ctFont: CTFont
    private let unitsPerEm: UInt
    private var _mathTab: FontMathTable?
    private let mathTableLock = NSLock()

    /// Fallback font for characters not supported by the main math font.
    /// Defaults to the system font at the same size. This is particularly useful
    /// for rendering text in \text{} commands with characters outside the math font's coverage
    /// (e.g., Chinese, Japanese, Korean, emoji, etc.)
    public var fallbackFont: CTFont?

    init(font: MathFont = .latinModernFont, size: CGFloat) {
        self.font = font
        self.size = size
        self._cgFont = font.cgFont()
        self._ctFont = font.ctFont(withSize: size)
        self.unitsPerEm = self._ctFont.unitsPerEm
    }

    var defaultCGFont: CGFont { _cgFont }
    var ctFont: CTFont { _ctFont }

    var mathTable: FontMathTable? {
        guard _mathTab == nil else { return _mathTab }
        mathTableLock.lock()
        defer { mathTableLock.unlock() }
        if _mathTab == nil {
            _mathTab = FontMathTable(mathFont: font, size: size, unitsPerEm: unitsPerEm)
        }
        return _mathTab
    }

    /** Returns a copy of this font but with a different size. */
    public func copy(withSize size: CGFloat) -> FontInstance {
        FontInstance(font: font, size: size)
    }

    func get(nameForGlyph glyph: CGGlyph) -> String {
        let name = defaultCGFont.name(for: glyph) as? String
        return name ?? ""
    }

    func get(glyphWithName name: String) -> CGGlyph {
        defaultCGFont.getGlyphWithGlyphName(name: name as CFString)
    }

    /** The size of this font in points. */
    public var fontSize: CGFloat { CTFontGetSize(self.ctFont) }
}
