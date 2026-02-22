---
# vil-l6i
title: Update identifiers to reflect toba/math-views origin
status: completed
type: task
priority: normal
created_at: 2026-02-22T17:01:27Z
updated_at: 2026-02-22T17:22:06Z
parent: 1ve-o8n
---

## Goal

Update all project identifiers to reflect the current GitHub origin (`toba/math-views`) and bundle identifier (`app.toba.maths`).

## Changes

- [x] **Rename Swift package and targets** — In `Package.swift`: `SwiftMath` → `MathViews`, `SwiftMathTests` → `MathViewsTests`
- [x] **Rename source directories** — `Sources/SwiftMath/` → `Sources/MathViews/`, `Tests/SwiftMathTests/` → `Tests/MathViewsTests/`
- [x] **Update all module imports** — `@testable import SwiftMath` → `@testable import MathViews` across ~28 test files
- [x] **Update GitHub URLs** — Replace `mgriebling/SwiftMath` and `mgriebling/SwiftMathDemo` URLs with `toba/math-views` equivalents in README.md, LICENSE, .jig.yaml, and test comments
- [x] **Remove file header comments** — Strip `Created by` / `Translated by` / author attribution lines from all source file headers
- [x] **Update README branding** — Replace "SwiftMath" project name references with "MathViews" (or "math-views") throughout README.md, EXAMPLES.md, MISSING_FEATURES.md
- [x] **Update example import statements** — `import SwiftMath` → `import MathViews` in README code examples
- [x] **Remove MT type prefix** — Rename all public types from `MTFoo` to `Foo` (MTMathList → MathList, MTFont → Font, MTTypesetter → Typesetter, etc.) — this is a large mechanical change, may warrant its own sub-task
- [x] **Verify build and tests pass** after all renames

## Out of Scope

- `mathFonts.bundle` resource bundle name (keeping as-is)
- Copyright notices in LICENSE (these stay as-is for legal attribution)
- Historical references to iosMath in LICENSE (legal requirement)


## Summary of Changes

Renamed package from SwiftMath to MathViews, moved directories, updated all imports and GitHub URLs, removed file header comments, updated README/CLAUDE.md branding, and removed MT prefix from 51 types across 57 Swift files. All 550 tests pass.
