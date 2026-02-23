---
# aun-km5
title: 'Naming modernization: Obj-C → Swift conventions'
status: completed
type: task
priority: normal
created_at: 2026-02-23T02:25:15Z
updated_at: 2026-02-23T02:59:49Z
---

Rename internal and public names from Obj-C conventions to Swift API Design Guidelines. See plan for full list of renames across 14 categories.

## Summary of Changes

All 14 categories of renames applied across Sources/ and Tests/:

1. Display.swift init labels: `withFoo:` → `foo:` (9 inits)
2. `DownShift` → `Shiftable`, `DisplayDS` → `ShiftableDisplay`
3. `.ssubscript` → `.\`subscript\``
4. Typesetter.swift: 23 `get*` free functions and methods renamed
5. `createLineForMathList` → `makeLineDisplay(for:)`
6. FontMathTable: 7 `get*` methods renamed
7. FontInstance: 3 methods renamed (`glyphName`, `glyph(named:)`, `withSize`)
8. MathFont enum cases: dropped `Font` suffix (6 cases)
9. InterElementSpaceType: `ns*` → `nonScript*` (3 cases)
10. MathAtomFactory: 4 methods renamed
11. MathListBuilder: 3 methods renamed
12. MathList: `isNotScript` → `isAboveScript`, `isBinaryOperator`, `hasLimits`, `incremented()`, `latexString`, MathTable methods
13. Tokenization files: 4 renames (ElementWidthCalculator, DisplayPreRenderer)
14. `ctFont(withSize:)` → `ctFont(size:)`, Typesetter init label

Verification: swift build clean, 549 tests pass, swiftlint 0 violations.
