---
# ziw-odj
title: Swift Concurrency & Strict Sendability
status: ready
type: epic
priority: normal
created_at: 2026-02-22T17:08:14Z
updated_at: 2026-02-22T19:19:32Z
parent: 1ve-o8n
blocking:
    - 3ss-4pl
blocked_by:
    - 0v4-vm2
sync:
    github:
        issue_number: "7"
        synced_at: "2026-02-22T18:51:02Z"
---

Replace all lock-based concurrency with Swift concurrency primitives. Enable strict concurrency checking.

## Tasks

- [ ] Enable `swiftLanguageMode: .v6` and `-strict-concurrency=complete`
- [ ] Enable: `GlobalConcurrency`, `RegionBasedIsolation`, `InferSendableFromCaptures`, `DisableOutwardActorIsolation`, `NonisolatedNonsendingByDefault`
- [ ] Convert `BundleManager` (DispatchQueue) to actor or use `Mutex` (Synchronization framework, available at iOS 18+/macOS 15+)
- [ ] Remove 3 NSLocks in `MathAtomFactory` — convert lazy statics to eagerly-computed `static let`
- [ ] Remove `interElementLock` in `Typesetter` — make spacing table a `static let`
- [ ] Add `Sendable` conformances to `MathAtom`, `MathList`, `Display` hierarchies, font types
- [ ] Mark display tree `@MainActor` where appropriate (it's only used for rendering)

## Key Files

`MathFont.swift`, `MathAtomFactory.swift`, `Typesetter.swift`, `MathList.swift`, `Display.swift`


## Swift Review Guidance

### Complete Lock Inventory (7 primitives → 0)

| Lock | Location | Protects | Recommended Replacement |
|------|----------|----------|------------------------|
| `delimValueLock` (NSLock) | `MathAtomFactory.swift:65` | `_delimValueToName` dict | `static let` (immutable after init) |
| `accentValueLock` (NSLock) | `MathAtomFactory.swift:110` | `_accentValueToName` dict | `static let` (immutable after init) |
| `textToLatexLock` (NSLock) | `MathAtomFactory.swift:591` | `_textToLatexSymbolName` dict | `static let` (immutable after init) |
| `interElementLock` (NSLock) | `Typesetter.swift:16` | `interElementSpaceArray` | `static let` (spacing table is constant) |
| `fontInstanceV2Lock` (NSLock) | `FontInstanceV2.swift:40` | font instance cache | Eliminated by font consolidation (Epic 2) |
| `threadSafeQueue` (DispatchQueue) | `MathFont.swift:100` | `cgFonts`, `ctFonts`, `rawMathTables` | `Mutex<State>` from Synchronization framework |
| `RWLock` (pthread_rwlock) | `RWLock.swift:3` + `FontManager.swift:17` | `nameToFontMap` | Eliminated by FontManager removal (Epic 2) |

### Strategy: Static Let for Immutable Caches

4 of the 5 NSLocks protect lazily-built dictionaries that never change after initialization. Convert to eagerly-computed `static let`:

```swift
// Before (MathAtomFactory.swift:65-90)
private static let delimValueLock = NSLock()
private static var _delimValueToName = [String: String]()
static var delimValueToName: [String: String] {
    if _delimValueToName.isEmpty { delimValueLock.lock(); defer { delimValueLock.unlock() }; ... }
}

// After
static let delimValueToName: [String: String] = {
    var result = [String: String]()
    for (name, value) in delimiters { result[value] = name }
    return result
}()
```

### Strategy: Mutex for Font Cache

`BundleManager` (MathFont.swift:100) uses a concurrent `DispatchQueue` with barrier writes to protect 3 mutable dictionaries. Replace with `Mutex<FontCacheState>` (available iOS 18+/macOS 15+):

```swift
import Synchronization

struct FontCacheState: Sendable {
    var cgFonts: [MathFont: CGFont] = [:]
    var ctFonts: [FontSizePair: CTFont] = [:]
    var rawMathTables: [MathFont: NSDictionary] = [:]
}
let cache = Mutex(FontCacheState())
```

This is better than an actor here because font loading is synchronous (no await needed), and `Mutex` avoids the overhead of actor hop for every font access during typesetting.

### Sendable Conformance Plan

After removing NSObject and locks:
- `MathAtom` hierarchy → `Sendable` (value-like, should be immutable after construction). Audit for mutable `var` properties; convert to `let` where possible or use `sending` for cross-isolation transfer
- `MathList` → `Sendable` if atoms array becomes `let`, otherwise needs `@unchecked Sendable` with documented invariant
- `Display` hierarchy → `@MainActor` (only used during rendering on main thread)
- `FontInstance` (post-consolidation) → `Sendable` (immutable after creation)
- `MathFont` enum → already `Sendable` (enum with no associated values)

### @MainActor Scope

Mark the `Display` class hierarchy `@MainActor` since it draws via CoreText/CoreGraphics which must run on the main thread. This gives compile-time guarantees rather than runtime crashes. The `Typesetter` creates display objects but does not draw — it should remain nonisolated, with the handoff to `@MainActor` happening at the view layer.
