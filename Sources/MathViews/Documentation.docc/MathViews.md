# ``MathViews``

Render LaTeX math formulae natively on Apple platforms using CoreText and CoreGraphics.

## Overview

MathViews typesets LaTeX math using the same rules as TeX. You give it a LaTeX string like `\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}` and it produces a rendered display that draws directly into a Core Graphics context — no web views or image downloads.

The rendering pipeline has four stages:

1. **Parse** — ``MathListBuilder`` turns a LaTeX string into a ``MathList`` (the abstract syntax tree).
2. **Typeset** — The typesetter converts the AST into a ``Display`` tree, applying TeX spacing and positioning rules.
3. **Draw** — Each ``Display`` node draws itself into a `CGContext` via CoreText and CoreGraphics.
4. **Host** — A platform view (`MathView`) or image renderer (``MathImage``) hosts the output.

Six bundled OpenType math fonts are included — see ``MathFont``.

## Topics

### Displaying Math

- ``MathView``
- ``MathImage``
- ``MathLabelMode``
- ``MathTextAlignment``

### Fonts

- ``MathFont``
- ``FontInstance``

### Parsing

- ``MathListBuilder``
- ``ParseError``

### Math Structure (AST)

- ``MathList``
- ``MathAtom``
- ``MathAtomType``
- ``FontStyle``
- ``LineStyle``

### Atom Subclasses

- ``Fraction``
- ``Radical``
- ``LargeOperator``
- ``Inner``
- ``Accent``
- ``Overline``
- ``Underline``
- ``MathSpace``
- ``MathStyle``
- ``MathColorAtom``
- ``MathTextColor``
- ``MathColorBox``
- ``MathTable``
- ``ColumnAlignment``

### Display Tree

- ``Display``
- ``CTLineDisplay``
- ``MathListDisplay``
- ``FractionDisplay``

### Indexing

- ``MathListIndex``

### Utilities

- ``MathAtomFactory``
- ``UnicodeSymbol``
- ``PlatformColor``

### Articles

- <doc:RenderingPipeline>
- <doc:FontSystem>
- <doc:LineBreaking>
