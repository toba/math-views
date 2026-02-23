import Synchronization

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

// MARK: - Retroactive Sendable for CoreText/CoreGraphics types

// These CF types are immutable after creation and thread-safe,
// but Apple hasn't annotated them yet.
extension CGFont: @retroactive @unchecked Sendable {}
extension CGDataProvider: @retroactive @unchecked Sendable {}

/// Immutable plist data wrapper for crossing the Mutex sending boundary.
private struct RawMathTableData: @unchecked Sendable {
    let plist: [String: Any]
}

/// CTFont wrapper for crossing the Mutex sending boundary.
/// CTFont is immutable and thread-safe but lacks Sendable conformance.
private struct SendableCTFont: @unchecked Sendable {
    let font: CTFont
}

private final class BundleManager: @unchecked Sendable {
    static let manager = BundleManager()

    private struct CacheState: Sendable {
        var cgFonts = [MathFont: CGFont]()
        var ctFonts = [CTFontSizePair: SendableCTFont]()
        var rawMathTables = [MathFont: RawMathTableData]()
    }

    private let cache = Mutex(CacheState())

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
        let postscript = (defaultCGFont.postScriptName as? String) ?? ""
        let cgFontName = (defaultCGFont.fullName as? String) ?? ""
        let threadName = Thread.isMainThread ? "main" : "global"
        debugPrint(
            "mathFonts bundle resource: \(mathFont.rawValue), font: \(cgFontName), ps: \(postscript) registered on \(threadName).",
        )
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

        let threadName = Thread.isMainThread ? "main" : "global"
        debugPrint(
            "mathFonts bundle resource: \(mathFont.rawValue).plist registered on \(threadName).",
        )
        return plist
    }

    private func onDemandRegistration(mathFont: MathFont) {
        let alreadyLoaded = cache.withLock { $0.cgFonts[mathFont] != nil }
        guard !alreadyLoaded else { return }

        do {
            let cgFont = try Self.loadCGFont(mathFont: mathFont)
            let mathTable = try Self.loadMathTable(mathFont: mathFont)

            cache.withLock { state in
                if state.cgFonts[mathFont] == nil {
                    state.cgFonts[mathFont] = cgFont
                    state.rawMathTables[mathFont] = RawMathTableData(plist: mathTable)
                }
            }
        } catch {
            fatalError(
                "MathFonts:\(#function) ondemand loading failed, mathFont \(mathFont.rawValue), reason \(error)",
            )
        }
    }

    fileprivate func obtainCGFont(font: MathFont) -> CGFont {
        onDemandRegistration(mathFont: font)
        return cache.withLock { state in
            guard let cgFont = state.cgFonts[font] else {
                fatalError("unable to locate CGFont \(font.fontName)")
            }
            return cgFont
        }
    }

    fileprivate func obtainCTFont(font: MathFont, size: CGFloat) -> CTFont {
        onDemandRegistration(mathFont: font)
        let fontSizePair = CTFontSizePair(font: font, size: size)

        let wrapped: SendableCTFont = cache.withLock { state in
            if let cached = state.ctFonts[fontSizePair] {
                return cached
            }
            guard let cgFont = state.cgFonts[font] else {
                fatalError("unable to locate CGFont \(font.fontName) to create CTFont")
            }
            let result = SendableCTFont(font: CTFontCreateWithGraphicsFont(cgFont, size, nil, nil))
            state.ctFonts[fontSizePair] = result
            return result
        }
        return wrapped.font
    }

    fileprivate func obtainRawMathTable(font: MathFont) -> [String: Any] {
        onDemandRegistration(mathFont: font)
        let wrapped: RawMathTableData = cache.withLock { state in
            guard let data = state.rawMathTables[font] else {
                fatalError("unable to locate mathTable: \(font.rawValue).plist")
            }
            return data
        }
        return wrapped.plist
    }

    deinit {
        cache.withLock { state in
            state.ctFonts.removeAll()
            var errorRef: Unmanaged<CFError>?
            for cgFont in state.cgFonts.values {
                CTFontManagerUnregisterGraphicsFont(cgFont, &errorRef)
            }
            state.cgFonts.removeAll()
        }
    }

    enum FontError: Error {
        case invalidFontFile
        case fontPathNotFound
        case initFontError
        case registerFailed
        case invalidMathTable
    }

    private struct CTFontSizePair: Hashable, Sendable {
        let font: MathFont
        let size: CGFloat
    }
}
