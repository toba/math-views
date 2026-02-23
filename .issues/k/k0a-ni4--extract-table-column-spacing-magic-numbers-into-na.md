---
# k0a-ni4
title: Extract table column spacing magic numbers into named constants
status: completed
type: task
priority: normal
tags:
    - type-tightening
created_at: 2026-02-23T05:15:20Z
updated_at: 2026-02-23T05:20:00Z
parent: cja-asi
---

The value `18` (standard TeX inter-column spacing in mu = 1em) appears 3 times in `Factory.swift`, and `6` appears once for smallmatrix compact spacing.

## Current state

| Line | Value | Context |
|------|-------|---------|
| `Factory.swift:523` | `18` | matrix column spacing |
| `Factory.swift:523` | `6` | smallmatrix column spacing |
| `Factory.swift:589` | `18` | eqnarray column spacing |
| `Factory.swift:602` | `18` | cases column spacing |

## Tasks

- [ ] Add named constants (e.g. `TableSpacing.standard = 18`, `TableSpacing.compact = 6`) or a private enum
- [ ] Replace all 4 occurrences in `Factory.swift`
- [ ] Run tests

## Files

- `Sources/MathViews/Atoms/Factory.swift`


## Summary of Changes

Added `standardColumnSpacing` (18mu) and `compactColumnSpacing` (6mu) constants on `MathAtomFactory`. Replaced all 4 inline literals.
