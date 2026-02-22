---
# ziw-odj
title: Swift Concurrency & Strict Sendability
status: ready
type: epic
priority: normal
created_at: 2026-02-22T17:08:14Z
updated_at: 2026-02-22T17:12:19Z
parent: 1ve-o8n
blocking:
    - 3ss-4pl
blocked_by:
    - 0v4-vm2
sync:
    github:
        issue_number: "7"
        synced_at: "2026-02-22T17:29:41Z"
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
