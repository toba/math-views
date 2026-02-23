---
# rgz-itr
title: Replace Any with generic or simplified signature in MathList.checkIndex
status: completed
type: task
priority: normal
created_at: 2026-02-23T02:25:24Z
updated_at: 2026-02-23T04:20:03Z
---

\`MathList.checkIndex(_:index:)\` at `MathList.swift:967` takes `[Any]` but is only ever called with `self.atoms` (`[MathAtom]`).

Simplest fix: remove the array parameter entirely since it's always `atoms`:

```swift
// Before
func checkIndex(_ array: [Any], index: Int) {
    precondition(array.indices.contains(index), "Index \(index) out of bounds")
}

// After
func checkIndex(_ index: Int) {
    precondition(atoms.indices.contains(index), "Index \(index) out of bounds")
}
```

Update call sites at lines 1014, 1020, 1021 to `checkIndex(index)` / `checkIndex(range.lowerBound)` etc.

Other `Any` uses in the codebase (FontMathTable plist access, NSAttributedString attributes) are dictated by Foundation/CoreText API contracts and are not addressable with generics.


## Summary of Changes

No changes needed — the fix was already applied during the source reorganization. `checkIndex` already uses the simplified signature `checkIndex(_ index: Int)` that references `atoms` directly, with no `[Any]` parameter.
