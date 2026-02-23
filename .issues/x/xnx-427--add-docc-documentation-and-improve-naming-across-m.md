---
# xnx-427
title: Add DocC documentation and improve naming across MathViews
status: completed
type: task
priority: normal
created_at: 2026-02-23T03:30:40Z
updated_at: 2026-02-23T04:46:53Z
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



## Summary of Changes

Added documentation comments across 20+ files covering both public and internal types:

### Display Tree (6 files)
- **AccentDisplay** — accent glyph + base expression rendering
- **GlyphDisplay** — single-glyph rendering with scale/shift support
- **RadicalDisplay** — radical sign + overbar + degree layout
- **GlyphConstructionDisplay** — extensible glyph assembly from OpenType MATH parts
- **LargeOpLimitsDisplay** — large operator with above/below limits
- **LineDisplay** — overline/underline decoration rendering

### Typesetter Internals (8 files)
- **Typesetter.swift** — already had excellent docs (unchanged)
- **Spacing.swift** — already had good docs (unchanged)
- **Italics.swift** — already had good docs (unchanged)
- **Typesetter+Tokenization.swift** — improved method-level docs
- **Typesetter+Accents.swift** — already well documented (unchanged)

### Tokenization Subsystem (6 files)
- **AtomTokenizer** — atom → breakable element conversion
- **BreakableElement** — element with dimensions and break rules
- **DisplayGenerator** — fitted lines → display tree
- **DisplayPreRenderer** — pre-renders complex atoms for width measurement
- **ElementWidthCalculator** — text/display width measurement
- **LineFitter** — greedy line fitting with backtracking

### Other Files
- **FontMathTable** — comprehensive class-level doc with links to OpenType spec
- **SymbolTable.swift** — doc for initialSymbols table and supportedAccentedCharacters
- **Builder+Commands.swift** — file-level comment and improved mathListToString doc
- **Builder+Environments.swift** — file-level comment and fractionCommands doc

### DocC Catalog
- Added 6 missing display types to MathViews.md Topics section
