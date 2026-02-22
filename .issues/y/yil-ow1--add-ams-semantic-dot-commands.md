---
# yil-ow1
title: Add AMS semantic dot commands
status: ready
type: task
priority: deferred
created_at: 2026-02-22T17:52:01Z
updated_at: 2026-02-22T17:52:01Z
sync:
    github:
        issue_number: "12"
        synced_at: "2026-02-22T18:51:00Z"
---

Add amsmath semantic dot commands that select dot style based on context.

Source: TeXShop 5.57 Gratzer Math command completion list (GratzerMathCC/CommandCompletion.txt).

## Commands to Add

In real amsmath, these are context-sensitive. For math-views, mapping them to their most common rendering is sufficient.

Add to `supportedLatexSymbols` in `Sources/MathViews/MathRender/MathAtomFactory.swift`:

| Command | Renders as | Unicode | Context |
|---------|-----------|---------|---------|
| `\dotsb` | `\cdots` | U+22EF | Between binary operators |
| `\dotsc` | `\ldots` | U+2026 | Between commas |
| `\dotsm` | `\cdots` | U+22EF | For multiplication |
| `\dotsi` | `\cdots` | U+22EF | For integrals |
| `\dotso` | `\ldots` | U+2026 | Other contexts |

```swift
"dotsb" : MathAtom(type: .ordinary, value: "\u{22EF}"),
"dotsc" : MathAtom(type: .ordinary, value: "\u{2026}"),
"dotsm" : MathAtom(type: .ordinary, value: "\u{22EF}"),
"dotsi" : MathAtom(type: .ordinary, value: "\u{22EF}"),
"dotso" : MathAtom(type: .ordinary, value: "\u{2026}"),
```

## Checklist

- [ ] Add 5 dot commands to `supportedLatexSymbols`
- [ ] Add basic parse tests
