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
swift test --parallel
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

### Framework: Swift Testing

All tests use Swift Testing (`@Test`, `#expect`, `struct` suites).

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
}
```

### Parameterized Tests

Test multiple inputs without duplicating test methods:

```swift
@Test(arguments: MathFont.allCases)
func loadsFont(_ font: MathFont) throws {
    let mtFont = font.cgFont()
    #expect(mtFont != nil)
}

@Test(arguments: ["\\frac{1}{2}", "x^2", "\\sqrt{3}"])
func rendersWithoutError(_ latex: String) throws {
    let list = MathListBuilder(latex).build()
    #expect(list != nil)
}
```

### Pattern: Testing LaTeX Rendering

Most tests follow this pattern:

1. Build a `MathList` from a LaTeX string via `MathListBuilder`
2. Optionally verify the AST structure
3. Typeset via `Typesetter` to get a `Display`
4. Assert display properties (width, height, positions)

## Traits

Traits customize test behavior. Pass them as arguments to `@Test` or `@Suite`.

### Built-in Traits

| Trait | Purpose |
|-------|---------|
| `.disabled()` | Skip unconditionally |
| `.disabled("reason")` | Skip with explanation |
| `.disabled { bool }` | Skip via closure (return true to disable) |
| `.enabled(if: condition)` | Run only when condition is true |
| `.bug("url")` | Link to bug tracker |
| `.bug(id: "name")` | Link by identifier |
| `.bug("url", "title")` | Link with display title |
| `.timeLimit(.minutes(N))` | Per-test or per-suite deadline |
| `.serialized` | Force serial execution in suite |
| `.tags(...)` | Categorize tests for filtering |
| `"display name"` | Human-readable test/suite name |

### `.disabled` — skip tests

```swift
@Test(.disabled()) func brokenRendering() throws { ... }
@Test(.disabled("Metrics differ on CI")) func accentPosition() throws { ... }
```

### `.bug` — link to known issues

```swift
@Test(.bug("https://github.com/user/repo/issues/42"))
func handlesEdgeCase() throws { ... }

@Test(.bug(id: "spacing-regression"))
func interatomSpacing() throws { ... }
```

### `.enabled(if:)` — conditional execution

Skips the test when the condition is false:

```swift
@Test(.enabled(if: ProcessInfo.processInfo.environment["CI"] == nil))
func localOnlyTest() { ... }
```

### `.timeLimit` — per-test or per-suite deadline

```swift
@Test(.timeLimit(.minutes(2))) func renderAllSymbols() throws { ... }

@Suite(.timeLimit(.minutes(1)))
struct SlowTests { ... }
```

### `.serialized` — force serial execution

```swift
@Suite(.serialized)
struct FontLoadingTests {
    // Tests run one at a time, in declaration order
}
```

### Display names

```swift
@Suite("MathListBuilder")
struct MathListBuilderTests { ... }

@Test("fraction builds correct atom tree")
func fractionBuild() { ... }
```

Convention: `@Suite` names match the type under test; `@Test` names describe expected behavior.

### Combining traits

Traits compose freely. Order doesn't matter:

```swift
@Test(.disabled("known regression"), .bug("https://github.com/user/repo/issues/7"))
func nestedFractionSpacing() throws { ... }

@Test("renders all fonts", .timeLimit(.minutes(1)), arguments: MathFont.allCases)
func renderFont(_ font: MathFont) throws { ... }
```

## Interpreting Results

| Outcome | Meaning |
|---------|---------|
| Passed | Test assertions all succeeded |
| Failed | Assertion failed or unexpected error thrown |
| Expected failure | Known issue marked with `withKnownIssue` |
| Skipped | Disabled by `.disabled()`, `.enabled(if:)`, or condition |

## Code Coverage

```bash
swift test --enable-code-coverage
```

- Coverage impacts performance — disable for performance-sensitive runs
- High coverage ≠ robust tests; pair with meaningful assertions
- Focus coverage efforts on high-risk code paths (typesetter, parser)

## Workflow: Debugging Failures

1. Run the failed test in isolation with `--filter`
2. Check if the test depends on font loading (fonts must be loaded via `MathFont` or `BundleManager`)
3. For rendering tests, check if platform (iOS vs macOS) affects the result
4. For typesetting tests, verify spacing constants in `FontMathTable`

## Troubleshooting

### Build errors in excluded tests

Excluded tests still compile. Build errors in skipped tests fail the entire test action. Fix build errors even in tests you don't plan to run.
