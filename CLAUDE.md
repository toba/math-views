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

Source code is organized into pipeline-stage folders under `Sources/MathViews/`:

1. **Parser/** (`Builder.swift`, `Builder+Commands.swift`, `Builder+Environments.swift`, `ParseError.swift`) - Parses LaTeX strings into an abstract syntax tree (`MathList`). Handles math delimiters (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`), commands, environments.

2. **Atoms/** (`Atom.swift`, `Atom+Subclasses.swift`, `AtomType.swift`, `FontStyle.swift`, `List.swift`, `ListIndex.swift`, `Table.swift`, `Factory.swift`, `SymbolTable.swift`) - The AST representation. Contains `MathAtom` objects representing mathematical elements (variables, operators, fractions, radicals, etc.). Each atom has a `MathAtomType` that determines rendering and spacing.

3. **Typesetter/** (`Typesetter.swift`, `Spacing.swift`, `Italics.swift`, `Typesetter+Accents.swift`, `Typesetter+Fractions.swift`, `Typesetter+LargeOps.swift`, `Typesetter+Radicals.swift`, `Typesetter+Tables.swift`, `Typesetter+Tokenization.swift`) - Converts `MathList` to `Display` tree using TeX typesetting rules. Handles inter-element spacing, script positioning, and line breaking.

4. **Display/** (`Display.swift`, `Displays.swift`) - The display tree that knows how to draw itself via CoreText/CoreGraphics.

5. **Font/** (`Font.swift`, `Instance.swift`, `MathTable.swift`, `Image.swift`) - Font loading, math metrics, and OpenType MATH table parsing.

6. **UI/** (`View.swift`, `Color.swift`, `Symbol.swift`) - Platform view (`MathView`/`MathUILabel`), color abstraction, and Unicode symbol constants.

### Font System

Located in `Font/`:

- **MathFont** (`Font/Font.swift`) - Enum of 12 bundled OTF math fonts with thread-safe loading via `BundleManager`
- **FontInstance** (`Font/Instance.swift`) - Font wrapper with math metrics access
- **FontMathTable** (`Font/MathTable.swift`) - Parses OpenType MATH table data from `.plist` files

Each font has a `.otf` file and a companion `.plist` containing math metrics (generated via included Python script).

### Key Classes

- **MathAtomFactory** (`Atoms/Factory.swift`, `Atoms/SymbolTable.swift`) - Factory for creating atoms, includes command mappings (`aliases`, `delimiters`, `accents`, `supportedLatexSymbols`)

### Platform Abstraction

Cross-platform types defined in `UI/`:
- `PlatformColor` - UIColor/NSColor (`UI/Color.swift`)
- `MathView` - UIView/NSView (`UI/View.swift`, via `#if os(iOS)` conditionals)

### Line Wrapping / Tokenization

The typesetter supports automatic line breaking via `preferredMaxLayoutWidth` on `MathUILabel`. Uses interatom breaking (breaks between atoms) as primary mechanism, with Unicode word boundary breaking as fallback.

The tokenization subsystem lives in `Typesetter/Tokenization/` and handles:
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
