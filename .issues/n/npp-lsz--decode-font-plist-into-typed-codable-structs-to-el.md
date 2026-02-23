---
# npp-lsz
title: 'Decode font plist into typed Codable structs to eliminate [String: Any]'
status: completed
type: task
priority: high
tags:
    - type-tightening
created_at: 2026-02-23T05:15:17Z
updated_at: 2026-02-23T05:29:24Z
parent: cja-asi
---

Replace all `[String: Any]` usage in the font plist parsing layer with typed `Codable` structs and `PropertyListDecoder`.

## Current state

`FontMathTable` stores `_mathTable: [String: Any]` and uses ~15 `as?` casts to extract values. `BundleManager` stores `rawMathTables = [MathFont: [String: Any]]()`. All 19 uses of `Any` in the codebase are in this layer.

## Tasks

- [ ] Define `MathTableData: Codable` struct with typed fields:
  - `version: String`
  - `constants: [String: Int]`
  - `v_variants: [String: [String]]` (vertical glyph variants)
  - `h_variants: [String: [String]]` (horizontal glyph variants)
  - `italic: [String: Int]`
  - `accents: [String: Int]`
  - `v_assembly: [String: AssemblyData]` with nested `AssemblyData` and `GlyphPartData`
- [ ] Define `GlyphPartData: Codable` to replace inline string keys (`"advance"`, `"endConnector"`, `"startConnector"`, `"extender"`, `"glyph"`) at `MathTable.swift:338-342`
- [ ] Replace `PropertyListSerialization` + `as? [String: Any]` in `BundleManager.loadMathTable` (`Font.swift:115-138`) with `PropertyListDecoder().decode(MathTableData.self, ...)`
- [ ] Change `FontMathTable._mathTable` from `[String: Any]` to `MathTableData`
- [ ] Remove all `as? [String: Any]` casts in `FontMathTable`
- [ ] Update `BundleManager.rawMathTables` to `[MathFont: MathTableData]`
- [ ] Remove `rawMathTable() -> [String: Any]` from `MathFont` (replace with typed accessor)
- [ ] Eliminate the 2 `as Any` casts in `ElementWidthCalculator.swift:32` and `DisplayGenerator.swift:388` if possible (these are CoreText bridging — may need to stay)
- [ ] Run all tests to verify no regressions

## Files

- `Sources/MathViews/Font/MathTable.swift` (primary)
- `Sources/MathViews/Font/Font.swift` (BundleManager)
- `Sources/MathViews/Typesetter/Tokenization/ElementWidthCalculator.swift`
- `Sources/MathViews/Typesetter/Tokenization/DisplayGenerator.swift`


## Summary of Changes

Defined `MathTableData`, `AssemblyEntry`, `PartEntry` as `Decodable` structs. Replaced `PropertyListSerialization` with `PropertyListDecoder`. Eliminated all 15 `as? [String: Any]` casts. Only 2 unavoidable `as Any` casts remain (CoreText bridging in NSAttributedString attribute dicts).
