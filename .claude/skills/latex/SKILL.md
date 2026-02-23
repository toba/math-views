---
name: latex
description: >
  LaTeX math domain knowledge for the math-views (SwiftMath) project. Use when:
  (1) adding new LaTeX commands, symbols, operators, or accents,
  (2) implementing structural commands (fractions, radicals, environments),
  (3) validating math rendering correctness or comparing against KaTeX,
  (4) working on MTMathAtomFactory, MTMathListBuilder, or MTTypesetter,
  (5) user mentions LaTeX, math rendering, TeX spacing, or atom types,
  (6) working on multiline/line breaking behavior in the typesetter.
---

# LaTeX Math Implementation Guide

Reference files in this skill's `references/` directory:
- `latex-math-commands.md` — Complete LaTeX math command reference by category
- `katex-functions.md` — KaTeX function checklist with math-views support status
- `tex-spacing.md` — TeX inter-element spacing matrix and rules
- `multiline-breaking.md` — Multiline/line breaking architecture and behavior

## Key Source Files

| File | Purpose |
|------|---------|
| `Sources/SwiftMath/MathRender/MTMathAtomFactory.swift` | Symbol tables: `supportedLatexSymbols`, `aliases`, `delimiters`, `accents`, `fontStyles`, `matrixEnvs` |
| `Sources/SwiftMath/MathRender/MTMathListBuilder.swift` | LaTeX parser: `atomForCommand()` handles structural commands |
| `Sources/SwiftMath/MathRender/MTMathList.swift` | AST: `MTMathAtomType` enum, `MTMathAtom` and subclasses |
| `Sources/SwiftMath/MathRender/MTTypesetter.swift` | Typesetting: spacing matrix, script positioning, layout |
| `Sources/SwiftMath/MathRender/MTMathListDisplay.swift` | Display tree: `MTDisplay` subclasses for rendering |
| `Sources/SwiftMath/MathRender/MTMathUILabel.swift` | View layer: `MTMathUILabel` (UIView/NSView) |
| `Sources/SwiftMath/MathRender/Tokenization/` | Line breaking subsystem: tokenizer, line fitter, element width calculator |
| `Tests/SwiftMathTests/MTMathListBuilderTests.swift` | Parser tests: round-trip and atom type verification |
| `Tests/SwiftMathTests/MTTypesetterTests.swift` | Typesetter tests: spacing, multiline, line breaking (97 tests) |

## Atom Types and Their Meaning

The `MTMathAtomType` determines both rendering style and inter-element spacing. Choosing the wrong type is the most common source of incorrect rendering.

| Type | TeX Name | Spacing Role | Examples |
|------|----------|-------------|----------|
| `.ordinary` | Ord | Default spacing | `\forall`, `\infty`, `\partial` |
| `.variable` | — | Italicized, Ord spacing | `x`, `\alpha`, `\Gamma` |
| `.number` | — | Upright, Ord spacing | `0`–`9`, `.` |
| `.largeOperator` | Op | Thin space from Ord | `\sum`, `\int`, `\sin` |
| `.binaryOperator` | Bin | Medium space both sides | `+`, `\times`, `\cup` |
| `.relation` | Rel | Thick space both sides | `=`, `\leq`, `\rightarrow` |
| `.open` | Open | No space after | `(`, `\langle`, `\lceil` |
| `.close` | Close | No space before | `)`, `\rangle`, `\rceil` |
| `.punctuation` | Punct | Thin space after | `,`, `;`, `\colon` |
| `.fraction` | — | Same as Inner | `\frac{a}{b}` |
| `.radical` | Rad | Special (see spacing ref) | `\sqrt{x}` |
| `.inner` | Inner | Same as Fraction | `\left(...\right)` |
| `.accent` | Acc | Treated as Ordinary | `\hat{x}`, `\vec{v}` |

## Workflow: Adding a Symbol Command

Symbol commands map a LaTeX name to a Unicode character with a specific atom type.

1. **Identify the correct atom type** — See table above and `references/tex-spacing.md`
2. **Find the Unicode code point** — See `references/latex-math-commands.md`
3. **Add to `supportedLatexSymbols`** in `MTMathAtomFactory.swift`:
   ```swift
   "commandname" : MTMathAtom(type: .relation, value: "\u{XXXX}"),
   ```
4. **Add alias if needed** to the `aliases` dictionary
5. **Verify font support** — The glyph must exist in Latin Modern Math (or the active font)
6. **Write a test** — Parse `\commandname`, verify atom type and round-trip

### Choosing the Atom Type

- **Greek letters** → `.variable` (lowercase) or `.variable` (uppercase)
  - Exception: `\epsilon`, `\vartheta`, `\phi`, `\varrho`, `\varpi`, `\varkappa` → `.ordinary` (prevents auto-italicization)
- **Binary operators** (`+`, `\times`, `\cup`, etc.) → `.binaryOperator`
- **Relations** (`=`, `\leq`, all arrows, `\subset`, etc.) → `.relation`
- **Delimiters** → `.open` or `.close` (also add to `delimiters` dict if usable with `\left`/`\right`)
- **Everything else** (symbols, constants) → `.ordinary`

## Workflow: Adding a Named Operator

Named operators render in upright roman font (like `sin`, `lim`, `max`).

```swift
// In supportedLatexSymbols:
"operatorname" : MTMathAtomFactory.operatorWithName("operatorname", limits: false),
// or with limits (for operators that take limits above/below in display mode):
"operatorname" : MTMathAtomFactory.operatorWithName("operatorname", limits: true),
```

- `limits: false` — limits appear as subscripts/superscripts (e.g., `\sin`, `\log`)
- `limits: true` — limits appear above/below in display mode (e.g., `\lim`, `\max`, `\sum`)

