---
# 6gp-s71
title: Add missing amssymb relation symbols
status: ready
type: task
priority: low
created_at: 2026-02-22T17:52:01Z
updated_at: 2026-02-22T17:52:01Z
sync:
    github:
        issue_number: "11"
        synced_at: "2026-02-22T18:51:00Z"
---

Add commonly-used amssymb relation symbols missing from MathAtomFactory.supportedLatexSymbols.

Source: TeXShop 5.57 completion.plist Symbols panel and Gratzer Math command completion list.

## Symbols to Add

Add to `supportedLatexSymbols` dictionary in `Sources/MathViews/MathRender/MathAtomFactory.swift` (around line 270, in the Relations section):

| Command | Type | Unicode | Description |
|---------|------|---------|-------------|
| `\lesssim` | `.relation` | U+2272 | Less-than or equivalent to |
| `\gtrsim` | `.relation` | U+2273 | Greater-than or equivalent to |
| `\lll` | `.relation` | U+22D8 | Very much less-than |
| `\ggg` | `.relation` | U+22D9 | Very much greater-than |
| `\lessgtr` | `.relation` | U+2276 | Less-than or greater-than |
| `\gtrless` | `.relation` | U+2277 | Greater-than or less-than |
| `\lesseqgtr` | `.relation` | U+22DA | Less-than equal or greater-than |
| `\gtreqless` | `.relation` | U+22DB | Greater-than equal or less-than |

## Implementation

Each is a one-line dictionary entry following the exact pattern of existing amssymb entries (lines 277-342):

```swift
"lesssim" : MathAtom(type: .relation, value: "\u{2272}"),
"gtrsim" : MathAtom(type: .relation, value: "\u{2273}"),
"lll" : MathAtom(type: .relation, value: "\u{22D8}"),
"ggg" : MathAtom(type: .relation, value: "\u{22D9}"),
"lessgtr" : MathAtom(type: .relation, value: "\u{2276}"),
"gtrless" : MathAtom(type: .relation, value: "\u{2277}"),
"lesseqgtr" : MathAtom(type: .relation, value: "\u{22DA}"),
"gtreqless" : MathAtom(type: .relation, value: "\u{22DB}"),
```

## Checklist

- [ ] Add 8 symbols to `supportedLatexSymbols`
- [ ] Add tests in `MathListBuilderTests.swift` verifying parse round-trip
- [ ] Verify glyphs render in Latin Modern Math font
