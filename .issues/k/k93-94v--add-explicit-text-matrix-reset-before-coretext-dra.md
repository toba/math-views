---
# k93-94v
title: Add explicit text matrix reset before CoreText drawing
status: completed
type: task
priority: normal
created_at: 2026-02-23T04:52:30Z
updated_at: 2026-02-23T04:55:36Z
---

## Description

Neither `MathImage.asImage()` nor `MathView.body` explicitly sets the text matrix to identity before calling `displayList.draw(context)`. `saveGState`/`restoreGState` do NOT save/restore the text matrix.

Currently safe because fresh contexts have identity text matrix, but fragile.

## Tasks
- [x] Add `context.textMatrix = .identity` in `Image.swift` before `displayList.draw(context)`
- [x] Add `cgContext.textMatrix = .identity` in `View.swift` before `info.displayList.draw(cgContext)`
- [x] Run `swift test`


## Summary of Changes

Added `context.textMatrix = .identity` in `Image.swift:145` and `cgContext.textMatrix = .identity` in `View.swift:59`, both before `displayList.draw()` calls.
