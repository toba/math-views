---
# 2eh-dil
title: Rename abbreviated variables to Swift API Design Guidelines (iteration 2)
status: completed
type: task
priority: normal
created_at: 2026-02-23T04:26:02Z
updated_at: 2026-02-23T04:37:07Z
---

Rename ~100+ abbreviated variables across 15 files to use clear, descriptive names per Swift API Design Guidelines.

## Summary of Changes

Renamed ~120 abbreviated variables across 15 files to use clear, descriptive names per Swift API Design Guidelines:

- **ParseError.swift**: `m` → `message` in switch case bindings
- **Image.swift**: `fontInst` → `fontInstance`
- **Symbol.swift**: `uch` → `unicodeCharacter`, `pos` → `position`
- **Display.swift**: `attrString` → `attributedString` (using `self.` disambiguation)
- **Italics.swift**: `ch` → `character`, `v` → `exceptionValue`, `u` → `codePoint`, `s` → `rangeStart`, `str` → `input`, `retval` → `result`
- **Typesetter.swift**: `ml` → `mathList`
- **Typesetter+Fractions.swift**: `frac` → `fraction`, `numDisplay`/`denomDisplay` → `resolvedNumerator`/`resolvedDenominator`
- **Typesetter+LargeOps.swift**: `op` → `largeOperator`, `d1`/`d2` → `axisDistance`/`paddingDistance`
- **Typesetter+Tables.swift**: `col` → `column`, `colWidth` → `columnWidth`, `cellPos` → `cellPosition`, `lo`/`hi` → `lowerBound`/`upperBound`, `currPos` → `currentRowPosition`
- **Typesetter+Accents.swift**: `curGlyph` → `currentGlyph`
- **Atom+Subclasses.swift**: all copy-init params → `source`
- **Factory.swift**: `ch` → `character`, `chStr` → `characterString`, `num`/`denom` → `numerator`/`denominator`, `delims` → `delimiters`, `frac`/`rad` → `fraction`/`radical`
- **Builder.swift**: `ch`/`char` → `character`, `str` → `input`, `stop` → `stopCharacter`, `nextChar` → `expectedCharacter`
- **Builder+Commands.swift**: `ml` → `mathList`, `str` → `result`, `frac` → `fraction`, `rad` → `radical`, `op` → `largeOperator`, `inner` → `innerAtom`, `over`/`under` → `overlineAtom`/`underlineAtom`, `phi`/`psi` → `firstArgument`/`secondArgument`, `delim` → `delimiter`, `mutable` → `colorValue`, `ch` → `character`, `env` → `environment`
- **Builder+Environments.swift**: same patterns as Builder+Commands, plus `oldEnv` → `previousEnvironment`, `alignChar` → `alignmentCharacter`
