---
# sxk-odn
title: Improve LaTeX round-trip fidelity for spaces
status: completed
type: task
priority: low
created_at: 2026-02-23T03:36:08Z
updated_at: 2026-02-23T05:04:39Z
---

In MathAtomFactory.swift:789,792, there are known limitations in the LaTeX-to-atom-to-LaTeX round-trip conversion, specifically around space handling. The mathListToString function doesn't always reproduce the original LaTeX exactly. Could improve fidelity for better round-trip support.


## Summary of Changes

### New space command aliases (SymbolTable.swift)
- `\thinspace` (3mu, alias for `\,`)
- `\:` and `\medspace` (4mu, aliases for `\>`)
- `\thickspace` (5mu, alias for `\;`)
- `\negthinspace` (-3mu, alias for `\!`)
- `\negmedspace` (-4mu, new)
- `\negthickspace` (-5mu, new)
- `\enspace` (9mu, new)

### `\mkern` parsing support (Builder+Commands.swift)
- Added `readMuDimension()` helper to parse numeric mu dimensions (e.g., `6.0mu`, `-2.5mu`)
- Added `\mkern` command handling in `atomForCommand()`
- The fallback serialization (`\mkern%.1fmu`) now round-trips correctly

### Reverse mapping (Builder.swift)
- Added `-4: "negmedspace"`, `-5: "negthickspace"`, `9: "enspace"` to `spaceToCommands`

### Parser fix (Builder+Environments.swift)
- Added `:` to `singleChars` in `readCommand()` so `\:` is recognized as a command

### Pre-existing fix (Spacing.swift)
- Added `.overbrace` and `.underbrace` to `interElementSpaceIndex` switch

### Tests (MathListBuilderFeatureTests.swift)
- `spaceAliasesRoundTrip` — all 8 verbose aliases parse and round-trip to canonical forms
- `mkernRoundTrip` — arbitrary mu values parse and serialize back
- `mkernNegativeValue` — negative mu values work
- `mkernKnownValueUsesCanonical` — `\mkern3mu` round-trips to `\,`
