---
# 3ss-4pl
title: SwiftUI Migration
status: ready
type: epic
priority: normal
created_at: 2026-02-22T17:08:27Z
updated_at: 2026-02-22T19:19:33Z
parent: 1ve-o8n
blocked_by:
    - z9b-r1r
    - 0v4-vm2
    - ziw-odj
sync:
    github:
        issue_number: "6"
        synced_at: "2026-02-22T18:51:01Z"
---

Replace UIKit/AppKit view layer with native SwiftUI. Full replacement, not a wrapper.

## Tasks

- [ ] Create `MathView` as a SwiftUI `View` using `Canvas` (provides `CGContext` via `.withCGContext`)
- [ ] Compute intrinsic size from `Typesetter` output (ascent + descent + width) for proper SwiftUI layout
- [ ] Accept SwiftUI `Color` in public API, convert to `CGColor` at rendering boundary
- [ ] Replace `MathBezierPath` (UIBezierPath/NSBezierPath) with direct `CGPath`/`CGMutablePath` usage
- [ ] Replace `MathEdgeInsets` with SwiftUI `EdgeInsets`
- [ ] Error display: expose parse errors as optional state, render as `Text` instead of UILabel/NSTextField
- [ ] Update `MathImage` to produce SwiftUI `Image` (via `CGImage`)
- [ ] Remove: `MathUILabel.swift`, `MathLabel.swift`, `MathBezierPath.swift`, `PlatformTypes.swift`
- [ ] Remove `@IBDesignable`/`@IBInspectable` (no longer relevant)
- [ ] Update tests that reference removed view types

## Files to Create

`MathView.swift`

## Files to Remove

`MathUILabel.swift`, `MathLabel.swift`, `MathBezierPath.swift`, `PlatformTypes.swift`, `MathImageRenderer.swift`


## Swift Review Guidance

### Display Hierarchy is @MainActor (from Epic 3)

By the time this epic starts, `Display` and all subclasses (`CTLineDisplay`, `MathListDisplay`, `FractionDisplay`, `RadicalDisplay`, `LargeOpLimitsDisplay`, `LineDisplay`, `AccentDisplay`) should already be `@MainActor`. The SwiftUI `Canvas` closure runs on `@MainActor`, so the display tree can be used directly without isolation hops.

### CGPath Migration Details

`MathBezierPath` wraps `UIBezierPath`/`NSBezierPath` with `#if os(iOS)` conditionals. When replacing with `CGPath`/`CGMutablePath`:
- `Display.swift` draw methods use `MathBezierPath` for fraction bars, radical signs, and overline/underline decorations
- `CGPath` is `Sendable` (unlike UIBezierPath/NSBezierPath), which simplifies the concurrency model
- The `Canvas` GraphicsContext provides `.fill(Path(...))` and `.stroke(Path(...))` — construct SwiftUI `Path` from `CGPath` directly

### Typesetter Overloads (from Epic 1)

After Epic 1 collapses the 6 `createLineForMathList` overloads into one method with defaults, the SwiftUI `MathView` only needs to call:

```swift
Typesetter.createLineForMathList(mathList, font: font, style: style, maxWidth: availableWidth)
```

### Performance: Avoid Heap Allocation in View Body

In the SwiftUI `MathView`, avoid passing empty/single-element arrays to `some Collection` or `some Sequence` parameters. Use `EmptyCollection()` / `CollectionOfOne(x)` for stack-allocated alternatives when interfacing with the typesetter or display tree.

### Error Display

Expose `MathListBuilder` parse errors as an optional on the view model rather than catching and rendering inline. With typed throws from Epic 1 (`throws(ParseError)`), the SwiftUI layer gets precise error types:

```swift
struct MathView: View {
    let latex: String
    var body: some View {
        switch parsed {
        case .success(let display): Canvas { context, size in display.draw(context) }
        case .failure(let error): Text(error.localizedDescription).foregroundStyle(.red)
        }
    }
}
```
