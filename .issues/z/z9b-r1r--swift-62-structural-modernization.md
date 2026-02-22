---
# z9b-r1r
title: Swift 6.2 Structural Modernization
status: ready
type: epic
priority: normal
created_at: 2026-02-22T17:07:47Z
updated_at: 2026-02-22T17:11:23Z
parent: 1ve-o8n
blocking:
    - 0v4-vm2
    - 3ss-4pl
sync:
    github:
        issue_number: "5"
        synced_at: "2026-02-22T17:29:41Z"
---

Remove Objective-C heritage and enable Swift 6.2 language features. This is the foundation — everything else depends on it.

## Tasks

- [ ] Bump `Package.swift` to swift-tools-version 6.2, raise platforms to iOS 18+ / macOS 15+
- [ ] Enable Swift 6.2 features: `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, `IsolatedDefaultValues`, `@concurrent`, `InlineArray`, `Span`, `sending`
- [ ] Remove NSObject inheritance from `MathAtom` (13 subclasses), `Display` (8+ subclasses), `MathList`
- [ ] Replace `NSError` with a Swift `Error` enum in `MathListBuilder`
- [ ] Replace `NSDictionary`/`NSNumber` with typed Swift dictionaries in font tables
- [ ] Replace `NSRange` with `Range<Int>` for `indexRange`
- [ ] Remove vestigial `isIos6Supported()` and `Display.initialized`/`.supported` statics

## Key Files

`Package.swift`, `MathList.swift`, `Display.swift`, `MathListBuilder.swift`, `FontMathTable.swift`, `FontMathTableV2.swift`
