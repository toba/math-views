#if os(iOS) || os(visionOS)
public import UIKit
#elseif os(macOS)
public import AppKit
#endif

/// Now available for everyone to use
public enum MathFont: String, CaseIterable, Identifiable, Sendable {
    
    public var id: Self { self }  // Makes things simpler for SwiftUI

    case latinModernFont = "latinmodern-math"
    case xitsFont        = "xits-math"
    case termesFont      = "texgyretermes-math"
    case notoSansFont    = "NotoSansMath-Regular"
    case libertinusFont  = "LibertinusMath-Regular"
    case garamondFont    = "Garamond-Math"
    
    var fontFamilyName: String {
        switch self {
            case .latinModernFont:  "Latin Modern Math"
            case .xitsFont:         "XITS Math"
            case .termesFont:       "TeX Gyre Termes Math"
            case .notoSansFont:     "Noto Sans Math"
            case .libertinusFont:   "Libertinus Math"
            case .garamondFont:     "Garamond-Math"
        }
    }

    var postScriptName: String {
        switch self {
            case .latinModernFont:  "LatinModernMath-Regular"
            case .xitsFont:         "XITSMath"
            case .termesFont:       "TeXGyreTermesMath-Regular"
            case .notoSansFont:     "NotoSansMath-Regular"
            case .libertinusFont:   "LibertinusMath-Regular"
            case .garamondFont:     "Garamond-Math"
        }
    }

    var fontName: String { self.rawValue }
	
    public func cgFont() -> CGFont {
        BundleManager.manager.obtainCGFont(font: self)
    }
    public func ctFont(withSize size: CGFloat) -> CTFont {
        BundleManager.manager.obtainCTFont(font: self, withSize: size)
    }
    internal func rawMathTable() -> [String: Any] {
        BundleManager.manager.obtainRawMathTable(font: self)
    }
    
    public func fontInstance(size: CGFloat) -> FontInstance {
        FontInstance(font: self, size: size)
    }
}
internal extension CTFont {
    /** The size of this font in points. */
    var fontSize: CGFloat {
        CTFontGetSize(self)
    }
    var unitsPerEm: UInt {
        return UInt(CTFontGetUnitsPerEm(self))
    }
}
import Synchronization

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

private class BundleManager: @unchecked Sendable {
    static let manager = BundleManager()

    private struct CacheState: Sendable {
        var cgFonts = [MathFont: CGFont]()
        var ctFonts = [CTFontSizePair: SendableCTFont]()
        var rawMathTables = [MathFont: RawMathTableData]()
    }

    private let cache = Mutex(CacheState())

    private static func loadCGFont(mathFont: MathFont) throws -> CGFont {
        guard let frameworkBundleURL = Bundle.module.url(forResource: "mathFonts", withExtension: "bundle"),
              let resourceBundleURL = Bundle(url: frameworkBundleURL)?.path(forResource: mathFont.rawValue, ofType: "otf") else {
            throw FontError.fontPathNotFound
        }
        guard let fontData = NSData(contentsOfFile: resourceBundleURL), let dataProvider = CGDataProvider(data: fontData) else {
            throw FontError.invalidFontFile
        }
        guard let defaultCGFont = CGFont(dataProvider) else {
            throw FontError.initFontError
        }

        var errorRef: Unmanaged<CFError>? = nil
        guard CTFontManagerRegisterGraphicsFont(defaultCGFont, &errorRef) else {
            throw FontError.registerFailed
        }
        let postsript  = (defaultCGFont.postScriptName as? String) ?? ""
        let cgfontName = (defaultCGFont.fullName as? String) ?? ""
        let threadName = Thread.isMainThread ? "main" : "global"
        debugPrint("mathFonts bundle resource: \(mathFont.rawValue), font: \(cgfontName), ps: \(postsript) registered on \(threadName).")
        return defaultCGFont
    }

    private static func loadMathTable(mathFont: MathFont) throws -> [String: Any] {
        guard let frameworkBundleURL = Bundle.module.url(forResource: "mathFonts", withExtension: "bundle"),
              let mathTablePlist = Bundle(url: frameworkBundleURL)?.url(forResource: mathFont.rawValue, withExtension:"plist") else {
            throw FontError.fontPathNotFound
        }
        guard let plist = NSDictionary(contentsOf: mathTablePlist) as? [String: Any],
                let version = plist["version"] as? String,
                version == "1.3" else {
            throw FontError.invalidMathTable
        }

        let threadName = Thread.isMainThread ? "main" : "global"
        debugPrint("mathFonts bundle resource: \(mathFont.rawValue).plist registered on \(threadName).")
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
            fatalError("MathFonts:\(#function) ondemand loading failed, mathFont \(mathFont.rawValue), reason \(error)")
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

    fileprivate func obtainCTFont(font: MathFont, withSize size: CGFloat) -> CTFont {
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
            var errorRef: Unmanaged<CFError>? = nil
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
