---
# nib-q8u
title: 'Test suite cleanup: deprecations, force casts, lint fixes'
status: completed
type: task
priority: normal
created_at: 2026-02-22T22:21:30Z
updated_at: 2026-02-22T22:37:51Z
---

Clean up test suite based on Swift review findings.

## Tasks

### High Priority
- [x] Migrate 73 `var error: NSError?` / `build(fromString:error:)` calls to throwing API (8 files)
  - [x] MathListBuilderFeatureTests (26 calls)
  - [x] MathListBuilderSymbolTests (24 calls)
  - [x] MathListBuilderDelimiterTests (10 calls)
  - [x] MathListBuilderTests (9 calls)
  - [x] MathListBuilderCommandTests
  - [x] TypesetterTests (3 calls)
  - [x] MathDelimiterTests (2 calls)
  - [x] MathFontTests (1 call)

### Medium Priority
- [x] Replace 64 force casts with `try #require(... as? Type)`
  - [x] MathListBuilderTests (37 casts)
  - [x] TypesetterTests (11 casts)
  - [x] MathListBuilderDelimiterTests (9 casts)
  - [x] MathListBuilderSymbolTests (5 casts)
  - [x] MathListTests (1 cast)
  - [x] MathListBuilderFeatureTests (1 cast)
- [ ] Consolidate duplicate `createTextElement()` in LineFitterTests / DisplayGeneratorTests (deferred — low priority)

### Low Priority
- [x] Fix 33 `empty_string` lint warnings
- [x] Fix `for_where` lint warnings (8 converted, 12 skipped — contain `as?` casts in body)
- [x] Fix 1 `sorted_first_last` warning

## Verification
- [x] All 549 tests pass
- [x] `swiftlint Tests/` — 12 remaining (all `for_where` in delimiter tests with `as?` casts)


## Summary of Changes

Reduced swiftlint violations from 128 to 12 (all remaining are legitimate `for_where` exceptions). Eliminated all NSError usage, all force casts, and most lint warnings across the test suite.
