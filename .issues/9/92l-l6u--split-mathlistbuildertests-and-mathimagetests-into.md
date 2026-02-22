---
# 92l-l6u
title: Split MathListBuilderTests and MathImageTests into separate files
status: completed
type: task
priority: normal
created_at: 2026-02-22T21:58:52Z
updated_at: 2026-02-22T22:08:43Z
---

MathListBuilderTests.swift (~3500 lines) and MathImageTests.swift (12+ structs) are too large. Split each into logical separate files.

## Summary of Changes

Split MathImageTests.swift into 11 files and MathListBuilderTests.swift into 6 files.

### MathImageTests split:
- MathImageTests.swift — shared code (MathImageResult, RenderCase, saveImage, Latex enum) + XCTest class
- 10 new files, one per render test struct (DelimiterSizingRenderTests, SymbolRenderTests, etc.)

### MathListBuilderTests split:
- MathListBuilderTests.swift (~1600 lines) — shared types (TestRecord, ParseErrorCase, checkAtomTypes) + core parsing tests
- MathListBuilderDelimiterTests.swift — inline/display delimiter tests (24 tests)
- MathListBuilderCommandTests.swift — command coverage + vector arrow tests (18 tests)
- MathListBuilderFeatureTests.swift — feature tests (11 tests)
- MathListBuilderSymbolTests.swift — symbol + negated relation tests (19 tests)
- MathListBuilderDiracTests.swift — Dirac + operatorname tests (9 tests)

536 tests in 39 suites, all passing.
