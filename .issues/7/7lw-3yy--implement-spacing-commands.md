---
# 7lw-3yy
title: 'Add \: spacing command alias'
status: ready
type: feature
priority: normal
created_at: 2026-02-22T16:44:34Z
updated_at: 2026-02-22T17:52:42Z
sync:
    github:
        issue_number: "1"
        synced_at: "2026-02-22T18:51:00Z"
---

Add support for the remaining fine spacing commands. `\,` (thin space) already works, but the others are missing.

Currently returns: `Invalid command \:` (and similar for others)

## Commands to Implement

| Command | Description | Width |
|---------|-------------|-------|
| `\:` | Medium space | 4/18 em |
| `\;` | Thick space | 5/18 em |
| `\!` | Negative thin space | -3/18 em |

## Examples

```latex
\int\!\!\!\int f(x,y) dx dy      % tight double integral
x \, y \: z \; w                  % mixed spacing
```

## Use Cases

- Fine typography control
- Integral notation (negative space for tight double integrals)
- Custom spacing in complex expressions

## Implementation Notes

- Insert proper `MathSpace` atoms with appropriate widths
- `\,` is already implemented (3/18 em) — use as reference


## Update (from TeXShop evaluation)

`\;` and `\!` already work — they are mapped in `MathAtomFactory.supportedLatexSymbols` as:
- `";"` → `MathSpace(space: 5)` (thick space, 5/18 em) ✅
- `"!"` → `MathSpace(space: -3)` (negative thin space, -3/18 em) ✅

Only `\:` is actually missing. It should map to `MathSpace(space: 4)`, same as the existing `">"` entry.

### Fix

Add to `supportedLatexSymbols` in `Sources/MathViews/MathRender/MathAtomFactory.swift` (around line 535):

```swift
":" : MathSpace(space: 4),
```
