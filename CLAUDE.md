# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run a single test class
swift test --filter MathListBuilderTests

# Run a specific test method
swift test --filter MathListBuilderTests.testBuilder
```

## Architecture Overview

MathViews is a Swift implementation of LaTeX math rendering for iOS (11+) and macOS (12+). It typesets LaTeX formulae using the same rules as LaTeX, rendering them natively via CoreText/CoreGraphics.

### Core Processing Pipeline

**LaTeX String → MathList → Display → Rendered Output**

1. **MathListBuilder** (`MathRender/MathListBuilder.swift`) - Parses LaTeX strings into an abstract syntax tree (`MathList`). Handles math delimiters (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`), commands, environments.

2. **MathList** (`MathRender/MathList.swift`) - The AST representation. Contains `MathAtom` objects representing mathematical elements (variables, operators, fractions, radicals, etc.). Each atom has a `MathAtomType` that determines rendering and spacing.

3. **Typesetter** (`MathRender/Typesetter.swift`) - Converts `MathList` to `Display` tree using TeX typesetting rules. Handles inter-element spacing, script positioning, and line breaking.

4. **Display** (`MathRender/Display.swift`) - The display tree that knows how to draw itself via CoreText/CoreGraphics.

5. **MathUILabel** (`MathRender/MathUILabel.swift`) - The UIView/NSView that hosts the rendered math. Entry point for most usage.

### Font System

Located in `MathBundle/`:

- **MathFont** (`MathFont.swift`) - Enum of 12 bundled OTF math fonts with thread-safe loading via `BundleManager`
- **FontInstance** (`MathRender/FontInstance.swift`) - Font wrapper with math metrics access
- **FontMathTable** (`MathRender/FontMathTable.swift`) - Parses OpenType MATH table data from `.plist` files

Each font has a `.otf` file and a companion `.plist` containing math metrics (generated via included Python script).

### Key Classes

- **MathAtomFactory** (`MathRender/MathAtomFactory.swift`) - Factory for creating atoms, includes command mappings (`aliases`, `delimiters`, `accents`, `supportedLatexSymbols`)
- **FontManager** (`MathRender/FontManager.swift`) - Manages font instances and defaults

### Platform Abstraction

Cross-platform types defined in `MathRender/`:
- `MathBezierPath` - UIBezierPath/NSBezierPath
- `MathColor` - UIColor/NSColor
- `MathView` - UIView/NSView (via `#if os(iOS)` conditionals)

### Line Wrapping / Tokenization

The typesetter supports automatic line breaking via `preferredMaxLayoutWidth` on `MathUILabel`. Uses interatom breaking (breaks between atoms) as primary mechanism, with Unicode word boundary breaking as fallback.

The tokenization subsystem lives in `MathRender/Tokenization/` and handles:
- **AtomTokenizer** - Converts atoms into breakable elements
- **LineFitter** - Fits elements into lines respecting width constraints
- **DisplayGenerator** - Produces final display objects from fitted lines
- **DisplayPreRenderer** - Pre-renders elements for width calculation
- **ElementWidthCalculator** - Calculates element widths including inter-element spacing
- **BreakableElement** - Represents an element that can participate in line breaking

## Skills

Skills provide detailed guides and workflows. Use skill triggers to load on demand.

| Area | Skill | One-liner |
|------|-------|-----------|
| Testing | `test` | SPM test commands, test file inventory, writing tests |
| DocC | `docc` | Documentation catalogs, symbol/article links, validation |
| Debugging | `debug` | LLDB attach, breakpoints, rendering pipeline diagnostics |
