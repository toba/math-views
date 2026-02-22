---
# pzb-8uv
title: Convert all tests to Swift Testing
status: ready
type: task
created_at: 2026-02-22T17:19:30Z
updated_at: 2026-02-22T17:19:30Z
parent: z9b-r1r
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
