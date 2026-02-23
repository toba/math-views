---
# loy-bif
title: Remove implicitly unwrapped optional from GlyphPart.glyph
status: completed
type: task
priority: low
tags:
    - type-tightening
created_at: 2026-02-23T05:15:24Z
updated_at: 2026-02-23T05:17:43Z
parent: cja-asi
---

\`MathTable.swift:9\` — \`var glyph: CGGlyph!\` is an IUO but the only construction site (\`MathTable.swift:349\`) always passes all fields via the memberwise init. The \`!\` can be replaced with a non-optional \`CGGlyph\`.

## Tasks

- [ ] Change \`var glyph: CGGlyph!\` to \`let glyph: CGGlyph\` in \`GlyphPart\`
- [ ] Verify the memberwise init still works (all callers provide the value)
- [ ] Make other stored properties \`let\` if they are never mutated after init
- [ ] Run tests

## Files

- \`Sources/MathViews/Font/MathTable.swift\`


## Summary of Changes

Changed all `GlyphPart` fields from `var` (with IUO and defaults) to `let`. Fixed pre-existing `MathImageTests` compilation error.
