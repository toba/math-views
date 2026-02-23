---
# 1ve-o8n
title: Modernization
status: completed
type: milestone
priority: normal
created_at: 2026-02-22T16:36:14Z
updated_at: 2026-02-23T00:51:19Z
sync:
    github:
        issue_number: "2"
        milestone_number: "1"
        synced_at: "2026-02-22T18:51:00Z"
---

## Goal

Modernize math-views for Swift 6.2 (Xcode 16.3+) with iOS 18+ / macOS 15+ platform minimums. Covers structural modernization, font system consolidation, strict concurrency, and SwiftUI migration. No backwards compatibility constraints.

## Target Configuration

- Swift 6.2 language mode, `-strict-concurrency=complete`
- Platforms: iOS 18+ / macOS 15+ (enables `Mutex` from Synchronization framework)
- Upcoming features: `ExistentialAny`, `GlobalConcurrency`, `RegionBasedIsolation`, `InferSendableFromCaptures`, `InternalImportsByDefault`, `IsolatedDefaultValues`, `DisableOutwardActorIsolation`, `NonisolatedNonsendingByDefault`, `MemberImportVisibility`

## Current State

- swift-tools-version 5.7, no strict concurrency checking
- 5 `NSLock` instances, 1 `DispatchQueue`, a custom `RWLock` wrapper
- Zero uses of async/await, actors, or `@Sendable`
- Dual font system (legacy `FontInstance`/`FontManager` + modern `FontInstanceV2`/`MathFont`)
- UIKit/AppKit view layer (`MathUILabel`) with `@IBDesignable`/`@IBInspectable`

## Child Epics

Dependency chain: Epic 1 → Epic 2 → Epic 3 → Epic 4

- [z9b-r1r] **Swift 6.2 Structural Modernization** — Remove ObjC heritage, enable Swift 6.2 features
- [0v4-vm2] **Font System Consolidation** — Eliminate dual font system, make `MathFont` sole API
- [ziw-odj] **Swift Concurrency & Strict Sendability** — Replace locks with Swift concurrency primitives
- [3ss-4pl] **SwiftUI Migration** — Replace UIKit/AppKit view layer with native SwiftUI

## Summary of Changes

All four epics completed in dependency order:

1. **Swift 6.2 Structural Modernization** (z9b-r1r) — Removed ObjC heritage, converted tests to Swift Testing, cleaned up MT prefixes and identifiers
2. **Font System Consolidation** (0v4-vm2) — Flattened V2 hierarchy, removed 6 fonts and FontManager, made MathFont the sole API
3. **Swift Concurrency & Strict Sendability** (ziw-odj) — Replaced 6 locks with static let and Mutex, added Sendable conformances, enabled strict concurrency
4. **SwiftUI Migration** (3ss-4pl) — Replaced UIKit/AppKit view layer with SwiftUI MathView, removed platform abstractions

Final state: Swift 6.2 language mode, strict concurrency complete, iOS 18+/macOS 15+ minimums, 549 tests passing.
