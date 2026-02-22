import XCTest
@testable import MathViews

final class FontMathTableV2Tests: XCTestCase {
    func testFontInstanceV2Script() throws {
        let size = CGFloat(Int.random(in: 20 ... 40))
        MathFont.allCases.forEach {
            let mTable = $0.fontInstance(size: size).mathTable
            XCTAssertNotNil(mTable)
            let values = [
                mTable?.fractionNumeratorDisplayStyleShiftUp,
                mTable?.fractionNumeratorShiftUp,
                mTable?.fractionDenominatorDisplayStyleShiftDown,
                mTable?.fractionDenominatorShiftDown,
                mTable?.fractionNumeratorDisplayStyleGapMin,
                mTable?.fractionNumeratorGapMin,
            ].compactMap{$0}
        }
    }
    private let executionQueue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
    private let executionGroup = DispatchGroup()
    let totalCases = 1000
    var testCount = 0
    func testConcurrentThreadsafeScript() throws {
        testCount = 0
        var mathFont: MathFont { .allCases.randomElement()! }
        var size: CGFloat { CGFloat.random(in: 20 ... 40) }
        let fontInstances = Array( 0 ..< 10 ).map { _ in mathFont.fontInstance(size: size) }
        for caseNumber in 0 ..< totalCases {
            helperConcurrentFontMathTableV2(caseNumber, fontInst: fontInstances.randomElement()!, in: executionGroup, on: executionQueue)
        }
        executionGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            XCTAssertEqual(self.testCount, totalCases)
        }
        executionGroup.wait()
    }
    func helperConcurrentFontMathTableV2(_ count: Int, fontInst: FontInstanceV2, in group: DispatchGroup, on queue: DispatchQueue) {
        let workitem = DispatchWorkItem {
            let mTable = fontInst.mathTable
            let values = [
                mTable?.fractionNumeratorDisplayStyleShiftUp,
                mTable?.fractionNumeratorShiftUp,
                mTable?.fractionDenominatorDisplayStyleShiftDown,
                mTable?.fractionDenominatorShiftDown,
                mTable?.fractionNumeratorDisplayStyleGapMin,
                mTable?.fractionNumeratorGapMin,
            ].compactMap{$0}
            // if count % 50 == 0 {
            //     print(values) // accessed these values on global thread.
            // }
            XCTAssertNotNil(mTable)
        }
        workitem.notify(queue: .main) { [weak self] in
            // print("\(Thread.isMainThread ? "main" : "global") completed .....")
            let mTable = fontInst.mathTable
            if count % 70 == 0 {
                let values = [
                    mTable?.fractionNumeratorDisplayStyleShiftUp,
                    mTable?.fractionNumeratorShiftUp,
                    mTable?.fractionDenominatorDisplayStyleShiftDown,
                    mTable?.fractionDenominatorShiftDown,
                    mTable?.fractionNumeratorDisplayStyleGapMin,
                    mTable?.fractionNumeratorGapMin,
                ].compactMap{$0}
                // if count % 50 == 0 {
                //     print(values)
                // }
            }
            self?.testCount += 1
        }
        queue.async(group: group, execute: workitem)
    }

}
