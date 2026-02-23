---
# zsk-ftd
title: Extract accent variant thresholds and padding multipliers into named constants
status: completed
type: task
priority: low
tags:
    - type-tightening
created_at: 2026-02-23T05:15:21Z
updated_at: 2026-02-23T05:22:37Z
parent: cja-asi
---

The wide accent variant selection and arrow accent padding use several inline magic numbers that would benefit from named constants.

## Current state

| File:Line | Value | Context |
|-----------|-------|---------|
| `Typesetter+Accents.swift:389-397` | `2, 4, 6` | Char count thresholds for variant selection |
| `Typesetter+Accents.swift:389-397` | `1.0, 1.5, 2.0, 2.5` | Width multipliers per threshold |
| `Typesetter+Accents.swift:458` | `1.1` | Stretchy arrow extra width request multiplier |
| `Typesetter+Accents.swift:598` | `fontSize / 6` | Arrow padding (~0.167em) |
| `Typesetter+Accents.swift:523` | `fontSize / 10` | Wide accent padding (~0.1em) |

## Tasks

- [ ] Name the variant threshold/multiplier pairs (e.g. a static lookup table or switch constants)
- [ ] Name the stretchy arrow extra width multiplier
- [ ] Name the arrow padding and wide accent padding divisors
- [ ] Run tests

## Files

- `Sources/MathViews/Typesetter/Typesetter+Accents.swift`


## Summary of Changes

Extracted 5 accent constants. Replaced if/else variant selection with data-driven tier lookup.
