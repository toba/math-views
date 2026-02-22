---
# 0v4-vm2
title: Font System Consolidation
status: ready
type: epic
priority: normal
created_at: 2026-02-22T17:08:00Z
updated_at: 2026-02-22T19:19:32Z
parent: 1ve-o8n
blocking:
    - ziw-odj
    - 3ss-4pl
blocked_by:
    - z9b-r1r
sync:
    github:
        issue_number: "4"
        synced_at: "2026-02-22T18:51:02Z"
---

Eliminate the dual font system (legacy `FontInstance`/`FontManager` vs modern `FontInstanceV2`/`MathFont`). Make `MathFont` enum the sole public API. Evaluate which bundled fonts provide distinct value.

## Tasks

- [ ] **Audit the 12 bundled fonts** — evaluate which provide distinct value (serif vs sans, weight coverage, glyph completeness, MATH table quality). Consider dropping fonts that overlap significantly to reduce bundle size (~180KB–800KB per .otf + companion .plist)
- [ ] Flatten `FontInstance` + `FontInstanceV2` into a single type (struct or final class) created via `MathFont.instance(size:)`
- [ ] Merge `FontMathTable` + `FontMathTableV2` into one implementation
- [ ] Remove `FontManager` singleton and its `RWLock`/`@RWLocked` property wrapper
- [ ] Remove `MathImageRenderer` (legacy image renderer) — keep only `MathImage`
- [ ] Update all call sites: `Typesetter`, label/view code, tests

## Files to Remove

`FontInstance.swift`, `FontManager.swift`, `FontInstanceV2.swift`, `MathImageRenderer.swift`, `RWLock.swift`

## Files to Modify

`MathFont.swift`, `FontMathTable.swift`, `Typesetter.swift`, `MathImage.swift`


## Swift Review Guidance

### Generic Consolidation: FontManager Methods

`FontManager.swift:31-76` has 12 nearly-identical public methods (`latinModernFont(withSize:)`, `kpMathLightFont(withSize:)`, etc.) that each just delegate to a font-specific loader. These are eliminated entirely when `FontManager` is removed — `MathFont.instance(size:)` replaces all 12.

### Shared Functionality: Lazy-Init Triple Pattern

`MathAtomFactory.swift` has 3 instances of an identical double-checked locking pattern:
1. `delimValueLock` + `_delimValueToName` (lines 65-90)
2. `accentValueLock` + `_accentValueToName` (lines 110-136)
3. `textToLatexLock` + `_textToLatexSymbolName` (lines 591-623)

Each follows: check nil → lock → check nil again → populate from dictionary → unlock. All three should become `static let` computed once (the dictionaries are immutable after first build). This eliminates 3 of the 5 `NSLock` instances.

### Font Audit Criteria

When evaluating the 12 bundled fonts, prioritize:
- **MATH table completeness** — fonts with incomplete tables cause fallback rendering artifacts
- **Glyph coverage** — especially for extended operators, integrals, delimiters at multiple sizes
- **Visual distinctiveness** — drop fonts that are near-duplicates in style/weight
- **Bundle cost** — each font is ~180KB-800KB .otf + companion .plist

### Performance: Public Generic Functions

After consolidation, if `MathFont.instance(size:)` or similar hot public API methods become generic, mark them `@inlinable` so client code gets specialized copies rather than paying protocol witness table dispatch (~4x overhead per call per WWDC25-308).
