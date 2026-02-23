# TeX Inter-Element Spacing

TeX inserts horizontal space between adjacent math atoms based on their types. The amount of space is determined by a matrix indexed by [left atom type][right atom type]. Some spaces are suppressed in script and scriptscript styles to keep sub/superscripts compact.

## Spacing Matrix

Abbreviations: `--` none, `3` thin (3mu), `3*` nsThin, `4*` nsMedium, `5*` nsThick, `!` invalid.

| Left \ Right | Ord | Op  | Bin | Rel | Open | Close | Punct | Frac |
|:-------------|:---:|:---:|:---:|:---:|:----:|:-----:|:-----:|:----:|
| **Ordinary** | --  |  3  | 4*  | 5*  |  --  |  --   |  --   |  3*  |
| **Operator** |  3  |  3  |  !  | 5*  |  --  |  --   |  --   |  3*  |
| **Binary**   | 4*  | 4*  |  !  |  !  |  4*  |   !   |   !   |  4*  |
| **Relation** | 5*  | 5*  |  !  | --  |  5*  |  --   |  --   |  5*  |
| **Open**     | --  | --  |  !  | --  |  --  |  --   |  --   |  --  |
| **Close**    | --  |  3  | 4*  | 5*  |  --  |  --   |  --   |  3*  |
| **Punct**    | 3*  | 3*  |  !  | 3*  |  3*  |  3*   |  3*   |  3*  |
| **Fraction** | 3*  |  3  | 4*  | 5*  |  3*  |  --   |  3*   |  3*  |
| **Radical**  | 4*  | 3*  | 4*  | 5*  |  --  |  --   |  --   |  3*  |

## Space Types

| Type     | Value | Size  | In script? |
|:---------|:-----:|:-----:|:-----------|
| none     |   0   | 0     | yes        |
| thin     |   1   | 3mu   | yes        |
| nsThin   |   2   | 3mu   | no         |
| nsMedium |   3   | 4mu   | no         |
| nsThick  |   4   | 5mu   | no         |
| invalid  |  -1   | n/a   | n/a        |

1mu = 1/18 em.

## Atom Type Index Mapping

| Index | Primary Type   | Also maps here                                                                                   |
|:-----:|:---------------|:-------------------------------------------------------------------------------------------------|
|   0   | ordinary       | color, textcolor, colorBox, placeholder, number, variable, unaryOperator, accent, underline, overline, boundary, space, style, table |
|   1   | largeOperator  |                                                                                                  |
|   2   | binaryOperator |                                                                                                  |
|   3   | relation       |                                                                                                  |
|   4   | open           |                                                                                                  |
|   5   | close          |                                                                                                  |
|   6   | punctuation    |                                                                                                  |
|   7   | fraction       | inner                                                                                            |
|   8   | radical        | row only                                                                                         |

## Special Cases

**Radical asymmetry.** Radical has a row (index 8) but no column. When a radical appears as the *right* atom, its column index is 0 (ordinary).

**"ns" suppression.** Spaces prefixed `ns` (nsThin, nsMedium, nsThick) are zeroed out in script and scriptscript styles. Only `thin` (3mu) survives in all styles.

**Invalid and unary reclassification.** An `invalid` entry means the left-right combination should not occur in well-formed math. When a binary operator follows another binary, a relation, an open delimiter, punctuation, or a large operator, the typesetter reclassifies it as a unary operator (ordinary, index 0) and re-looks up spacing.
