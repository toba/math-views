---
# 2fs-vw0
title: MathViews structural modernization
status: completed
type: task
priority: normal
created_at: 2026-02-23T03:18:38Z
updated_at: 2026-02-23T03:25:47Z
---

Three tasks:
- [x] Fix MathTable.finalized bug (value-type copy mutation)
- [x] Simplify checkIndex to remove [Any] parameter
- [x] Split Typesetter.swift into extension files

## Summary of Changes

Fixed MathTable.finalized bug where `for var row in table.cells` created local copies, silently discarding mutations. Now indexes into `table.cells` directly.

Simplified `checkIndex` by removing the `[Any]` parameter since it was only ever called with `self.atoms`.

Split Typesetter.swift (2,102 lines) into 5 focused extension files:
- Typesetter+Fractions.swift (fraction metrics and layout)
- Typesetter+Radicals.swift (radical metrics and layout)  
- Typesetter+LargeOps.swift (glyphs, large operators, and delimiters)
- Typesetter+Accents.swift (underline, overline, and accents)
- Typesetter+Tables.swift (table layout and positioning)

Core Typesetter.swift retained: spacing, scripts, font style, preprocessing (~696 lines).
