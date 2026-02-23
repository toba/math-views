---
# 6w7-qrn
title: Add named constant for plist version string
status: completed
type: task
priority: low
tags:
    - type-tightening
created_at: 2026-02-23T05:15:22Z
updated_at: 2026-02-23T05:18:14Z
parent: cja-asi
---

`Font.swift:132-133` has a hardcoded version string \`"1.3"\` with no named constant.

## Tasks

- [ ] Add \`private static let kExpectedPlistVersion = "1.3"\` (or similar) to \`BundleManager\`
- [ ] Replace inline \`"1.3"\` at line 133
- [ ] Run tests

## Files

- \`Sources/MathViews/Font/Font.swift\`


## Summary of Changes

Added `BundleManager.expectedPlistVersion` constant, replaced inline `"1.3"` literal.
