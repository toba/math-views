---
# fl5-9vy
title: Split TypesetterTests.swift into focused test files
status: completed
type: task
priority: normal
created_at: 2026-02-23T04:59:13Z
updated_at: 2026-02-23T05:06:24Z
---

Split the 3938-line TypesetterTests.swift into 8 focused files matching the source structure.

## Summary of Changes

Split TypesetterTests.swift (3938 lines) into 8 focused files:

- **TypesetterTestHelpers.swift** (~8 lines) — CGPoint.isEqual(to:accuracy:) extension
- **TypesetterTests.swift** (~1680 lines) — Core typesetter tests (variables, operators, scripts, fractions, radicals, large ops, inner, overline, underline, spacing, tables, symbols, styles, accents)
- **TypesetterVectorArrowTests.swift** (~180 lines) — Vector arrow rendering tests
- **TypesetterLineBreakingTests.swift** (~500 lines) — Interatom line breaking + complex display line breaking + additional edge cases
- **TypesetterComplexDisplayTests.swift** (~340 lines) — Large operator, delimiter, color, matrix, integration tests
- **TypesetterLayoutRegressionTests.swift** (~340 lines) — Sum equation layout regression + improved script handling
- **TypesetterBreakQualityTests.swift** (~230 lines) — Break quality scoring tests
- **TypesetterDynamicHeightTests.swift** (~260 lines) — Dynamic line height + table cell line breaking
- **TypesetterSafetyTests.swift** (~240 lines) — Safety tests: negative dimensions, NSRange overflow, invalid fraction range, atom width, safe UInt conversion, negative number after relation

All 123 Typesetter tests pass. Build is clean with 0 warnings.
