# Multiline / Line Breaking

The typesetter supports automatic line breaking via `preferredMaxLayoutWidth` on `MTMathUILabel`. When the rendered width would exceed this constraint, the typesetter breaks content across multiple lines.

## Architecture: Two-Tier Breaking

### 1. Interatom Breaking (Primary)

**Location**: `MTTypesetter.swift` — `checkAndPerformInteratomLineBreak()`

Checks **before** adding each atom. If `currentLineWidth + atomWidth + spacing > maxWidth`, flushes the current line and starts a new one.

Applies to: `.ordinary`, `.binaryOperator`, `.relation`, `.open`, `.close`, `.placeholder`, `.punctuation`

### 2. Universal Breaking (Fallback)

**Location**: `MTTypesetter.swift` — after adding atoms without scripts

Uses Core Text's `CTTypesetterSuggestLineBreak` for Unicode-aware word boundary breaking. Protects numbers from splitting (3.14, 1,000). Used for very long single text atoms.

## Complex Atom Handling

All complex atom types use a "create-then-check" pattern:
1. Create the display object first
2. Call `shouldBreakBeforeDisplay()` to check if it fits
3. If it doesn't fit, call `performLineBreak()` before adding it
4. Propagate `maxWidth` to nested content for proper inner wrapping

| Atom Type | Approach | Notes |
|-----------|----------|-------|
| Fractions | Create display, check width | Stays inline when fits |
| Radicals | Create display (incl. degree), check width | Handles simple and nth roots |
| Large operators | Create display, check width AND height | Height threshold: `fontSize × 2.5` |
| Delimiters (`\left`/`\right`) | Create display, propagate maxWidth | Inner content wraps independently |
| Color atoms | Create display, propagate maxWidth | All 3 types: `.color`, `.textcolor`, `.colorBox` |
| Matrices/tables | Create display, check width | Small matrices stay inline |
| Scripted atoms | Estimate width with scripts, check | Uses `estimateAtomWidthWithScripts()` |

## Break Quality Scoring

**Location**: `calculateBreakPenalty()` in `MTTypesetter.swift`

When width is 100–120% of maxWidth, a 3-atom look-ahead selects the lowest-penalty break point:

| Penalty | Break After | Examples |
|---------|------------|----------|
| 0 (best) | Binary operators, relations, punctuation | `+`, `=`, `,` |
| 10 | Ordinary atoms | variables, numbers |
| 100 | Open brackets, before close brackets | `(`, `)` |
| 150 | Unary/large operators | `\sum`, `\int` |

## Dynamic Line Height

**Location**: `calculateCurrentLineHeight()` in `MTTypesetter.swift`

Each line's vertical offset is computed from actual content height (max ascent + max descent + minimum spacing) rather than a fixed multiplier. Lines with tall content (fractions, large operators) get more spacing; regular lines stay compact.

- Minimum spacing: `fontSize × 0.2`
- Minimum total line height: `fontSize × 1.2`

## Early Exit Optimization

When remaining atoms are likely to fit (current usage < 60% with ≤5 atoms remaining, or estimated remaining width fits), the `remainingContentFits` flag skips all subsequent breaking checks.

## Key Helper Functions

| Function | Purpose |
|----------|---------|
| `shouldBreakBeforeDisplay()` | Check if display would exceed maxWidth |
| `performLineBreak()` | Flush current line, advance Y position |
| `performInteratomLineBreak()` | Line break during interatom checking |
| `calculateBreakPenalty()` | Score break point quality (lower = better) |
| `calculateCurrentLineHeight()` | Dynamic line height from content |
| `estimateAtomWidthWithScripts()` | Width estimate including super/subscripts |
| `estimateRemainingAtomsWidth()` | Heuristic for remaining content width |
| `checkAndPerformInteratomLineBreak()` | Main interatom breaking decision logic |

## Known Limitations

1. **No global optimization** — greedy algorithm, no backtracking for better overall layout
2. **No widow/orphan control** — single atoms can end up alone on a line
3. **Long text atoms** — break within the atom using Core Text word boundaries, not between atoms
4. **Fixed alignment** — no left/center/right alignment options for multiline output

## Tests

97 typesetter tests in `MTTypesetterTests.swift` covering:
- Simple equations, fractions/radicals inline, large operators, delimiters, colored expressions, matrices
- Scripted atoms, break quality scoring, dynamic line height
- Edge cases (very narrow widths, very wide atoms, 4+ line breaks)
- Real-world examples (quadratic formula, continued fractions, polynomials)
