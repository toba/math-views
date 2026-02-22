import CoreGraphics
import Foundation
import Testing

@testable import MathViews

struct FontInstanceV2Tests {
  @Test func fontInstanceV2Script() {
    let size = CGFloat(Int.random(in: 20...40))
    for font in MathFont.allCases {
      let fontInst = font.fontInstance(size: size)
      let mTable = fontInst.mathTable?._mathTable
      #expect(fontInst != nil)
      #expect(mTable != nil)
    }
  }

  @Test func concurrentThreadsafe() {
    let queue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
    let group = DispatchGroup()
    let totalCases = 1000
    for _ in 0..<totalCases {
      let mathFont = MathFont.allCases.randomElement()!
      let size = CGFloat.random(in: 20...40)
      group.enter()
      queue.async {
        defer { group.leave() }
        let fontV2 = mathFont.fontInstance(size: size)
        #expect(fontV2 != nil)
        let (cgfont, ctfont) = (fontV2.defaultCGFont, fontV2.ctFont)
        #expect(cgfont != nil)
        #expect(ctfont != nil)
      }
    }
    group.wait()
  }

  @Test func concurrentThreadsafeMathTableLock() {
    let queue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
    let group = DispatchGroup()
    let totalCases = 1000
    let fontInstances = (0..<5).map { _ in
      MathFont.allCases.randomElement()!.fontInstance(size: CGFloat.random(in: 20...40))
    }
    for _ in 0..<totalCases {
      let fontInst = fontInstances.randomElement()!
      group.enter()
      queue.async {
        defer { group.leave() }
        let mathTable = fontInst.mathTable as? FontMathTableV2
        #expect(mathTable != nil)
      }
    }
    group.wait()
  }
}
