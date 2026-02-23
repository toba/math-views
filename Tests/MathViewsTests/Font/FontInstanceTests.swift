import CoreGraphics
import Foundation
import Testing

@testable import MathViews

struct FontInstanceTests {
  @Test func fontInstanceScript() {
    let size = CGFloat(Int.random(in: 20...40))
    for font in MathFont.allCases {
      let fontInst = font.fontInstance(size: size)
      #expect(fontInst.mathTable != nil)
    }
  }
}
