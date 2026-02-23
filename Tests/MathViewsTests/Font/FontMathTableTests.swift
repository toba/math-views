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
}
