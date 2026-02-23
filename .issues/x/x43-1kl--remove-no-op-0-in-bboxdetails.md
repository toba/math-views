---
# x43-1kl
title: Remove no-op '- 0' in bboxDetails
status: completed
type: task
priority: low
created_at: 2026-02-23T04:52:30Z
updated_at: 2026-02-23T04:55:36Z
---

## Description

In `Typesetter/Italics.swift:158`:
```swift
ascent = max(0, bbox.maxY - 0)
```

The `- 0` is a no-op, likely a leftover. Should be `max(0, bbox.maxY)`.

## Tasks
- [x] Simplify to `max(0, bbox.maxY)`
- [x] Run `swift test`


## Summary of Changes

Removed no-op `- 0` from `max(0, bbox.maxY - 0)` in `Typesetter/Italics.swift:158`.
