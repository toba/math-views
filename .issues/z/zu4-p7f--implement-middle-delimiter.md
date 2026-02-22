---
# zu4-p7f
title: Implement \middle delimiter
status: ready
type: feature
created_at: 2026-02-22T16:44:34Z
updated_at: 2026-02-22T16:44:34Z
---

Support `\middle` for use between `\left` and `\right` to add delimiters in the middle of expressions.

Currently returns: `Invalid command \middle`

## Examples

```latex
\left( \frac{a}{b} \middle| \frac{c}{d} \right)
\left\{ x \middle\| y \right\}
```

## Use Cases

- Set notation: `\left\{ x \middle| x > 0 \right\}`
- Conditional expressions
- Piecewise functions with multiple sections

## Implementation Notes

- Needs integration with existing `\left...\right` delimiter pairing system
- Should support all delimiter types that work with `\left` and `\right`
