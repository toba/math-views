---
# 09r-bjr
title: Extract font metric magic numbers into named constants
status: completed
type: task
priority: normal
tags:
    - type-tightening
created_at: 2026-02-23T05:15:19Z
updated_at: 2026-02-23T05:21:40Z
parent: cja-asi
---

Several magic numbers used for font metrics and spacing lack descriptive names. Extract each into a named constant with documentation.

## Tasks

- [ ] `MathTable.swift:121` — `1.01` → named constant `kFractionDelimiterMultiplier` (non-standard fraction delimiter size)
- [ ] `MathTable.swift:122` — `2.39` → named constant `kFractionDelimiterDisplayMultiplier` (display-style fraction delimiter)
- [ ] `Typesetter.swift:228` — `6.0` → named constant for minimum font size floor (prevents unreadable deeply-nested scripts)
- [ ] `Typesetter+Fractions.swift:163` — `1.5` → named constant for ruleless fraction gap multiplier
- [ ] `DisplayGenerator.swift:34` — `0.2` → named constant for minimum line spacing ratio
- [ ] `DisplayGenerator.swift:51` — `1.2` → named constant for minimum line spacing multiplier
- [ ] `MathTable.swift:264` — `0.6` → named constant for display-style variant target ratio
- [ ] Run tests

## Files

- `Sources/MathViews/Font/MathTable.swift`
- `Sources/MathViews/Typesetter/Typesetter.swift`
- `Sources/MathViews/Typesetter/Typesetter+Fractions.swift`
- `Sources/MathViews/Typesetter/Tokenization/DisplayGenerator.swift`


## Summary of Changes

Extracted 7 magic numbers across 4 files into named constants with documentation.
