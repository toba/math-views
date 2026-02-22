---
# fj9-4rx
title: Add \dag and \ddag aliases
status: ready
type: task
priority: low
created_at: 2026-02-22T17:52:01Z
updated_at: 2026-02-22T17:52:01Z
sync:
    github:
        issue_number: "14"
        synced_at: "2026-02-22T18:51:00Z"
---

Add standard LaTeX shorthand aliases for dagger symbols.

Source: TeXShop 5.57 completion.plist lists `\dag` and `\ddag` as standard commands.

## Implementation

Add to the `aliases` dictionary in `Sources/MathViews/MathRender/MathAtomFactory.swift` (line 6):

```swift
"dag" : "dagger",
"ddag" : "ddagger",
```

The target symbols already exist at lines 348-349:
```swift
"dagger" : MathAtom(type: .binaryOperator, value: "\u{2020}"),
"ddagger" : MathAtom(type: .binaryOperator, value: "\u{2021}"),
```

## Checklist

- [ ] Add `dag` and `ddag` to `aliases` dictionary
- [ ] Add test verifying `\dag` parses to same atom as `\dagger`
