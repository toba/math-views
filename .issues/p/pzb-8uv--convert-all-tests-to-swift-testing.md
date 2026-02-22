---
# pzb-8uv
title: Convert all tests to Swift Testing
status: completed
type: task
priority: normal
created_at: 2026-02-22T17:19:30Z
updated_at: 2026-02-22T22:15:16Z
parent: z9b-r1r
sync:
    github:
        issue_number: "8"
        synced_at: "2026-02-22T18:51:01Z"
---

Migrate the entire test suite from XCTest to Swift Testing (https://developer.apple.com/xcode/swift-testing/).

## Tasks

- [x] Replace `import XCTest` with `import Testing` in all test files
- [x] Convert `class ... : XCTestCase` to `struct`
- [x] Convert `func test...` methods to `@Test` functions
- [x] Replace `XCTAssert*` with `#expect` / `#require` macros
- [x] Replace `setUp` / `tearDown` with `init` / `deinit` where needed
- [x] Convert parameterized test patterns to `@Test(arguments:)`
- [x] Remove `override` modifiers from test methods
- [x] Verify all tests pass with `swift test`

## Key Files

All files under `Tests/`

## Summary of Changes

Converted 25 test files from XCTest to Swift Testing. All test files converted. No XCTest imports remain.

### Key changes across all files:
- `class Foo: XCTestCase` → `struct Foo`
- `import XCTest` → `import Testing` (+ explicit CoreGraphics/Foundation/AppKit imports)
- `func testFoo()` → `@Test func foo()`
- `var font: FontInstance!` with `setUp()` → `let font: FontInstance` with `init()`
- All XCT assertions → `#expect()` / `#require()`
- `XCTFail()` → `Issue.record()`
- `try XCTUnwrap()` → `try #require()`

### Parameterized tests (`@Test(arguments:)`):
- MathListBuilderTests: 6 data-driven methods (builder, superScript, subScript, superSubScript, leftRight, parseErrors)
- MathImageTests: 11 render test classes with parameterized loops
- LimitOperatorRegressionTests: 2 methods (operators, integrals)
- DotlessIJAccentTests: 6 methods
- ArrowStretchingTest, WidehatTests, MathDelimiterTests: various

### Previously kept as XCTest, now converted (5):
- MathImageTests, ConcurrencyThreadsafeTests, FontInstanceV2Tests, FontMathTableV2Tests, MathFontTests
- Concurrency tests preserved GCD DispatchQueue/DispatchGroup pattern (tests thread safety) with `group.enter()`/`group.leave()`/`group.wait()`
- Dropped mutable `testCount` tracking (replaced by `group.wait()` guaranteeing completion)
- `XCTFail` → `try #require`, `XCTAssertEqual(count)` → removed (group.wait suffices)

### Result: 536 tests in 34 suites, all passing


### Final result: 549 tests in 44 suites, all passing. Zero XCTest imports.
