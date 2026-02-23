---
# 642-ufa
title: Extract duplicated AccentDisplay construction into helper method
status: completed
type: task
priority: normal
tags:
    - type-tightening
created_at: 2026-02-23T05:15:25Z
updated_at: 2026-02-23T05:25:59Z
parent: cja-asi
---

\`Typesetter+Accents.swift\` has three near-identical blocks that create a scaled \`GlyphDisplay\`, optionally reattach sub/superscripts to the accentee, and construct an \`AccentDisplay\`:

1. **Wide accents** (lines ~527-565)
2. **Stretchy arrows** (lines ~602-640)
3. **Regular accents** (lines ~654-694)

Each block:
- Creates \`GlyphDisplay\` with glyph, range, font
- Sets ascent, descent, width, position
- Optionally checks \`isSingleCharAccentee\` and reattaches scripts
- Creates \`AccentDisplay\` with accent + accentee
- Sets width, descent, ascent, position

## Tasks

- [ ] Extract a private helper method (e.g. \`buildAccentDisplay(glyph:range:glyphAscent:glyphDescent:glyphWidth:position:accent:accentee:height:)\`)
- [ ] Replace all three blocks with calls to the helper
- [ ] Run tests (especially accent-related: \`AccentSpacingComparisonTest\`, \`WidehatTests\`, \`DotlessIJAccentTests\`)

## Files

- \`Sources/MathViews/Typesetter/Typesetter+Accents.swift\`


## Summary of Changes

Extracted `makeScaledAccentGlyph` and `buildAccentDisplay` helpers, removing ~80 lines of triplicated code across wide accent, stretchy arrow, and regular accent paths.
