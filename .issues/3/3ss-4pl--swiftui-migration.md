---
# 3ss-4pl
title: SwiftUI Migration
status: ready
type: epic
created_at: 2026-02-22T17:08:27Z
updated_at: 2026-02-22T17:08:27Z
parent: 1ve-o8n
blocked_by:
    - z9b-r1r
    - 0v4-vm2
    - ziw-odj
---

Replace UIKit/AppKit view layer with native SwiftUI. Full replacement, not a wrapper.

## Tasks

- [ ] Create `MathView` as a SwiftUI `View` using `Canvas` (provides `CGContext` via `.withCGContext`)
- [ ] Compute intrinsic size from `MTTypesetter` output (ascent + descent + width) for proper SwiftUI layout
- [ ] Accept SwiftUI `Color` in public API, convert to `CGColor` at rendering boundary
- [ ] Replace `MTBezierPath` (UIBezierPath/NSBezierPath) with direct `CGPath`/`CGMutablePath` usage
- [ ] Replace `MTEdgeInsets` with SwiftUI `EdgeInsets`
- [ ] Error display: expose parse errors as optional state, render as `Text` instead of UILabel/NSTextField
- [ ] Update `MathImage` to produce SwiftUI `Image` (via `CGImage`)
- [ ] Remove: `MTMathUILabel.swift`, `MTLabel.swift`, `MTBezierPath.swift`, `MTConfig.swift`
- [ ] Remove `@IBDesignable`/`@IBInspectable` (no longer relevant)
- [ ] Update tests that reference removed view types

## Files to Create

`MathView.swift`

## Files to Remove

`MTMathUILabel.swift`, `MTLabel.swift`, `MTBezierPath.swift`, `MTConfig.swift`, `MTMathImage.swift`
