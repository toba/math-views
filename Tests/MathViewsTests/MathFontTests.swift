import Testing
import CoreText
@testable import MathViews
import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
#endif

struct MathFontTests {
    @Test func mathFontScript() {
        let size = Int.random(in: 20 ... 40)
        for font in MathFont.allCases {
            #expect(font.cgFont() != nil)
            #expect(font.ctFont(size: CGFloat(size)) != nil)
            #expect(
                font.ctFont(size: CGFloat(size)).fontSize == CGFloat(size),
                "ctFont fontSize != size.",
            )
            #expect(
                font.cgFont().postScriptName as? String == font.postScriptName,
                "cgFont.postScriptName != postScriptName",
            )
            #expect(
                CTFontCopyFamilyName(font.ctFont(size: CGFloat(size))) as String == font
                    .fontFamilyName,
                "ctfont.family != familyName",
            )
        }
        #if os(iOS) || os(visionOS)
        for name in fontNames {
            #expect(UIFont(name: name, size: CGFloat(size)) != nil)
        }
        for name in fontFamilyNames {
            #expect(UIFont.fontNames(forFamilyName: name) != nil)
        }
        #endif
        #if os(macOS)
        for name in fontNames {
            let font = NSFont(name: name, size: CGFloat(size))
            #expect(font != nil)
        }
        #endif
    }

    @Test func onDemandMathFontScript() throws {
        let size = Int.random(in: 20 ... 40)
        let mathFont = try #require(MathFont.allCases.randomElement())
        #expect(mathFont.cgFont() != nil)
        #expect(mathFont.ctFont(size: CGFloat(size)) != nil)
        #expect(
            mathFont.ctFont(size: CGFloat(size)).fontSize == CGFloat(size),
            "ctFont fontSize test",
        )
    }

    var fontNames: [String] {
        MathFont.allCases.map(\.postScriptName)
    }

    var fontFamilyNames: [String] {
        MathFont.allCases.map(\.fontFamilyName)
    }

    @Test func concurrentThreadsafe() throws {
        let queue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
        let group = DispatchGroup()
        let totalCases = 5000
        for caseNumber in 0 ..< totalCases {
            let mathFont = try #require(MathFont.allCases.randomElement())
            group.enter()
            queue.async {
                defer { group.leave() }
                switch caseNumber % 3 {
                    case 0:
                        let font = mathFont.cgFont()
                        #expect(font != nil, "font != nil")
                    case 1:
                        let size = CGFloat.random(in: 20 ... 40)
                        let font = mathFont.ctFont(size: size)
                        #expect(font != nil, "font != nil")
                    case 2:
                        let mathtable = mathFont.rawMathTable()
                        #expect(mathtable != nil, "mathTable != nil")
                    default:
                        break
                }
            }
        }
        group.wait()
    }

    @Test func fallbackFont() throws {
        #if os(iOS) || os(visionOS)
        let systemFont = UIFont.systemFont(ofSize: 20)
        let systemCTFont = CTFontCreateWithName(systemFont.fontName as CFString, 20, nil)
        #elseif os(macOS)
        let systemFont = NSFont.systemFont(ofSize: 20)
        let systemCTFont = CTFontCreateWithName(systemFont.fontName as CFString, 20, nil)
        #endif

        let mathFont = MathFont.latinModern.fontInstance(size: 20)
        mathFont.fallbackFont = systemCTFont

        let mathList = try MathListBuilder.buildChecked(fromString: "\\text{中文测试}")

        #expect(mathList.atoms.count == 4, "Should have 4 atoms for 4 Chinese characters")

        for atom in mathList.atoms {
            #expect(atom.fontStyle == .roman, "Text atoms should have roman font style")
        }

        let display = Typesetter.makeLineDisplay(for: mathList, font: mathFont, style: .text)

        #expect(display != nil, "Display should be created with fallback font")
        #expect((display?.width ?? 0) > 0, "Display should have non-zero width with fallback font")
    }
}
