---
# pzb-8uv
title: Convert all tests to Swift Testing
status: completed
type: task
priority: normal
created_at: 2026-02-22T17:19:30Z
updated_at: 2026-02-22T21:57:41Z
parent: z9b-r1r
sync:
    github:
        issue_number: "8"
        synced_at: "2026-02-22T18:51:01Z"
---

Migrate the entire test suite from XCTest to Swift Testing (https://developer.apple.com/xcode/swift-testing/).

## Tasks

- [ ] Replace `import XCTest` with `import Testing` in all test files
- [ ] Convert `class ... : XCTestCase` to `struct` with `@Suite`
- [ ] Convert `func test...` methods to `@Test` functions
- [ ] Replace `XCTAssert*` with `#expect` / `#require` macros
- [ ] Replace `setUp` / `tearDown` with `init` / `deinit` where needed
- [ ] Convert parameterized test patterns to `@Test(arguments:)`
- [ ] Remove `override` modifiers from test methods
- [ ] Verify all tests pass with `swift test`

## Key Files

All files under `Tests/`

## Summary of Changes

Converted 25 test files from XCTest to Swift Testing. 4 concurrency test files kept as XCTest (coexist in same target).

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

### Files kept as XCTest (4):
- ConcurrencyThreadsafeTests, FontInstanceV2Tests, FontMathTableV2Tests, MathFontTests

### Result: 536 tests in 34 suites, all passing
