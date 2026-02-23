import Testing
@testable import MathViews
import Foundation

struct ConcurrencyThreadsafeTests {
    @Test func mathViewsConcurrentScript() async {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 20 {
                group.addTask {
                    let result1 = interElementSpaces
                    let result2 = MathAtomFactory.delimValueToName
                    let result3 = MathAtomFactory.accentValueToName
                    let result4 = MathAtomFactory.textToLatexSymbolName
                    #expect(!result1.isEmpty)
                    #expect(!result2.isEmpty)
                    #expect(!result3.isEmpty)
                    #expect(!result4.isEmpty)
                }
            }
        }
    }
}
