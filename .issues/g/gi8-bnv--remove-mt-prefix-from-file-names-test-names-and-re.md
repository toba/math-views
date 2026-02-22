---
# gi8-bnv
title: Remove MT prefix from file names, test names, and remaining identifiers
status: completed
type: task
priority: normal
created_at: 2026-02-22T17:34:45Z
updated_at: 2026-02-22T17:35:28Z
parent: 1ve-o8n
---

## Goal

Complete the MT prefix removal started in vil-l6i. That task renamed all type definitions but left file names, test class names, and `MTFont`/`MTFontV2` untouched.

## Changes

- [x] **Rename MTFont → FontInstance, MTFontV2 → FontInstanceV2, MTFontMathTableV2 → FontMathTableV2** — resolve the MathFont enum naming conflict by using `FontInstance` for the loaded-font wrapper class
- [x] **Rename `mtfont(size:)` → `fontInstance(size:)`** — update the MathFont extension method
- [x] **Rename MT-prefixed functions** — `MTGraphicsGetCurrentContext()` → `graphicsGetCurrentContext()`, `MTAssertNotSpace()` → `assertNotSpace()`
- [x] **Strip leftover header comments** from FontInstance.swift and PlatformTypes.swift
- [x] **Rename 25 source files** to match their primary type (e.g. MTMathList.swift → MathList.swift, MTTypesetter.swift → Typesetter.swift)
- [x] **Rename 15 test classes** to remove MT prefix (e.g. MTMathListBuilderTests → MathListBuilderTests)
- [x] **Rename 15 test files** to match their class names
- [x] **Update CLAUDE.md, README.md, MULTILINE_IMPLEMENTATION_NOTES.md** to reflect new names
- [x] **Verify zero MT[A-Z] references remain** in Sources/ and Tests/ (excluding issue files)
- [x] **Build and tests pass** after all changes

## Approach

Four phases, each independently compilable:
1. Type/function/constant renames (sed, build+test)
2. Source file renames (git mv, build+test)
3. Test class + file renames (sed + git mv, build+test)
4. Documentation updates + final grep audit

## Summary of Changes

Completed full MT prefix removal across the codebase:

- **3 type renames**: MTFont → FontInstance, MTFontV2 → FontInstanceV2, MTFontMathTableV2 → FontMathTableV2
- **Function renames**: MTGraphicsGetCurrentContext → graphicsGetCurrentContext, MTAssertNotSpace → assertNotSpace, mtfont(size:) → fontInstance(size:)
- **Constant rename**: MTParseError → parseError
- **25 source files** renamed to remove MT prefixes
- **15 test files** renamed to remove MT prefixes
- **15 test classes** renamed to remove MT prefixes
- Updated all comments containing MT-prefixed references
- Updated CLAUDE.md, skill files, issue files, and docs/MULTILINE_IMPLEMENTATION_NOTES.md
- Final verification: 550 tests passing, zero `MT[A-Z]` references in Swift source
