---
# fc0-5el
title: Add fallback or document digamma font coverage gap
status: ready
type: bug
priority: low
created_at: 2026-02-23T03:36:08Z
updated_at: 2026-02-23T03:36:08Z
---

In MathAtomFactory.swift:152, there's a comment: 'digamma not supported by Latin Modern Math'. This means \digamma may not render correctly with the default font. Options: add a fallback glyph, document which fonts support it, or add a runtime warning.
