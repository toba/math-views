---
# z9b-r1r
title: Swift 6.2 Structural Modernization
status: in-progress
type: epic
priority: normal
created_at: 2026-02-22T17:07:47Z
updated_at: 2026-02-22T20:13:14Z
parent: 1ve-o8n
blocking:
    - 0v4-vm2
    - 3ss-4pl
sync:
    github:
        issue_number: "5"
        synced_at: "2026-02-22T18:51:02Z"
---

Remove Objective-C heritage and enable Swift 6.2 language features. This is the foundation — everything else depends on it.

## Tasks

- [ ] Bump `Package.swift` to swift-tools-version 6.2, raise platforms to iOS 18+ / macOS 15+
- [ ] Enable Swift 6.2 features: `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, `IsolatedDefaultValues`, `@concurrent`, `InlineArray`, `Span`, `sending`
- [ ] Remove NSObject inheritance from `MathAtom` (13 subclasses), `Display` (8+ subclasses), `MathList`
- [ ] Replace `NSError` with a Swift `Error` enum in `MathListBuilder`
- [x] Replace `NSDictionary`/`NSNumber` with typed Swift dictionaries in font tables
- [ ] Replace `NSRange` with `Range<Int>` for `indexRange`
- [ ] Remove vestigial `isIos6Supported()` and `Display.initialized`/`.supported` statics

## Key Files

`Package.swift`, `MathList.swift`, `Display.swift`, `MathListBuilder.swift`, `FontMathTable.swift`, `FontMathTableV2.swift`


## Swift Review Guidance

### NSObject Removal (3 root classes, 21+ subclasses)

Root classes to de-NSObject:
- `MathAtom` (`MathList.swift:152`) — 13 subclasses: `Fraction`, `Radical`, `LargeOperator`, `Inner`, `OverLine`, `UnderLine`, `Accent`, `MathSpace`, `MathStyle`, `MathColorAtom`, `MathTextColor`, `MathColorbox`, `MathTable`
- `Display` (`Display.swift:30`) — 8 subclasses: `DisplayDS`, `CTLineDisplay`, `MathListDisplay`, `FractionDisplay`, `RadicalDisplay`, `LargeOpLimitsDisplay`, `LineDisplay`, `AccentDisplay`
- `MathList` (`MathList.swift:898`)

After removing `NSObject`, audit for implicit `NSObject` protocol conformances (`Hashable`, `Equatable`, `CustomStringConvertible`) that callers may depend on — add explicit conformances where needed.

### Overload Collapse → Default Parameters

`Typesetter.swift:435-463` has 6 overloads of `createLineForMathList` that all delegate to the final variant. Collapse into a single method with default parameters:

```swift
static func createLineForMathList(
    _ mathList: MathList?, font: FontInstance?, style: LineStyle,
    cramped: Bool = false, spaced: Bool = false, maxWidth: CGFloat = 0
) -> MathListDisplay?
```

~26 internal call sites use the short forms and will continue to compile unchanged.

### Typed Throws

`MathListBuilder.swift:26` defines `ParseErrors: Int` (raw-value enum). Convert to a proper `Error` enum and use typed throws:

```swift
enum ParseError: Error { case mismatchBraces, invalidCommand, ... }
func build() throws(ParseError) { ... }
```

`MathFont.swift:206` defines `FontError: Error` with 5 cases — already a single-type throw domain. Mark loading functions `throws(FontError)`.

### NSError Replacement

`MathListBuilder` currently uses `NSError` for parse errors. Replace with the typed `ParseError` enum above — eliminates the `NSError` dependency and enables typed throws in one step.

### NSDictionary/NSNumber Elimination

`FontMathTable.swift` / `FontMathTableV2.swift` use `NSDictionary`/`NSNumber` for plist-loaded font metrics. Replace with typed Swift dictionaries (`[String: Any]` → `[String: Int]` / `[String: [String: Int]]` where possible). Use `PropertyListDecoder` with `Codable` structs for the math table schema.
