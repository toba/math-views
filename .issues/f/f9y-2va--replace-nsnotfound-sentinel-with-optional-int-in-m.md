---
# f9y-2va
title: Replace NSNotFound sentinel with Optional Int in MathListDisplay.index
status: completed
type: task
priority: low
tags:
    - type-tightening
created_at: 2026-02-23T05:15:23Z
updated_at: 2026-02-23T05:24:04Z
parent: cja-asi
---

\`MathListDisplay.swift:40\` uses \`index = NSNotFound\` as a sentinel for "not a script line." This is an Obj-C convention. Idiomatic Swift would use \`Int?\` with \`nil\` meaning "no script index."

## Scope

This is a public API change — audit all callers before changing.

## Tasks

- [ ] Audit all reads of \`MathListDisplay.index\` to find comparison sites
- [ ] Change \`public var index: Int\` to \`public var index: Int?\`
- [ ] Replace \`index = NSNotFound\` with \`index = nil\`
- [ ] Update all comparison sites (\`== NSNotFound\` → \`== nil\`, etc.)
- [ ] Run tests

## Files

- \`Sources/MathViews/Display/MathListDisplay.swift\`
- All files that read \`MathListDisplay.index\`


## Summary of Changes

Changed `MathListDisplay.index` from `Int` (NSNotFound sentinel) to `Int?` (nil for non-script). Updated all 28 test assertions.
