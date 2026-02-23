---
# xnx-427
title: Add DocC documentation and improve naming across MathViews
status: in-progress
type: task
created_at: 2026-02-23T03:30:40Z
updated_at: 2026-02-23T03:30:40Z
---

## Objectives
- [ ] Create Documentation.docc catalog with landing page and conceptual articles
- [ ] Add/improve documentation comments on all public types and methods
- [ ] Capture coding decision comments and actionable items as follow-up issues
- [ ] Rename confusing types per Swift API Design Guidelines

## Documentation Articles Needed
- Landing page (Main.md) with module overview and Topics
- Rendering Pipeline article explaining LaTeX → MathList → Display flow
- Font System article explaining MathFont, FontInstance, FontMathTable
- Line Breaking article explaining the tokenization subsystem

## Naming Issues to Address
- MathLabelMode → RenderingStyle (display/text are TeX math modes, not label modes)
- MathTextAlignment → already fine (mirrors SwiftUI)
- MathListSubIndexType → already fine
- LineStyle could use better docs (it's TeX math style, not line styling)

## Files Needing Documentation
- FontInstance.swift - no public docs
- PlatformColor.swift - no public docs  
- MathImage.swift - no public docs
- Typesetter extension files - no public docs
- UnicodeSymbol.swift - no public docs
