---
# 8hk-j89
title: Guard against CGRect.null from CTLineGetBoundsWithOptions
status: completed
type: bug
priority: normal
created_at: 2026-02-23T04:52:30Z
updated_at: 2026-02-23T04:55:36Z
---

## Description

In `Display.swift:115`, `CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)` can return `CGRect.null` for empty/whitespace-only lines. The `max(0, bounds.maxY)` would produce `CGFloat.infinity`.

## Tasks
- [x] Add `bounds.isNull` check before using bounds values, falling back to 0
- [x] Run `swift test`


## Summary of Changes

Added `bounds.isNull` guard in `CTLineDisplay.init`. When null, ascent and descent default to 0, width uses typographic width only.
