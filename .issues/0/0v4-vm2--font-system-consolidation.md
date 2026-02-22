---
# 0v4-vm2
title: Font System Consolidation
status: ready
type: epic
priority: normal
created_at: 2026-02-22T17:08:00Z
updated_at: 2026-02-22T17:12:04Z
parent: 1ve-o8n
blocking:
    - ziw-odj
    - 3ss-4pl
blocked_by:
    - z9b-r1r
---

Eliminate the dual font system (legacy `MTFont`/`MTFontManager` vs modern `MTFontV2`/`MathFont`). Make `MathFont` enum the sole public API. Evaluate which bundled fonts provide distinct value.

## Tasks

- [ ] **Audit the 12 bundled fonts** — evaluate which provide distinct value (serif vs sans, weight coverage, glyph completeness, MATH table quality). Consider dropping fonts that overlap significantly to reduce bundle size (~180KB–800KB per .otf + companion .plist)
- [ ] Flatten `MTFont` + `MTFontV2` into a single type (struct or final class) created via `MathFont.instance(size:)`
- [ ] Merge `MTFontMathTable` + `MTFontMathTableV2` into one implementation
- [ ] Remove `MTFontManager` singleton and its `RWLock`/`@RWLocked` property wrapper
- [ ] Remove `MTMathImage` (legacy image renderer) — keep only `MathImage`
- [ ] Update all call sites: `MTTypesetter`, label/view code, tests

## Files to Remove

`MTFont.swift`, `MTFontManager.swift`, `MTFontV2.swift`, `MTMathImage.swift`, `RWLock.swift`

## Files to Modify

`MathFont.swift`, `MTFontMathTable.swift`, `MTTypesetter.swift`, `MathImage.swift`
