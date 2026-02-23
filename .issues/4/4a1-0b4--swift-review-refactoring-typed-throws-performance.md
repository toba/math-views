---
# 4a1-0b4
title: 'Swift review: refactoring, typed throws, performance fixes'
status: completed
type: epic
priority: normal
created_at: 2026-02-23T01:47:48Z
updated_at: 2026-02-23T03:53:33Z
---

Comprehensive Swift review findings for the MathViews codebase (9,170 lines across 21 source files). Conducted 2026-02-22.

## Formatting & Linting Baseline

- `swift format -r -i .` applied
- `swiftlint --fix` applied (corrected 66 files)
- Remaining: **23 errors** (all force_cast), **60 warnings** (83 total)
  - 12 force cast violations in AtomTokenizer.swift and MathListBuilder.swift
  - 4 multiline_parameters in Typesetter.swift
  - 1 TODO in Typesetter.swift:528
  - 1 contains_over_first_not_nil in MathListBuilder.swift:1624
  - 1 for_where in MathListBuilder.swift:563

---

## 1. Shared Functionality Extraction

### HIGH — BreakableElement construction boilerplate (AtomTokenizer.swift:840-1165)

8 tokenize* functions create nearly identical BreakableElement instances with 15+ parameters:
- `tokenizeFraction()` lines 840-865
- `tokenizeRadical()` lines 867-901
- `tokenizeLargeOperator()` lines 903-982
- `tokenizeAccent()` lines 984-1039
- `tokenizeUnderline()` lines 1062-1086
- `tokenizeOverline()` lines 1088-1112
- `tokenizeTable()` lines 1114-1139
- `tokenizeInner()` lines 1141-1165

Extract helper:
```swift
private func makeBreakableElement(
  display: Display, atom: MathAtom,
  breakBefore: Bool, breakAfter: Bool,
  penaltyBefore: BreakPenalty, penaltyAfter: BreakPenalty,
  indivisible: Bool
) -> BreakableElement
```
~200 lines saved.

### MEDIUM — Display subclass position/color propagation (Display.swift)

7+ Display subclasses override `textColor` setter and `position` setter with identical child-propagation logic:
- FractionDisplay (lines 234-336): numerator + denominator
- LargeOpLimitsDisplay (lines 561-680): upperLimit + lowerLimit
- LineDisplay (lines 685-741): single inner
- AccentDisplay (lines 746-799): accentee

A protocol or base helper could eliminate ~200 lines.

### MEDIUM — Dictionary reversal logic (MathAtomFactory.swift:66-81 and 101-116)

`delimValueToName` and `accentValueToName` use identical reversal logic with shortest-key preference. Extract to generic `buildReverseMapping(_:)`.

### LOW — Empty display creation (Typesetter.swift:803, 1572)

Repeated `MathListDisplay(withDisplays: [], range:)` + position assignment.

---

## 2. Generic Consolidation

### HIGH — Character style converters (Typesetter.swift:79-301)

9 functions with identical structure, differing only in Unicode offset tables:
- `getItalicized` (line 79)
- `getBold` (line 108)
- `getBoldItalic` (line 129)
- `getDefaultStyle` (line 153)
- `getCaligraphic` (line 172)
- `getTypewriter` (line 216)
- `getSansSerif` (line 230)
- `getFraktur` (line 244)
- `getBlackboard` (line 271)

Each: check special cases → apply Unicode offset for upper/lower/Greek/digits → fall back. Consolidate into single data-driven function with lookup table per style. ~200 lines saved.

### HIGH — Force casts (as!) — 23 lint errors

**AtomTokenizer.swift:115-137** — 8 force casts dispatching atom types:
```
115: atom as! Fraction
118: atom as! Radical
121: atom as! LargeOperator
125: atom as! Accent
128: atom as! UnderLine
131: atom as! OverLine
134: atom as! MathTable
137: atom as! Inner
```

**MathList.swift** — 9 force casts in `finalized` overrides:
```
368: super.finalized as! Fraction
418: super.finalized as! Radical
510: super.finalized as! Inner
545: super.finalized as! UnderLine
574: super.finalized as! Accent
688: super.finalized as! MathColorAtom
720: super.finalized as! MathTextColor
752: super.finalized as! MathColorbox
790: super.finalized as! MathTable
```
These are structurally safe (subclass overrides) but a typed helper would silence lint.

**MathListBuilder.swift** — 4 force casts:
```
720: atom as! LargeOperator
722: atom as! LargeOperator
1247: atom as! LargeOperator
1256: atom as! LargeOperator
```

### MEDIUM — Finalization template (MathList.swift)

9 `finalized` overrides follow same pattern: cast super.finalized, recursively finalize child lists, return. Protocol-based template method could reduce this.

---

## 3. Typed Throws

### MEDIUM — BundleManager.loadCGFont(mathFont:) (MathFont.swift:97)

Only throws FontError. Change `throws` → `throws(FontError)`.
Error paths: lines 103, 108, 111, 116.

### MEDIUM — BundleManager.loadMathTable(mathFont:) (MathFont.swift:127)

Only throws FontError. Change `throws` → `throws(FontError)`.
Error paths: lines 133, 139.

### LOW — Test helper simplification (MathUILabelLineWrappingTests.swift:29-35)

