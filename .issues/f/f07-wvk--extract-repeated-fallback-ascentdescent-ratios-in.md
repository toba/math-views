---
# f07-wvk
title: Extract repeated fallback ascent/descent ratios in AtomTokenizer into named constants
status: completed
type: task
priority: high
tags:
    - type-tightening
created_at: 2026-02-23T05:15:18Z
updated_at: 2026-02-23T05:19:12Z
parent: cja-asi
---

The same magic-number fallback ratios for element sizing appear 6 times across `AtomTokenizer.swift`. Extract into named constants.

## Current state

| Lines | Pattern | Count |
|-------|---------|-------|
| 218, 332, 667, 756 | `font.fontSize * 0.5` (fallback ascent) | 4 |
| 219, 333, 668, 699, 727, 757 | `font.fontSize * 0.2` (fallback descent) | 6 |
| 698, 726 | `font.fontSize * 0.6` (delimiter ascent) | 2 |

## Tasks

- [ ] Add a `private enum FallbackMetrics` (or similar) with named ratio constants:
  - `ascentRatio: CGFloat = 0.5` — approximate ascent when math table data is unavailable
  - `descentRatio: CGFloat = 0.2` — approximate descent for line-break element sizing
  - `delimiterAscentRatio: CGFloat = 0.6` — approximate ascent for delimiter elements
- [ ] Replace all 12 occurrences in `AtomTokenizer.swift` with the named constants
- [ ] Run tests to verify no regressions

## Files

- `Sources/MathViews/Typesetter/Tokenization/AtomTokenizer.swift`


## Summary of Changes

Added `fallbackAscentRatio`, `fallbackDescentRatio`, `delimiterAscentRatio` static constants on `AtomTokenizer`. Replaced all 12 inline magic multipliers.
