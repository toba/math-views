---
# zfj-6pd
title: Rename abbreviated variables to follow Swift API Design Guidelines
status: completed
type: task
priority: normal
created_at: 2026-02-23T03:41:21Z
updated_at: 2026-02-23T03:45:14Z
---

Rename cg/ct abbreviations to graphicsFont/coreTextFont, terse locals (rv, val, adv, ext, prev, consts) to descriptive names, snake_case to camelCase in Display.swift, and glyphsRv/offsetsRv in Typesetter+LargeOps.swift.

## Summary of Changes

Renamed abbreviated variables across 8 files to follow Swift API Design Guidelines:

- **MathFont.swift**: `cgFont()` → `graphicsFont()`, `ctFont(size:)` → `coreTextFont(size:)`, `CTFontSizePair` → `FontSizePair`, all internal CG/CT-prefixed methods and properties
- **FontInstance.swift**: `_cgFont`/`_ctFont` → `_graphicsFont`/`_coreTextFont`, `defaultCGFont` → `defaultGraphicsFont`, `ctFont` → `coreTextFont`
- **FontMathTable.swift**: `val` → `value`, `consts` → `constants`, `rv` → `parts`, `adv` → `advance`, `end` → `endConnector`, `start` → `startConnector`, `ext` → `extender`
- **Display.swift**: `max_ascent`/`max_descent`/`max_width` → camelCase
- **Typesetter+LargeOps.swift**: `glyphsRv` → `accumulatedGlyphs`, `offsetsRv` → `accumulatedOffsets`, `prev` → `previousPart`
- **Callers** (Typesetter+Accents.swift, ElementWidthCalculator.swift, DisplayGenerator.swift, MathFontTests.swift): updated all references to renamed API

All 543 tests pass, zero build warnings from these changes.
