import Testing
@testable import MathViews
import Foundation

struct ConcurrencyThreadsafeTests {

    @Test func mathViewsConcurrentScript() {
        let queue = DispatchQueue(label: "com.swiftmath.concurrencytests", attributes: .concurrent)
        let group = DispatchGroup()
        let totalCases = 20
        for _ in 0 ..< totalCases {
            group.enter()
            queue.async {
                defer { group.leave() }
                let result1 = getInterElementSpaces()
                let result2 = MathAtomFactory.delimValueToName
                let result3 = MathAtomFactory.accentValueToName
                let result4 = MathAtomFactory.textToLatexSymbolName
                #expect(result1 != nil)
                #expect(!result2.isEmpty)
                #expect(!result3.isEmpty)
                #expect(!result4.isEmpty)
            }
        }
        group.wait()
    }
}
