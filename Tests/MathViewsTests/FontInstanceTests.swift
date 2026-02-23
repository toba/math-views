import Testing
@testable import MathViews
import Foundation
import CoreGraphics

struct FontInstanceTests {
    @Test func fontInstanceScript() {
        let size = CGFloat(Int.random(in: 20 ... 40))
        for font in MathFont.allCases {
            let fontInst = font.fontInstance(size: size)
            #expect(fontInst != nil)
            #expect(fontInst.mathTable != nil)
        }
    }

    @Test func concurrentThreadsafe() throws {
        let queue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
        let group = DispatchGroup()
        let totalCases = 1000
        for _ in 0 ..< totalCases {
            let mathFont = try #require(MathFont.allCases.randomElement())
            let size = CGFloat.random(in: 20 ... 40)
            group.enter()
            queue.async {
                defer { group.leave() }
                let fontInst = mathFont.fontInstance(size: size)
                #expect(fontInst != nil)
                let (cgfont, ctfont) = (fontInst.defaultCGFont, fontInst.ctFont)
                #expect(cgfont != nil)
                #expect(ctfont != nil)
            }
        }
        group.wait()
    }

    @Test func concurrentThreadsafeMathTableLock() throws {
        let queue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
        let group = DispatchGroup()
        let totalCases = 1000
        let fontInstances = (0 ..< 5).map { _ in
            MathFont.allCases.randomElement()!.fontInstance(size: CGFloat.random(in: 20 ... 40))
        }
        for _ in 0 ..< totalCases {
            let fontInst = try #require(fontInstances.randomElement())
            group.enter()
            queue.async {
                defer { group.leave() }
                let mathTable = fontInst.mathTable
                #expect(mathTable != nil)
            }
        }
        group.wait()
    }
}
