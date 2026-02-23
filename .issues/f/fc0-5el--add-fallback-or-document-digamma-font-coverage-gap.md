---
# fc0-5el
title: Add fallback or document digamma font coverage gap
status: completed
type: bug
priority: low
created_at: 2026-02-23T03:36:08Z
updated_at: 2026-02-23T04:56:01Z
---

In MathAtomFactory.swift:152, there's a comment: 'digamma not supported by Latin Modern Math'. This means \digamma may not render correctly with the default font. Options: add a fallback glyph, document which fonts support it, or add a runtime warning.


## Summary of Changes

Added `\digamma` (U+03DD) and `\Digamma` (U+03DC) back to the symbol table in `SymbolTable.swift`. These glyphs are missing from Latin Modern Math (the default font) but are present in XITS, Libertinus, and Garamond math fonts. The existing fallback mechanism in `findGlyphForCharacterAtIndex` already handles missing glyphs gracefully by rendering `.notdef`, so no additional fallback logic was needed.

Updated the `greekVariants` test in `MathListBuilderSymbolTests` to include `digamma`.
