# Font System

How MathViews uses OpenType math fonts to render mathematical notation.

## Overview

Mathematical typesetting requires far more font information than regular text.
A math font must know how to:

- Stretch parentheses, braces, and radicals to arbitrary heights
- Position superscripts, subscripts, and fraction bars
- Provide larger variants of operators like `∑` and `∫` for display mode
- Supply italic corrections for proper script attachment

OpenType math fonts encode all of this in a specialized **MATH table** — a
binary data structure inside the font file.

## Bundled Fonts

MathViews bundles six OpenType math fonts, represented by the ``MathFont`` enum:

| Font | Style | Origin |
|------|-------|--------|
| `.latinModern` | Serif, matches Computer Modern (default LaTeX) | GUST |
| `.xits` | Serif, based on STIX | Khaled Hosny |
| `.termes` | Serif, Times-like | GUST |
| `.notoSans` | Sans-serif | Google |
| `.libertinus` | Serif, Libertine-based | Libertinus project |
| `.garamond` | Serif, Garamond-style | Yuansheng Zhao |

## Architecture: MathFont → FontInstance → FontMathTable

The font system has three layers:

- ``MathFont`` is the enum identifying which font to use. It handles loading
  the `.otf` file from the bundle and creating Core Text font objects (`CTFont`,
  `CGFont`).

- ``FontInstance`` wraps a `CTFont` at a specific point size. It provides access
  to glyph metrics and the math table. Use ``FontInstance/withSize(_:)`` to
  create a copy at a different size (needed for script styles).

- `FontMathTable` parses the font's math metrics. It provides constants
  (like subscript drop, fraction rule thickness) and glyph variant lookups
  (like larger integral signs or extensible braces).

## Why .plist Files Instead of Parsing the Binary MATH Table?

Each font has a companion `.plist` file containing the MATH table data. This
is a deliberate design choice: parsing the binary OpenType MATH table directly
would require a complex binary parser for a rarely-changing data format. The
`.plist` files are generated once from each font using a Python script
(`mathTableToMathPList.py`) and provide the same data in a format that Swift's
`PropertyListSerialization` reads trivially.

## Units

Font metrics use two unit systems:

- **Font design units** (or "em units") — The coordinate system the font is
  designed in. Most fonts use 1000 or 2048 units per em. The `FontMathTable`
  converts these to points using the font's units-per-em value.

- **Mu units** — TeX's relative spacing unit. 1 mu = 1/18 em. The
  ``MathSpace`` atom stores spacing in mu units, which scale automatically
  with font size. For example, `\quad` is 18 mu (= 1 em) and `\,` is 3 mu.
