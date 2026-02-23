---
# aqy-aew
title: Cache FontInstance in FontMathTable to avoid redundant allocations
status: completed
type: task
priority: normal
created_at: 2026-02-23T04:52:30Z
updated_at: 2026-02-23T04:55:36Z
---

## Description

Every call to `variants()`, `largerGlyph()`, `italicCorrection()`, `topAccentAdjustment()`, and `verticalGlyphAssembly()` in `Font/MathTable.swift` creates a new `FontInstance` via `mathFont.fontInstance(size: fontSize)`. These only need `CGFont` for `glyphName(for:)` and `glyph(named:)`.

## Tasks
- [x] Store a `CGFont` reference in `FontMathTable` init (already have `mathFont` which can provide it)
- [x] Add helper methods for glyph name lookup directly on `CGFont`
- [x] Replace all `mathFont.fontInstance(size: fontSize)` calls with direct CGFont lookups
- [x] Run `swift test` to verify no regressions


## Summary of Changes

Stored `CGFont` in `FontMathTable.init`, added private `glyphName(for:)` and `glyph(named:)` helpers that call `CGFont` directly. Replaced all 6 `mathFont.fontInstance(size: fontSize)` call sites with direct CGFont lookups, eliminating redundant `FontInstance` allocations.
