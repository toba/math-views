---
# s53-e9u
title: Mark BundleManager as @MainActor for thread safety
status: completed
type: task
priority: normal
created_at: 2026-02-23T04:52:30Z
updated_at: 2026-02-23T04:55:36Z
---

## Description

`BundleManager` in `Font/Font.swift:82` is a singleton with mutable dictionaries accessed without synchronization. The `onDemandRegistration` method has a TOCTOU race. Currently mitigated by `defaultIsolation(MainActor.self)` but `BundleManager` itself isn't marked `@MainActor`.

## Tasks
- [x] Add `@MainActor` to `BundleManager` class
- [x] Verify it compiles without errors (all callers should already be on MainActor)
- [x] Run `swift test`


## Summary of Changes

Added `@MainActor` annotation to the `BundleManager` class in `Font/Font.swift`. Compiles cleanly since all call sites are already on MainActor via `defaultIsolation`.
