---
name: test
description: |
  Run and manage tests for the MathViews Swift package. Use when (1) running tests after code changes, (2) debugging test failures, (3) adding new tests, (4) understanding test infrastructure. Triggers on: test failures, writing tests, running tests, TDD workflow.
---

# Test Skill

MathViews is a Swift Package Manager project. All builds and tests use `swift build` and `swift test`.

## Build & Test Commands

### Build only (fastest verification)
```bash
swift build
```

### Run all tests
```bash
swift test
```

### Run a single test class
```bash
swift test --filter MathListBuilderTests
```

### Run a specific test method
```bash
swift test --filter MathListBuilderTests.testBuilder
```

### Run multiple test classes by pattern
```bash
swift test --filter "MathListBuilderTests|TypesetterTests"
```

### Clean build
```bash
swift package clean
```

## CRITICAL: Minimize Test Scope

**Never run the full test suite during development.** Test selectively:

1. **Build only** — verify compilation without running tests
2. **Single class** — run only the class you modified
3. **Single method** — when debugging a specific failure
4. **Full suite** — only when explicitly requested

## Test Target

| Target | Module | Purpose |
|--------|--------|---------|
| MathViewsTests | MathViews | All tests: parsing, typesetting, fonts, rendering, line wrapping |

### Test Files

| File | Area |
|------|------|
| MathListBuilderTests | LaTeX parsing |
| MathListTests | AST structure |
| TypesetterTests | Typesetting rules |
| MathFontTests / FontInstanceV2Tests / FontMathTableV2Tests | Font loading and metrics |
| MathDelimiterTests | Delimiter sizing |
| MathImageTests | Rendered output |
| MathUILabelLineWrappingTests | Line breaking |
| Tokenization/ | Line break tokenization subsystem |
| AccentSpacingComparisonTest | Accent positioning |
| WidehatTests / WidehatGlyphTest | Wide accent glyphs |
| ArrowStretchingTest | Extensible arrows |
| ConcurrencyThreadsafeTests | Thread safety |
| Various regression tests | Edge cases |

## Writing Tests

### Current Framework: XCTest

Tests currently use XCTest (`XCTestCase` subclasses). Migration to Swift Testing is planned.

### Swift Testing (target framework)

New tests should use Swift Testing when the migration is underway:

```swift
import Testing
@testable import MathViews

struct MyFeatureTests {
    @Test func parsesInputCorrectly() throws {
        let builder = MathListBuilder("x^2")
        let list = builder.build()
        #expect(list != nil)
        #expect(list!.atoms.count == 1)
    }

    @Test(arguments: MathFont.allCases)
    func loadsFont(_ font: MathFont) throws {
        let mtFont = font.cgFont()
        #expect(mtFont != nil)
    }
}
```

### Pattern: Testing LaTeX Rendering

Most tests follow this pattern:

1. Build a `MathList` from a LaTeX string via `MathListBuilder`
2. Optionally verify the AST structure
3. Typeset via `Typesetter` to get a `Display`
4. Assert display properties (width, height, positions)

## Workflow: Debugging Failures

1. Run the failed test in isolation with `--filter`
2. Check if the test depends on font loading (fonts must be loaded via `MathFont` or `BundleManager`)
3. For rendering tests, check if platform (iOS vs macOS) affects the result
4. For typesetting tests, verify spacing constants in `FontMathTable`
