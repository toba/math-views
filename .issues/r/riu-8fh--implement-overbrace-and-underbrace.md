---
# riu-8fh
title: Implement \overbrace and \underbrace
status: ready
type: feature
priority: normal
created_at: 2026-02-22T17:52:01Z
updated_at: 2026-02-22T17:52:01Z
sync:
    github:
        issue_number: "13"
        synced_at: "2026-02-22T18:51:00Z"
---

Support `\overbrace{content}^{annotation}` and `\underbrace{content}_{annotation}` structural commands.

Currently returns: `Invalid command \overbrace`

Source: TeXShop 5.57 completion.plist Math panel lists these as standard math decorations.

## Examples

```latex
\overbrace{x+y+z}^{3 \text{ terms}}
\underbrace{a+b+\cdots+z}_{26 \text{ letters}}
\underbrace{\overbrace{a+b}^{2}+c}_{3}   % nested
```

## Implementation Approach

Follow the `OverLine`/`UnderLine` pattern:

### 1. MathAtomType (`Sources/MathViews/MathRender/MathList.swift`)

No new atom types needed. Reuse `overline`/`underline` types OR extend the accent system. The key difference is the glyph and annotation positioning.

**Option A (recommended):** Create `OverBrace` and `UnderBrace` subclasses of `MathAtom` (like `OverLine` at line 540) with:
- `innerList: MathList?` — the content under/over the brace
- The atom's existing `superScript`/`subScript` carries the annotation

Add corresponding `case overbrace` and `case underbrace` to `MathAtomType` enum (line 8).

### 2. Parser (`Sources/MathViews/MathRender/MathListBuilder.swift`)

Add handling in TWO locations (the codebase has duplicate parsing paths):
- Around line 924 (alongside `overline`/`underline`)
- Around line 1385 (second parser path)

Pattern to follow:
```swift
} else if command == "overbrace" {
    let ob = OverBrace()
    ob.innerList = self.buildInternal(true)
    return ob
} else if command == "underbrace" {
    let ub = UnderBrace()
    ub.innerList = self.buildInternal(true)
    return ub
```

After parsing the command, the parser's existing superscript/subscript handling will attach `^{...}` or `_{...}` to the atom.

### 3. Typesetter (`Sources/MathViews/MathRender/Typesetter.swift`)

Add typesetting cases. The brace glyph is:
- U+23DE (⏞) for overbrace — TOP CURLY BRACKET
- U+23DF (⏟) for underbrace — BOTTOM CURLY BRACKET

These are stretchy horizontal braces that scale to match content width (similar to how `\widehat` works but horizontal).

Layout:
- **Overbrace**: content on bottom, stretchy brace above content, superscript annotation above brace
- **Underbrace**: content on top, stretchy brace below content, subscript annotation below brace

### 4. Round-trip (`MathListBuilder.swift`, `mathListToString`)

Add cases around line 669:
```swift
} else if atom.type == .overbrace {
    if let ob = atom as? OverBrace {
        str += "\\overbrace{\(mathListToString(ob.innerList!))}"
    }
} else if atom.type == .underbrace {
    if let ub = atom as? UnderBrace {
        str += "\\underbrace{\(mathListToString(ub.innerList!))}"
    }
}
```

## Checklist

- [ ] Add `OverBrace` and `UnderBrace` classes to `MathList.swift`
- [ ] Add `case overbrace` and `case underbrace` to `MathAtomType`
- [ ] Add parser support in `MathListBuilder.swift` (both parse paths)
- [ ] Add `mathListToString` round-trip support
- [ ] Add typesetter rendering in `Typesetter.swift`
- [ ] Add display support for stretchy horizontal brace glyph
- [ ] Add tests for basic parsing, annotation, nesting, and round-trip
