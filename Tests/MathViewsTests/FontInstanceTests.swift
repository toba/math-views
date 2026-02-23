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
}
