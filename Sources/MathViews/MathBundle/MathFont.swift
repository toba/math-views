#if os(iOS) || os(visionOS)
public import UIKit
#elseif os(macOS)
public import AppKit
#endif

/// Now available for everyone to use
public enum MathFont: String, CaseIterable, Identifiable, Sendable {
    public var id: Self { self } // Makes things simpler for SwiftUI

    case latinModern = "latinmodern-math"
    case xits = "xits-math"
    case termes = "texgyretermes-math"
    case notoSans = "NotoSansMath-Regular"
    case libertinus = "LibertinusMath-Regular"
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

    public func cgFont() -> CGFont {
        BundleManager.manager.obtainCGFont(font: self)
    }

    public func ctFont(size: CGFloat) -> CTFont {
        BundleManager.manager.obtainCTFont(font: self, size: size)
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

private final class BundleManager {
    static let manager = BundleManager()

    private var cgFonts = [MathFont: CGFont]()
    private var ctFonts = [CTFontSizePair: CTFont]()
    private var rawMathTables = [MathFont: [String: Any]]()

    private static func loadCGFont(mathFont: MathFont) throws(FontError) -> CGFont {
        guard
            let frameworkBundleURL = Bundle.module.url(
                forResource: "mathFonts",
                withExtension: "bundle",
            ),
            let resourceBundleURL = Bundle(url: frameworkBundleURL)?.path(
                forResource: mathFont.rawValue, ofType: "otf",
            )
        else {
            throw FontError.fontPathNotFound
        }
        guard let fontData = try? Data(contentsOf: URL(fileURLWithPath: resourceBundleURL)),
              let dataProvider = CGDataProvider(data: fontData as CFData)
        else {
            throw FontError.invalidFontFile
        }
        guard let defaultCGFont = CGFont(dataProvider) else {
            throw FontError.initFontError
        }

        var errorRef: Unmanaged<CFError>?
        guard CTFontManagerRegisterGraphicsFont(defaultCGFont, &errorRef) else {
            throw FontError.registerFailed
        }
        return defaultCGFont
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
              let plist = (try? PropertyListSerialization.propertyList(
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
        guard cgFonts[mathFont] == nil else { return }

        do {
            let cgFont = try Self.loadCGFont(mathFont: mathFont)
            let mathTable = try Self.loadMathTable(mathFont: mathFont)

            if cgFonts[mathFont] == nil {
                cgFonts[mathFont] = cgFont
                rawMathTables[mathFont] = mathTable
            }
        } catch {
            fatalError(
                "MathFonts:\(#function) ondemand loading failed, mathFont \(mathFont.rawValue), reason \(error)",
            )
        }
    }

    fileprivate func obtainCGFont(font: MathFont) -> CGFont {
        onDemandRegistration(mathFont: font)
        guard let cgFont = cgFonts[font] else {
            fatalError("unable to locate CGFont \(font.fontName)")
        }
        return cgFont
    }

    fileprivate func obtainCTFont(font: MathFont, size: CGFloat) -> CTFont {
        onDemandRegistration(mathFont: font)
        let fontSizePair = CTFontSizePair(font: font, size: size)

        if let cached = ctFonts[fontSizePair] {
            return cached
        }
        guard let cgFont = cgFonts[font] else {
            fatalError("unable to locate CGFont \(font.fontName) to create CTFont")
        }
        let result = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
        ctFonts[fontSizePair] = result
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

    private nonisolated struct CTFontSizePair: Hashable {
        let font: MathFont
        let size: CGFloat
    }
}