For large operators with a symbol instead of text (like `\prod`):
```swift
"prod" : MTMathAtomFactory.operatorWithName("\u{220F}", limits: true),
```

Users can also create custom operators at runtime with `\operatorname{name}` or `\operatorname*{name}`.

## Workflow: Adding an Accent

1. **Find the combining Unicode character** for the accent
2. **Add to `accents`** dictionary in `MTMathAtomFactory.swift`:
   ```swift
   "accentname" : "\u{XXXX}",  // combining character
   ```
3. The parser automatically handles `\accentname{x}` via `atomForCommand()`
4. For stretchy accents (arrows), set `accent.isStretchy = true` in the `accent(withName:)` method
5. For wide accents (`\widehat`, `\widetilde`), set `accent.isWide = true`

Current accents: `grave`, `acute`, `hat`/`widehat`, `tilde`/`widetilde`, `bar`, `breve`, `dot`, `ddot`, `check`, `vec`, `overleftarrow`, `overrightarrow`, `overleftrightarrow`

## Workflow: Adding a Structural Command

Structural commands require parsing logic in `MTMathListBuilder.swift:atomForCommand()`.

1. **Add a new `else if` branch** in `atomForCommand()` for the command name
2. **Create the appropriate atom subclass**:
   - `MTFraction` — for fraction-like structures (`\frac`, `\binom`, `\cfrac`)
   - `MTRadical` — for root structures (`\sqrt`)
   - `MTInner` — for delimited groups (`\bra`, `\ket`)
   - `MTMathTable` — for matrix/tabular environments
3. **Parse arguments** using `self.buildInternal(true)` for `{...}` args
4. **Handle optional arguments** by checking for `[` and parsing with `buildInternal(false, stopChar: "]")`
5. **Add typesetting support** in `MTTypesetter.swift` if the atom needs custom layout

## Workflow: Adding an Environment

1. **For matrix-style environments**: Add to `matrixEnvs` in `MTMathAtomFactory.swift`:
   ```swift
   "envname": ["leftDelim", "rightDelim"],  // or [] for no delimiters
   ```
2. **For other environments**: Add handling in `table(withEnvironment:)` method
3. Configure: column count validation, alignment pattern, spacing, delimiters

Current environments: `matrix`, `pmatrix`, `bmatrix`, `Bmatrix`, `vmatrix`, `Vmatrix`, `smallmatrix`, starred variants, `aligned`, `eqalign`, `split`, `gather`, `displaylines`, `eqnarray`, `cases`

## Workflow: Validating Correctness

1. **Atom type check** — Wrong type = wrong spacing. Compare against KaTeX (`references/katex-functions.md`)
2. **Round-trip test** — Parse LaTeX → build MTMathList → convert back to LaTeX. Must match.
3. **Visual check** — Render and compare against KaTeX (katex.org) or LaTeX output
4. **Spacing check** — See `references/tex-spacing.md` for expected spacing between atom types
5. **Font check** — Ensure the Unicode glyph exists in the math font's coverage

## Multiline / Line Breaking

The typesetter supports automatic line breaking when `preferredMaxLayoutWidth` is set on `MTMathUILabel`. See `references/multiline-breaking.md` for full architecture details.

### How It Works

A two-tier system handles line breaks:
1. **Interatom breaking** (primary) — checks before each atom if adding it would exceed `maxWidth`; if so, flushes the current line
2. **Universal breaking** (fallback) — uses Core Text word boundary breaking for long text atoms

Complex atoms (fractions, radicals, large operators, delimiters, colored expressions, matrices, scripted atoms) all use a "create-then-check" pattern: build the display first, then check if it fits before deciding to break.

### Break Quality Scoring

A penalty system with 3-atom look-ahead selects aesthetically better break points:
- **Penalty 0** (best): after `+`, `=`, `,` (binary operators, relations, punctuation)
- **Penalty 10**: after ordinary atoms
- **Penalty 100**: after open brackets / before close brackets
- **Penalty 150**: after large operators

### Dynamic Line Height

Line spacing is computed from actual content height (max ascent + descent + padding) rather than a fixed multiplier. Lines with fractions get more vertical space; simple variable lines stay compact.

### Key Implementation Points

- `maxWidth` is propagated to all nested `createLineForMathList()` calls (color, inner, delimiters)
- Height threshold for large operators: `fontSize × 2.5`
- Early exit optimization skips breaking checks when remaining content clearly fits
- Tests: 97 typesetter tests in `MTTypesetterTests.swift`

## Writing Tests

Tests live in `Tests/SwiftMathTests/MTMathListBuilderTests.swift`.

Standard test pattern:
```swift
func testMyCommand() throws {
    let list = MTMathListBuilder.build(from: "\\commandname")!
    XCTAssertEqual(list.atoms.count, 1)
    let atom = list.atoms[0]
    XCTAssertEqual(atom.type, .relation)  // or whatever type
    XCTAssertEqual(atom.nucleus, "\u{XXXX}")

    // Round-trip test
    let latex = MTMathListBuilder.toLatex(list)
    XCTAssertEqual(latex, "\\commandname ")
}
```

For structural commands, verify the internal structure:
```swift
func testFracCommand() throws {
    let list = MTMathListBuilder.build(from: "\\frac{1}{2}")!
    XCTAssertEqual(list.atoms.count, 1)
    let frac = list.atoms[0] as! MTFraction
    XCTAssertEqual(frac.type, .fraction)
    XCTAssertEqual(frac.numerator?.atoms.count, 1)
    XCTAssertEqual(frac.denominator?.atoms.count, 1)
}
```

Build and test:
```bash
swift build
swift test --filter MTMathListBuilderTests
```
