# Rendering Pipeline

How MathViews converts a LaTeX string into rendered math.

## Overview

MathViews follows a four-stage pipeline modeled on how TeX itself works.
Each stage transforms the data into a form closer to pixels on screen.

```
LaTeX string ──► MathList (AST) ──► Display tree ──► CGContext drawing
     ▲                ▲                   ▲                ▲
  raw text      parsed atoms      positioned boxes    CoreText glyphs
```

## Stage 1: Parsing — LaTeX String to MathList

The entry point is ``MathListBuilder``. It reads a LaTeX string character by
character and produces a ``MathList`` — an ordered list of ``MathAtom`` objects.

### What is LaTeX math notation?

LaTeX uses special syntax for mathematical expressions:
- `$...$` or `\(...\)` for inline math (renders at text size)
- `$$...$$` or `\[...\]` for display math (renders larger, centered)
- Curly braces `{...}` group content
- Backslash commands like `\frac`, `\sqrt`, `\sum` create structures
- `^` and `_` attach superscripts and subscripts

For example, `\frac{x^2}{y}` means "a fraction with x² on top and y on the bottom."

### What are atoms?

Each ``MathAtom`` represents one mathematical element — a character, operator,
fraction, radical, or other structure. The atom's ``MathAtomType`` determines
both its visual rendering and the spacing around it. TeX defines specific
spacing rules between each pair of atom types (the "inter-element spacing matrix").

A ``MathList`` is simply a list of these atoms. Sub-expressions (like the
numerator of a fraction) are nested MathLists.

### Finalization

Before typesetting, the list is *finalized*: adjacent number atoms are fused
(so "1" and "2" become "12"), and binary operators at the start or end of
expressions are reclassified as unary operators (so the "-" in "-x" isn't
treated as subtraction).

## Stage 2: Typesetting — MathList to Display Tree

The typesetter walks the finalized ``MathList`` and creates a tree of
``Display`` objects. This is where TeX's layout rules are applied:

- **Inter-element spacing** — The typesetter looks up spacing between each pair
  of atom types in a matrix derived from TeX. For example, there is thick space
  around relation operators (=, <, >) but no space after an open parenthesis.

- **Script positioning** — Superscripts and subscripts are positioned using font
  metrics from the OpenType MATH table (see <doc:FontSystem>). The typesetter
  accounts for cramped mode (scripts are slightly lower inside radicals and
  denominators).

- **Math styles** — TeX has four nested styles: display, text, script, and
  script-of-script. Each level renders smaller. Fractions and scripts
  automatically step down one level.

- **Large operators** — Operators like `∑` and `∫` render larger in display
  mode and can have limits above and below.

- **Delimiters** — `\left` and `\right` delimiters grow to match their content
  using glyph variants and construction recipes from the font.

## Stage 3: Drawing — Display Tree to Pixels

Each ``Display`` node knows how to draw itself into a `CGContext`:

- ``CTLineDisplay`` renders character sequences using Core Text. It creates a
  `CTLine` from an `NSAttributedString` and calls `CTLineDraw`.

- ``FractionDisplay`` draws numerator, denominator, and the fraction rule line.

- ``MathListDisplay`` is a container that positions and draws its children.

### Coordinate system

Core Graphics uses a bottom-up coordinate system: the y-axis points upward.
This matches mathematical convention (superscripts go up). The ``Display``
stores `ascent` (distance above the baseline) and `descent` (distance below).
On iOS, the hosting view flips the context vertically since UIKit uses
top-down coordinates.

## Stage 4: Hosting — Presenting the Output

The rendered display tree can be hosted in:

- **MathView** — A `UIView` (iOS) or `NSView` (macOS) that displays the math.
  Set its `latex` property and it handles parsing, typesetting, and drawing.

- ``MathImage`` — Renders to a `CGImage` for use in SwiftUI, image export, or
  any context where a view isn't appropriate.
