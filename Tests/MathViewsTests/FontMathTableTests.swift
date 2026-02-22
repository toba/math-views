import CoreGraphics
import Foundation
import Testing

@testable import MathViews

struct FontMathTableTests {
  @Test func fontMathTableScript() {
    let size = CGFloat(Int.random(in: 20...40))
    for font in MathFont.allCases {
      let mTable = font.fontInstance(size: size).mathTable
      #expect(mTable != nil)
      _ = [
        mTable?.fractionNumeratorDisplayStyleShiftUp,
        mTable?.fractionNumeratorShiftUp,
        mTable?.fractionDenominatorDisplayStyleShiftDown,
        mTable?.fractionDenominatorShiftDown,
        mTable?.fractionNumeratorDisplayStyleGapMin,
        mTable?.fractionNumeratorGapMin,
      ].compactMap(\.self)
    }
  }

  @Test func concurrentThreadsafe() {
    let queue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
    let group = DispatchGroup()
    let totalCases = 1000
    let fontInstances = (0..<10).map { _ in
      MathFont.allCases.randomElement()!.fontInstance(size: CGFloat.random(in: 20...40))
    }
    for _ in 0..<totalCases {
      let fontInst = fontInstances.randomElement()!
      group.enter()
      queue.async {
        defer { group.leave() }
        let mTable = fontInst.mathTable
        _ = [
          mTable?.fractionNumeratorDisplayStyleShiftUp,
          mTable?.fractionNumeratorShiftUp,
          mTable?.fractionDenominatorDisplayStyleShiftDown,
          mTable?.fractionDenominatorShiftDown,
          mTable?.fractionNumeratorDisplayStyleGapMin,
          mTable?.fractionNumeratorGapMin,
        ].compactMap(\.self)
        #expect(mTable != nil)
      }
    }
    group.wait()
  }
}
