---
# cja-asi
title: 'Tighten types: eliminate Any, magic numbers, IUOs, and code duplication'
status: completed
type: epic
priority: high
tags:
    - type-tightening
created_at: 2026-02-23T05:15:36Z
updated_at: 2026-02-23T05:29:36Z
---

Systematic type-tightening pass identified by Swift review. Goals:
- Eliminate all `[String: Any]` in favor of typed `Codable` structs
- Replace magic numbers with named constants
- Remove IUOs and ObjC sentinel patterns
- Extract duplicated code

See child issues for individual tasks.


## Summary of Changes

All 9 child tasks completed across 8 commits. Key outcomes:

- **Eliminated all `[String: Any]`** in font plist parsing via `Codable` structs (`MathTableData`, `AssemblyEntry`, `PartEntry`)
- **Replaced ~30 magic numbers** with named constants across 7 files
- **Removed IUO** from `GlyphPart.glyph` (all fields now `let`)
- **Replaced `NSNotFound` sentinel** with `Int?` in `MathListDisplay.index`
- **Extracted duplicated code** in accent display construction (~80 lines removed)
- **Fixed pre-existing test compilation error** in `MathImageTests`

Only 2 unavoidable `as Any` casts remain (CoreText bridging in NSAttributedString attribute dicts).
