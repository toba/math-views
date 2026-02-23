# Line Breaking

How MathViews breaks long mathematical expressions across multiple lines.

## Overview

When a math expression is too wide for its container, MathViews can
automatically break it across lines. Set `preferredMaxLayoutWidth` on the
hosting view to enable this. The line-breaking system uses a two-tier approach.

## Tier 1: Interatom Breaking (Primary)

The primary mechanism breaks between math atoms. Not all positions are equal —
each potential break point has a quality score:

- **Best** — After binary operators (`+`, `−`, `×`) and relation operators
  (`=`, `<`, `≥`). These are where mathematicians naturally break expressions.
- **Good** — After punctuation (commas in argument lists) and between
  ordinary atoms.
- **Acceptable** — Before open delimiters or after close delimiters.
- **Bad** — Inside grouped structures (fractions, radicals). Avoided unless
  the line would otherwise overflow.
- **Never** — Between a base and its scripts (`x` and `²` in `x²`), or
  inside words in `\text{}` commands.

The line fitter tries break points in quality order, using the best available
break that keeps each line within the width limit.

## Tier 2: Universal Breaking (Fallback)

When interatom breaking produces lines that still exceed the width limit — for
example, a single long `\text{}` block — the system falls back to Core Text
word-boundary breaking. This uses the Unicode text segmentation algorithm to
find word boundaries within text content.

For CJK (Chinese, Japanese, Korean) text inside `\text{}`, the system allows
breaks between any two CJK characters, following standard CJK line-breaking
conventions (kinsoku shori / 禁則処理).

## Dynamic Line Height

Each line computes its own height based on its content. A line containing only
variables has a shorter height than one containing a tall fraction or radical.
This produces tighter vertical spacing than using a fixed line height.

## Architecture

The line-breaking subsystem lives in `MathRender/Tokenization/` and consists of:

- `AtomTokenizer` — Converts atoms into ``BreakableElement`` values, each with
  width, break permissions, and penalty scores.
- `ElementWidthCalculator` — Measures element widths including inter-element
  spacing from the TeX spacing matrix.
- `LineFitter` — Fits elements into lines respecting the width constraint,
  choosing break points by penalty score.
- `DisplayGenerator` — Converts fitted lines back into ``Display`` objects
  for rendering.
- `DisplayPreRenderer` — Pre-renders complex structures (fractions, radicals)
  to determine their widths before line fitting.
