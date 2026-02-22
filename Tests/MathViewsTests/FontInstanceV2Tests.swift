import XCTest
@testable import MathViews

final class FontInstanceV2Tests: XCTestCase {
    func testFontInstanceV2Script() throws {
        let size = CGFloat(Int.random(in: 20 ... 40))
        MathFont.allCases.forEach {
            let fontInst = $0.fontInstance(size: size)
            let mTable = fontInst.mathTable?._mathTable
            XCTAssertNotNil(fontInst)
            XCTAssertNotNil(mTable)
        }
    }
    private let executionQueue = DispatchQueue(label: "com.swiftmath.mathbundle", attributes: .concurrent)
    private let executionGroup = DispatchGroup()
    let totalCases = 1000
    var testCount = 0
    func testConcurrentThreadsafeScript() throws {
        testCount = 0
        var mathFont: MathFont { .allCases.randomElement()! }
        for caseNumber in 0 ..< totalCases {
            helperConcurrentFontInstanceV2(caseNumber, mathFont: mathFont, in: executionGroup, on: executionQueue)
        }
        executionGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            XCTAssertEqual(self.testCount, totalCases)
        }
        executionGroup.wait()
    }
    func helperConcurrentFontInstanceV2(_ count: Int, mathFont: MathFont, in group: DispatchGroup, on queue: DispatchQueue) {
        let size = CGFloat.random(in: 20 ... 40)
        let workitem = DispatchWorkItem {
            let fontV2 = mathFont.fontInstance(size: size)
            XCTAssertNotNil(fontV2)
            let (cgfont, ctfont) = (fontV2.defaultCGFont, fontV2.ctFont)
            XCTAssertNotNil(cgfont)
            XCTAssertNotNil(ctfont)
        }
        workitem.notify(queue: .main) { [weak self] in
            // print("\(Thread.isMainThread ? "main" : "global") completed .....")
            let fontV2 = mathFont.fontInstance(size: size)
            XCTAssertNotNil(fontV2)
            let (cgfont, ctfont) = (fontV2.defaultCGFont, fontV2.ctFont)
            XCTAssertNotNil(cgfont)
            XCTAssertNotNil(ctfont)
            let mTable = mathFont.rawMathTable()
            XCTAssertNotNil(mTable)
            self?.testCount += 1
        }
        queue.async(group: group, execute: workitem)
    }
    func testConcurrentThreadsafeMathTableLockScript() throws {
        testCount = 0
        var mathFont: MathFont { .allCases.randomElement()! }
        var size: CGFloat { CGFloat.random(in: 20 ... 40) }
        let fontInstances = Array( 0 ..< 5 ).map { _ in mathFont.fontInstance(size: size) }
        for caseNumber in 0 ..< totalCases {
            helperConcurrentFontInstanceV2MathTableLock(caseNumber, fontInst: fontInstances.randomElement()!, in: executionGroup, on: executionQueue)
        }
        executionGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            XCTAssertEqual(self.testCount, totalCases)
        }
        executionGroup.wait()
    }
    func helperConcurrentFontInstanceV2MathTableLock(_ count: Int, fontInst: FontInstanceV2, in group: DispatchGroup, on queue: DispatchQueue) {
        let workitem = DispatchWorkItem {
            let mathTable = fontInst.mathTable as? FontMathTableV2
            // each mathTable is initialized once per fontInst with a NSLock.
            // this is even when mathTable is accessed via different threads.
            XCTAssertNotNil(mathTable)
        }
        workitem.notify(queue: .main) { [weak self] in
            // print("\(Thread.isMainThread ? "main" : "global") completed .....")
            self?.testCount += 1
        }
        queue.async(group: group, execute: workitem)
    }
}
