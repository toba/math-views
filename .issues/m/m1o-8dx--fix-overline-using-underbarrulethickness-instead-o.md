---
# m1o-8dx
title: Fix overline using underbarRuleThickness instead of overbarRuleThickness
status: completed
type: bug
priority: high
created_at: 2026-02-23T04:52:30Z
updated_at: 2026-02-23T04:55:36Z
---

## Description

In `Typesetter+Accents.swift:40`, `makeOverline` uses `underbarRuleThickness` for the overbar line thickness:

```swift
overDisplay.lineThickness = styleFont.mathTable!.underbarRuleThickness
```

Should be `overbarRuleThickness`. These are distinct OpenType MATH constants. Most fonts set them to the same value, but it's semantically wrong.

## Tasks
- [x] Change `underbarRuleThickness` to `overbarRuleThickness` on line 40
- [x] Verify with `swift test`


## Summary of Changes

Changed `styleFont.mathTable!.underbarRuleThickness` to `styleFont.mathTable!.overbarRuleThickness` in `makeOverline` at `Typesetter+Accents.swift:40`.
