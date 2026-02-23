#if os(iOS) || os(visionOS)
  public import UIKit
#elseif os(macOS)
  public import AppKit
#endif

/// The bundled OpenType math fonts available for rendering.
///
/// Each case corresponds to a `.otf` font file and companion `.plist` (math metrics) in the
/// package bundle. These are full OpenType math fonts with MATH tables — they contain glyph
/// variants, construction recipes, and spacing constants that regular text fonts lack.
///
/// Use ``fontInstance(size:)`` to create a ``FontInstance`` at a specific point size.
public enum MathFont: String, CaseIterable, Identifiable, Sendable {
  public var id: Self { self }

  /// Computer Modern derivative — the classic LaTeX look. Default font. Origin: GUST.
  case latinModern = "latinmodern-math"
  /// STIX-based serif font with broad Unicode math coverage. Origin: Khaled Hosny.
  case xits = "xits-math"
  /// Times-like serif font. Origin: GUST (TeX Gyre project).
  case termes = "texgyretermes-math"
  /// Sans-serif math font. Origin: Google (Noto project).
  case notoSans = "NotoSansMath-Regular"
  /// Libertine-based serif font. Origin: Libertinus project.
  case libertinus = "LibertinusMath-Regular"
  /// Garamond-style serif font. Origin: Yuansheng Zhao.
  case garamond = "Garamond-Math"

  var fontFamilyName: String {
    switch self {
    case .latinModern: "Latin Modern Math"
    case .xits: "XITS Math"
    case .termes: "TeX Gyre Termes Math"
    case .notoSans: "Noto Sans Math"
    case .libertinus: "Libertinus Math"
    case .garamond: "Garamond-Math"
    }
  }

  var postScriptName: String {
    switch self {
    case .latinModern: "LatinModernMath-Regular"
    case .xits: "XITSMath"
    case .termes: "TeXGyreTermesMath-Regular"
    case .notoSans: "NotoSansMath-Regular"
    case .libertinus: "LibertinusMath-Regular"
    case .garamond: "Garamond-Math"
    }
  }

  var fontName: String { rawValue }

  public func graphicsFont() -> CGFont {
    BundleManager.manager.obtainGraphicsFont(font: self)
  }

  public func coreTextFont(size: CGFloat) -> CTFont {
    BundleManager.manager.obtainCoreTextFont(font: self, size: size)
  }

  func rawMathTable() -> [String: Any] {
    BundleManager.manager.obtainRawMathTable(font: self)
  }

  public func fontInstance(size: CGFloat) -> FontInstance {
    FontInstance(font: self, size: size)
  }
}

extension CTFont {
  /// The size of this font in points.
  var fontSize: CGFloat {
    CTFontGetSize(self)
  }

  var unitsPerEm: UInt {
    UInt(CTFontGetUnitsPerEm(self))
  }
}

@MainActor private final class BundleManager {
  static let manager = BundleManager()

  private var graphicsFonts = [MathFont: CGFont]()
  private var coreTextFonts = [FontSizePair: CTFont]()
  private var rawMathTables = [MathFont: [String: Any]]()

  private static func loadGraphicsFont(mathFont: MathFont) throws(FontError) -> CGFont {
    guard
      let frameworkBundleURL = Bundle.module.url(
        forResource: "mathFonts",
        withExtension: "bundle",
      ),
      let fontURL = Bundle(url: frameworkBundleURL)?.url(
        forResource: mathFont.rawValue, withExtension: "otf",
      )
    else {
      throw FontError.fontPathNotFound
    }

    guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) else {
      throw FontError.registerFailed
    }

    guard let fontData = try? Data(contentsOf: fontURL),
      let dataProvider = CGDataProvider(data: fontData as CFData),
      let graphicsFont = CGFont(dataProvider)
    else {
      throw FontError.initFontError
    }
    return graphicsFont
  }

  private static func loadMathTable(mathFont: MathFont) throws(FontError) -> [String: Any] {
    guard
      let frameworkBundleURL = Bundle.module.url(
        forResource: "mathFonts",
        withExtension: "bundle",
      ),
      let mathTablePlist = Bundle(url: frameworkBundleURL)?.url(
        forResource: mathFont.rawValue, withExtension: "plist",
      )
    else {
      throw FontError.fontPathNotFound
    }
    guard let plistData = try? Data(contentsOf: mathTablePlist),
      let plist =
        (try? PropertyListSerialization.propertyList(
          from: plistData, format: nil,
        )) as? [String: Any],
      let version = plist["version"] as? String,
      version == "1.3"
    else {
      throw FontError.invalidMathTable
    }

    return plist
  }

  private func onDemandRegistration(mathFont: MathFont) {
    guard graphicsFonts[mathFont] == nil else { return }

    do {
      let graphicsFont = try Self.loadGraphicsFont(mathFont: mathFont)
      let mathTable = try Self.loadMathTable(mathFont: mathFont)

      if graphicsFonts[mathFont] == nil {
        graphicsFonts[mathFont] = graphicsFont
        rawMathTables[mathFont] = mathTable
      }
    } catch {
      fatalError(
        "MathFonts:\(#function) ondemand loading failed, mathFont \(mathFont.rawValue), reason \(error)",
      )
    }
  }

  fileprivate func obtainGraphicsFont(font: MathFont) -> CGFont {
    onDemandRegistration(mathFont: font)
    guard let graphicsFont = graphicsFonts[font] else {
      fatalError("unable to locate CGFont \(font.fontName)")
    }
    return graphicsFont
  }

  fileprivate func obtainCoreTextFont(font: MathFont, size: CGFloat) -> CTFont {
    onDemandRegistration(mathFont: font)
    let fontSizePair = FontSizePair(font: font, size: size)

    if let cached = coreTextFonts[fontSizePair] {
      return cached
    }
    guard let graphicsFont = graphicsFonts[font] else {
      fatalError("unable to locate CGFont \(font.fontName) to create CTFont")
    }
    let result = CTFontCreateWithGraphicsFont(graphicsFont, size, nil, nil)
    coreTextFonts[fontSizePair] = result
    return result
  }

  fileprivate func obtainRawMathTable(font: MathFont) -> [String: Any] {
    onDemandRegistration(mathFont: font)
    guard let data = rawMathTables[font] else {
      fatalError("unable to locate mathTable: \(font.rawValue).plist")
    }
    return data
  }

  enum FontError: Error {
    case invalidFontFile
    case fontPathNotFound
    case initFontError
    case registerFailed
    case invalidMathTable
  }

  private nonisolated struct FontSizePair: Hashable {
    let font: MathFont
    let size: CGFloat
  }
}
