import XCTest
@testable import MathViews

final class ConcurrencyThreadsafeTests: XCTestCase {
    
    private let executionQueue = DispatchQueue(label: "com.swiftmath.concurrencytests", attributes: .concurrent)
    private let executionGroup = DispatchGroup()
    
    let totalCases = 20
    var testCount = 0
    
    func testMathViewsConcurrentScript() throws {
        for caseNumber in 0 ..< totalCases {
            helperConcurrency(caseNumber, in: executionGroup, on: executionQueue) {
                let result1 = getInterElementSpaces()
                let result2 = MathAtomFactory.delimValueToName
                let result3 = MathAtomFactory.accentValueToName
                let result4 = MathAtomFactory.textToLatexSymbolName
                XCTAssertNotNil(result1)
                XCTAssertNotNil(result2)
                XCTAssertNotNil(result3)
                XCTAssertNotNil(result4)
            }
        }
//        executionGroup.notify(queue: .main) { [weak self] in
//            // print("All test cases completed: \(self?.testCount ?? 0)")
//        }
        executionGroup.wait()
    }
    func helperConcurrency(_ count: Int, in group: DispatchGroup, on queue: DispatchQueue, _ testClosure: @escaping () -> (Void)) {
        let workitem = DispatchWorkItem {
            testClosure()
        }
        workitem.notify(queue: .main) { [weak self] in
            self?.testCount += 1
        }
        queue.async(group: group, execute: workitem)
    }

}
