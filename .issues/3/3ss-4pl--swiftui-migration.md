---
# 3ss-4pl
title: SwiftUI Migration
status: ready
type: epic
priority: normal
created_at: 2026-02-22T17:08:27Z
updated_at: 2026-02-22T17:08:27Z
parent: 1ve-o8n
blocked_by:
    - z9b-r1r
    - 0v4-vm2
    - ziw-odj
sync:
    github:
        issue_number: "6"
        synced_at: "2026-02-22T17:29:41Z"
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