Has `catch let e as ParseError` + unreachable generic `catch`. With typed throws on `buildChecked`, the second catch is dead code.

---

## 4. Structured Concurrency

Already well-positioned:
- Uses Mutex from Synchronization framework (no legacy DispatchQueue/NSLock)
- No completion handlers, no DispatchGroup, no Task.detached
- Appropriate Sendable conformances

### LOW — @unchecked Sendable audit

7 types use @unchecked Sendable: FontInstance, Display, MathAtom, MathList, FontMathTable, BundleManager, SymbolState. All immutable-by-convention. Document thread-safety invariants.

---

## 5. Swift 6.2 Modernization

No significant opportunities found (no Task.detached, no tuple-buffers, no UnsafeBufferPointer, no weak var, no @MainActor conformance issues).

---

## 6. Performance Anti-Patterns

### HIGH — O(n²) array copying in line fitting (LineFitter.swift:96-97)

Inside main line-fitting loop (`while i < elements.count`), every line break creates two Array() copies from slices:
```swift
let moveElements = Array(lines[lines.count - 1][breakIndex...])  // line 96
let oldLine = Array(lines[lines.count - 1][..<breakIndex])        // line 97
```
Fix: use index-based tracking instead of materializing arrays.

### HIGH — Unbounded loop in glyph construction (Typesetter.swift:1040)

```swift
for numExtenders in 0..<Int.max
```
Should have a reasonable upper bound (e.g., 1000) to prevent hangs on malformed font data.

### MEDIUM — Missing reserveCapacity in glyph arrays (Typesetter.swift:1041-1042)

`glyphsRv` and `offsetsRv` built via append in loop without pre-allocation. Final size can be estimated from `parts.count * repeats`.

### MEDIUM — String slice chaining in parser (MathListBuilder.swift:255-277)

```swift
let content = String(trimmed.dropFirst(2).dropLast(2))
```
4 instances. Use index-based subscripting to avoid redundant passes.

### MEDIUM — Width recalculation via reduce (LineFitter.swift:105, 134)

```swift
currentWidth = moveElements.reduce(0) { $0 + $1.width }
```
Recomputes total width from scratch on every line break. Incremental tracking would suffice.

### LOW — didSet clearing cached font (Typesetter.swift:418)

`style` property didSet clears `_styleFont`, triggering re-creation. Fine for correctness but notable if style is set repeatedly.

---

## Priority Summary

| Category | High | Medium | Low |
|----------|------|--------|-----|
| Shared Functionality | 1 | 2 | 1 |
| Generic Consolidation | 2 | 1 | 0 |
| Typed Throws | 0 | 2 | 1 |
| Structured Concurrency | 0 | 0 | 1 |
| Swift 6.2 | 0 | 0 | 0 |
| Performance | 2 | 3 | 1 |
| **Totals** | **5** | **8** | **4** |

Top 3 highest-impact items:
1. LineFitter O(n²) copying (performance, correctness)
2. Character style converter consolidation (~200 lines)
3. BreakableElement boilerplate extraction (~200 lines)


## Summary of Changes

Completed 2026-02-22. All 549 tests pass.

### Performance Fixes
- **LineFitter.swift**: Eliminated redundant `Array()` copies — split line uses slices directly, single materialization
- **Typesetter.swift**: Bounded glyph construction loop to 1000 iterations (was `Int.max`), added `reserveCapacity` for glyph arrays
- **MathListBuilder.swift**: Replaced 4 `dropFirst/dropLast` chains with index-based subscripting

### Code Deduplication
- **AtomTokenizer.swift**: Extracted `makeDisplayElement(_:atom:...)` helper, removing ~130 lines of BreakableElement boilerplate from 8 tokenize functions
- **MathAtomFactory.swift**: Extracted `buildReverseMapping(_:)` helper, deduplicating `delimValueToName` and `accentValueToName`

### Typed Throws
- **MathFont.swift**: `loadCGFont` and `loadMathTable` now use `throws(FontError)` instead of untyped `throws`

### Lint Fixes
- **MathListBuilder.swift**: Replaced 4 `as! LargeOperator` force casts with conditional binding
- **MathListBuilder.swift**: `firstIndex(of:) != nil` → `contains()`
- **MathListBuilder.swift**: `for + if` → `for...where`

### Remaining (deferred to child issues)
- 19 force_cast lint errors in MathList.swift (9 `finalized` overrides) and AtomTokenizer.swift (8 type dispatch + 2 other) — structurally safe, require deeper refactoring
- Character style converter consolidation (Typesetter.swift:79-301, 9 functions) — significant but low-risk, deferred
- Display subclass position/color propagation dedup — needs careful design


### Follow-up (2026-02-22)

- **Force casts**: Already eliminated in prior work (all 19 replaced with conditional binding)
- **Character style converters**: Consolidated 9 functions (italicized, bolded, boldItalic, defaultStyleChar, calligraphic, typewriter, sansSerif, fraktur, blackboard) into data-driven `CharStyleMap` struct + `applyMap` helper + 8 static map constants. Reduced ~200 lines to ~100. All 543 tests pass.
- **Display subclass textColor/position propagation**: Analyzed and declined. Each subclass propagates to different named children (~5 lines each); a protocol abstraction would add similar line count with more indirection. Net benefit near zero.
