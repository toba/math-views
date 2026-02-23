# LaTeX Math Command Reference

Comprehensive reference for LaTeX math commands as implemented in the math-views Swift package. Each entry lists the LaTeX command, Unicode code point, atom type used by the typesetter, and a brief description.

---

## Greek Letters

### Lowercase Greek (Type: `.variable`)

Auto-italicized by the renderer.

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\alpha` | U+03B1 | `.variable` | Greek small letter alpha |
| `\beta` | U+03B2 | `.variable` | Greek small letter beta |
| `\gamma` | U+03B3 | `.variable` | Greek small letter gamma |
| `\delta` | U+03B4 | `.variable` | Greek small letter delta |
| `\varepsilon` | U+03B5 | `.variable` | Greek small letter epsilon (variant) |
| `\zeta` | U+03B6 | `.variable` | Greek small letter zeta |
| `\eta` | U+03B7 | `.variable` | Greek small letter eta |
| `\theta` | U+03B8 | `.variable` | Greek small letter theta |
| `\iota` | U+03B9 | `.variable` | Greek small letter iota |
| `\kappa` | U+03BA | `.variable` | Greek small letter kappa |
| `\lambda` | U+03BB | `.variable` | Greek small letter lambda |
| `\mu` | U+03BC | `.variable` | Greek small letter mu |
| `\nu` | U+03BD | `.variable` | Greek small letter nu |
| `\xi` | U+03BE | `.variable` | Greek small letter xi |
| `\omicron` | U+03BF | `.variable` | Greek small letter omicron |
| `\pi` | U+03C0 | `.variable` | Greek small letter pi |
| `\rho` | U+03C1 | `.variable` | Greek small letter rho |
| `\varsigma` | U+03C2 | `.variable` | Greek small letter final sigma |
| `\sigma` | U+03C3 | `.variable` | Greek small letter sigma |
| `\tau` | U+03C4 | `.variable` | Greek small letter tau |
| `\upsilon` | U+03C5 | `.variable` | Greek small letter upsilon |
| `\varphi` | U+03C6 | `.variable` | Greek small letter phi (variant) |
| `\chi` | U+03C7 | `.variable` | Greek small letter chi |
| `\psi` | U+03C8 | `.variable` | Greek small letter psi |
| `\omega` | U+03C9 | `.variable` | Greek small letter omega |

### Lowercase Greek Variants (Type: `.ordinary`)

These use mathematical italic forms from the Unicode math block and are typed as `.ordinary` (not auto-italicized).

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\epsilon` | U+1D716 | `.ordinary` | Mathematical italic epsilon |
| `\vartheta` | U+1D717 | `.ordinary` | Mathematical italic theta variant |
| `\phi` | U+1D719 | `.ordinary` | Mathematical italic phi |
| `\varrho` | U+1D71A | `.ordinary` | Mathematical italic rho variant |
| `\varpi` | U+1D71B | `.ordinary` | Mathematical italic pi variant |
| `\varkappa` | U+03F0 | `.ordinary` | Greek kappa symbol |

### Uppercase Greek (Type: `.variable`)

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\Gamma` | U+0393 | `.variable` | Greek capital letter gamma |
| `\Delta` | U+0394 | `.variable` | Greek capital letter delta |
| `\Theta` | U+0398 | `.variable` | Greek capital letter theta |
| `\Lambda` | U+039B | `.variable` | Greek capital letter lambda |
| `\Xi` | U+039E | `.variable` | Greek capital letter xi |
| `\Pi` | U+03A0 | `.variable` | Greek capital letter pi |
| `\Sigma` | U+03A3 | `.variable` | Greek capital letter sigma |
| `\Upsilon` | U+03A5 | `.variable` | Greek capital letter upsilon |
| `\Phi` | U+03A6 | `.variable` | Greek capital letter phi |
| `\Psi` | U+03A8 | `.variable` | Greek capital letter psi |
| `\Omega` | U+03A9 | `.variable` | Greek capital letter omega |

---

## Binary Operators

All typed as `.binaryOperator` (Bin). TeX inserts medium spacing around binary operators.

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\times` | U+00D7 | `.binaryOperator` | Multiplication sign |
| `\div` | U+00F7 | `.binaryOperator` | Division sign |
| `\pm` | U+00B1 | `.binaryOperator` | Plus-minus sign |
| `\mp` | U+2213 | `.binaryOperator` | Minus-plus sign |
| `\dagger` | U+2020 | `.binaryOperator` | Dagger |
| `\ddagger` | U+2021 | `.binaryOperator` | Double dagger |
| `\setminus` | U+2216 | `.binaryOperator` | Set minus |
| `\ast` | U+2217 | `.binaryOperator` | Asterisk operator |
| `\circ` | U+2218 | `.binaryOperator` | Ring operator |
| `\bullet` | U+2219 | `.binaryOperator` | Bullet operator |
| `\wedge` | U+2227 | `.binaryOperator` | Logical and (aliases: `\land`) |
| `\vee` | U+2228 | `.binaryOperator` | Logical or (aliases: `\lor`) |
| `\cap` | U+2229 | `.binaryOperator` | Intersection |
| `\cup` | U+222A | `.binaryOperator` | Union |
| `\wr` | U+2240 | `.binaryOperator` | Wreath product |
| `\uplus` | U+228E | `.binaryOperator` | Multiset union |
| `\sqcap` | U+2293 | `.binaryOperator` | Square intersection |
| `\sqcup` | U+2294 | `.binaryOperator` | Square union |
| `\oplus` | U+2295 | `.binaryOperator` | Circled plus |
| `\ominus` | U+2296 | `.binaryOperator` | Circled minus |
| `\otimes` | U+2297 | `.binaryOperator` | Circled times |
| `\oslash` | U+2298 | `.binaryOperator` | Circled division slash |
| `\odot` | U+2299 | `.binaryOperator` | Circled dot operator |
| `\star` | U+22C6 | `.binaryOperator` | Star operator |
| `\cdot` | U+22C5 | `.binaryOperator` | Dot operator |
| `\diamond` | U+22C4 | `.binaryOperator` | Diamond operator |
| `\amalg` | U+2A3F | `.binaryOperator` | Amalgamation or coproduct |
| `\ltimes` | U+22C9 | `.binaryOperator` | Left normal factor semidirect product |
| `\rtimes` | U+22CA | `.binaryOperator` | Right normal factor semidirect product |
| `\circledast` | U+229B | `.binaryOperator` | Circled asterisk |
| `\circledcirc` | U+229A | `.binaryOperator` | Circled ring |
| `\circleddash` | U+229D | `.binaryOperator` | Circled dash |
| `\boxdot` | U+22A1 | `.binaryOperator` | Squared dot operator |
| `\boxminus` | U+229F | `.binaryOperator` | Squared minus |
| `\boxplus` | U+229E | `.binaryOperator` | Squared plus |
| `\boxtimes` | U+22A0 | `.binaryOperator` | Squared times |
| `\divideontimes` | U+22C7 | `.binaryOperator` | Division times |
| `\dotplus` | U+2214 | `.binaryOperator` | Dot plus |
| `\lhd` | U+22B2 | `.binaryOperator` | Normal subgroup of |
| `\rhd` | U+22B3 | `.binaryOperator` | Contains as normal subgroup |
| `\unlhd` | U+22B4 | `.binaryOperator` | Normal subgroup of or equal to |
| `\unrhd` | U+22B5 | `.binaryOperator` | Contains as normal subgroup or equal to |
| `\intercal` | U+22BA | `.binaryOperator` | Intercalate |
| `\barwedge` | U+22BC | `.binaryOperator` | Nand |
| `\veebar` | U+22BB | `.binaryOperator` | Exclusive or |
| `\curlywedge` | U+22CF | `.binaryOperator` | Curly logical and |
| `\curlyvee` | U+22CE | `.binaryOperator` | Curly logical or |
| `\doublebarwedge` | U+2A5E | `.binaryOperator` | Double bar wedge (logical and) |
| `\centerdot` | U+22C5 | `.binaryOperator` | Center dot (same glyph as `\cdot`) |

---

## Relations

All typed as `.relation` (Rel). TeX inserts thick spacing around relations.

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\leq` | U+2264 | `.relation` | Less than or equal to (alias: `\le`) |
| `\geq` | U+2265 | `.relation` | Greater than or equal to (alias: `\ge`) |
| `\leqslant` | U+2A7D | `.relation` | Less than or slanted equal to |
| `\geqslant` | U+2A7E | `.relation` | Greater than or slanted equal to |
| `\neq` | U+2260 | `.relation` | Not equal to (alias: `\ne`) |
| `\in` | U+2208 | `.relation` | Element of |
| `\notin` | U+2209 | `.relation` | Not an element of |
| `\ni` | U+220B | `.relation` | Contains as member |
| `\propto` | U+221D | `.relation` | Proportional to |
| `\mid` | U+2223 | `.relation` | Divides |
| `\parallel` | U+2225 | `.relation` | Parallel to |
| `\sim` | U+223C | `.relation` | Tilde operator (similar to) |
| `\simeq` | U+2243 | `.relation` | Asymptotically equal to |
| `\cong` | U+2245 | `.relation` | Approximately equal to (congruent) |
| `\approx` | U+2248 | `.relation` | Almost equal to |
| `\asymp` | U+224D | `.relation` | Equivalent to |
| `\doteq` | U+2250 | `.relation` | Approaches the limit |
| `\equiv` | U+2261 | `.relation` | Identical to (equivalent) |
| `\gg` | U+226B | `.relation` | Much greater than |
| `\ll` | U+226A | `.relation` | Much less than |
| `\prec` | U+227A | `.relation` | Precedes |
| `\succ` | U+227B | `.relation` | Succeeds |
| `\preceq` | U+2AAF | `.relation` | Precedes or equal to |
| `\succeq` | U+2AB0 | `.relation` | Succeeds or equal to |
| `\subset` | U+2282 | `.relation` | Subset of |
| `\supset` | U+2283 | `.relation` | Superset of |
| `\subseteq` | U+2286 | `.relation` | Subset of or equal to |
| `\supseteq` | U+2287 | `.relation` | Superset of or equal to |
| `\sqsubset` | U+228F | `.relation` | Square image of |
| `\sqsupset` | U+2290 | `.relation` | Square original of |
| `\sqsubseteq` | U+2291 | `.relation` | Square image of or equal to |
| `\sqsupseteq` | U+2292 | `.relation` | Square original of or equal to |
| `\models` | U+22A7 | `.relation` | Models |
| `\vdash` | U+22A2 | `.relation` | Right tack (proves) |
| `\dashv` | U+22A3 | `.relation` | Left tack |
| `\bowtie` | U+22C8 | `.relation` | Bowtie (natural join) |
| `\perp` | U+27C2 | `.relation` | Perpendicular |
| `\implies` | U+27F9 | `.relation` | Long double right arrow (implies) |

---

## Negated Relations

All typed as `.relation` (Rel).

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\nless` | U+226E | `.relation` | Not less than |
| `\ngtr` | U+226F | `.relation` | Not greater than |
| `\nleq` | U+2270 | `.relation` | Neither less than nor equal to |
| `\ngeq` | U+2271 | `.relation` | Neither greater than nor equal to |
| `\nleqslant` | U+2A87 | `.relation` | Not less than or slant equal to |
| `\ngeqslant` | U+2A88 | `.relation` | Not greater than or slant equal to |
| `\lneq` | U+2A87 | `.relation` | Less than and single-line not equal to |
| `\gneq` | U+2A88 | `.relation` | Greater than and single-line not equal to |
| `\lneqq` | U+2268 | `.relation` | Less than and not equal to |
| `\gneqq` | U+2269 | `.relation` | Greater than and not equal to |
| `\lnsim` | U+22E6 | `.relation` | Less than but not equivalent to |
| `\gnsim` | U+22E7 | `.relation` | Greater than but not equivalent to |
| `\lnapprox` | U+2A89 | `.relation` | Less than and not approximate |
| `\gnapprox` | U+2A8A | `.relation` | Greater than and not approximate |
| `\nprec` | U+2280 | `.relation` | Does not precede |
| `\nsucc` | U+2281 | `.relation` | Does not succeed |
| `\npreceq` | U+22E0 | `.relation` | Does not precede or equal |
| `\nsucceq` | U+22E1 | `.relation` | Does not succeed or equal |
| `\precneqq` | U+2AB5 | `.relation` | Precedes and not equal to |
| `\succneqq` | U+2AB6 | `.relation` | Succeeds and not equal to |
| `\precnsim` | U+22E8 | `.relation` | Precedes but not equivalent to |
| `\succnsim` | U+22E9 | `.relation` | Succeeds but not equivalent to |
| `\precnapprox` | U+2AB9 | `.relation` | Precedes and not approximate |
| `\succnapprox` | U+2ABA | `.relation` | Succeeds and not approximate |
| `\nsim` | U+2241 | `.relation` | Not tilde (not similar to) |
| `\ncong` | U+2247 | `.relation` | Not congruent to |
| `\nmid` | U+2224 | `.relation` | Does not divide |
| `\nshortmid` | U+2224 | `.relation` | Negated short mid |
| `\nparallel` | U+2226 | `.relation` | Not parallel to |
| `\nshortparallel` | U+2226 | `.relation` | Negated short parallel |
| `\nsubseteq` | U+2288 | `.relation` | Not a subset of or equal to |
| `\nsupseteq` | U+2289 | `.relation` | Not a superset of or equal to |
| `\subsetneq` | U+228A | `.relation` | Subset of with not equal to |
| `\supsetneq` | U+228B | `.relation` | Superset of with not equal to |
| `\subsetneqq` | U+2ACB | `.relation` | Subset of and not equal to |
| `\supsetneqq` | U+2ACC | `.relation` | Superset of and not equal to |
| `\varsubsetneq` | U+228A | `.relation` | Subset of with not equal to (variant) |
| `\varsupsetneq` | U+228B | `.relation` | Superset of with not equal to (variant) |
| `\varsubsetneqq` | U+2ACB | `.relation` | Subset of and not equal to (variant) |
| `\varsupsetneqq` | U+2ACC | `.relation` | Superset of and not equal to (variant) |
| `\notni` | U+220C | `.relation` | Does not contain as member |
| `\nni` | U+220C | `.relation` | Does not contain as member |
| `\ntriangleleft` | U+22EA | `.relation` | Not normal subgroup of |
| `\ntriangleright` | U+22EB | `.relation` | Does not contain as normal subgroup |
| `\ntrianglelefteq` | U+22EC | `.relation` | Not normal subgroup of or equal to |
| `\ntrianglerighteq` | U+22ED | `.relation` | Does not contain as normal subgroup or equal |
| `\nvdash` | U+22AC | `.relation` | Does not prove |
| `\nvDash` | U+22AD | `.relation` | Not true |
| `\nVdash` | U+22AE | `.relation` | Does not force |
| `\nVDash` | U+22AF | `.relation` | Negated double vertical bar double right turnstile |
| `\nsqsubseteq` | U+22E2 | `.relation` | Not square image of or equal to |
| `\nsqsupseteq` | U+22E3 | `.relation` | Not square original of or equal to |

---

## Arrows

All typed as `.relation` (Rel).

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\leftarrow` | U+2190 | `.relation` | Leftwards arrow (alias: `\gets`) |
| `\uparrow` | U+2191 | `.relation` | Upwards arrow |
| `\rightarrow` | U+2192 | `.relation` | Rightwards arrow (alias: `\to`) |
| `\downarrow` | U+2193 | `.relation` | Downwards arrow |
| `\leftrightarrow` | U+2194 | `.relation` | Left right arrow |
| `\updownarrow` | U+2195 | `.relation` | Up down arrow |
| `\nwarrow` | U+2196 | `.relation` | North west arrow |
| `\nearrow` | U+2197 | `.relation` | North east arrow |
| `\searrow` | U+2198 | `.relation` | South east arrow |
| `\swarrow` | U+2199 | `.relation` | South west arrow |
| `\mapsto` | U+21A6 | `.relation` | Rightwards arrow from bar |
| `\hookleftarrow` | U+21A9 | `.relation` | Leftwards arrow with hook |
| `\hookrightarrow` | U+21AA | `.relation` | Rightwards arrow with hook |
| `\Leftarrow` | U+21D0 | `.relation` | Leftwards double arrow |
| `\Uparrow` | U+21D1 | `.relation` | Upwards double arrow |
| `\Rightarrow` | U+21D2 | `.relation` | Rightwards double arrow |
| `\Downarrow` | U+21D3 | `.relation` | Downwards double arrow |
| `\Leftrightarrow` | U+21D4 | `.relation` | Left right double arrow |
| `\Updownarrow` | U+21D5 | `.relation` | Up down double arrow |
| `\longleftarrow` | U+27F5 | `.relation` | Long leftwards arrow |
| `\longrightarrow` | U+27F6 | `.relation` | Long rightwards arrow |
| `\longleftrightarrow` | U+27F7 | `.relation` | Long left right arrow |
| `\Longleftarrow` | U+27F8 | `.relation` | Long leftwards double arrow |
| `\Longrightarrow` | U+27F9 | `.relation` | Long rightwards double arrow |
| `\Longleftrightarrow` | U+27FA | `.relation` | Long left right double arrow (alias: `\iff`) |
| `\longmapsto` | U+27FC | `.relation` | Long rightwards arrow from bar |

---

## Delimiters

### Opening Delimiters (Type: `.open`)

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `(` | U+0028 | `.open` | Left parenthesis |
| `[` | U+005B | `.open` | Left square bracket |
| `\{` | U+007B | `.open` | Left curly brace (alias: `\lbrace`) |
| `\lceil` | U+2308 | `.open` | Left ceiling |
| `\lfloor` | U+230A | `.open` | Left floor |
| `\langle` | U+27E8 | `.open` | Left angle bracket |
| `\lgroup` | U+27EE | `.open` | Left group |

### Closing Delimiters (Type: `.close`)

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `)` | U+0029 | `.close` | Right parenthesis |
| `]` | U+005D | `.close` | Right square bracket |
| `\}` | U+007D | `.close` | Right curly brace (alias: `\rbrace`) |
| `\rceil` | U+2309 | `.close` | Right ceiling |
| `\rfloor` | U+230B | `.close` | Right floor |
| `\rangle` | U+27E9 | `.close` | Right angle bracket |
| `\rgroup` | U+27EF | `.close` | Right group |

---

## Large Operators

All typed as `.largeOperator` (Op). These are rendered larger in display style and support limits above/below.

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\sum` | U+2211 | `.largeOperator` | N-ary summation |
| `\prod` | U+220F | `.largeOperator` | N-ary product |
| `\coprod` | U+2210 | `.largeOperator` | N-ary coproduct |
| `\int` | U+222B | `.largeOperator` | Integral |
| `\iint` | U+222C | `.largeOperator` | Double integral |
| `\iiint` | U+222D | `.largeOperator` | Triple integral |
| `\iiiint` | U+2A0C | `.largeOperator` | Quadruple integral |
| `\oint` | U+222E | `.largeOperator` | Contour integral |
| `\bigwedge` | U+22C0 | `.largeOperator` | N-ary logical and |
| `\bigvee` | U+22C1 | `.largeOperator` | N-ary logical or |
| `\bigcap` | U+22C2 | `.largeOperator` | N-ary intersection |
| `\bigcup` | U+22C3 | `.largeOperator` | N-ary union |
| `\bigodot` | U+2A00 | `.largeOperator` | N-ary circled dot operator |
| `\bigoplus` | U+2A01 | `.largeOperator` | N-ary circled plus operator |
| `\bigotimes` | U+2A02 | `.largeOperator` | N-ary circled times operator |
| `\biguplus` | U+2A04 | `.largeOperator` | N-ary union with plus |
| `\bigsqcup` | U+2A06 | `.largeOperator` | N-ary square union |

---

## Named Functions (No-Limit Operators)

Type: `.largeOperator` (no limits). Rendered in upright/roman font. Limits (subscripts/superscripts) appear as scripts, not above/below.

| Command | Description |
|---------|-------------|
| `\log` | Logarithm |
| `\lg` | Common logarithm |
| `\ln` | Natural logarithm |
| `\sin` | Sine |
| `\arcsin` | Inverse sine |
| `\sinh` | Hyperbolic sine |
| `\cos` | Cosine |
| `\arccos` | Inverse cosine |
| `\cosh` | Hyperbolic cosine |
| `\tan` | Tangent |
| `\arctan` | Inverse tangent |
| `\tanh` | Hyperbolic tangent |
| `\cot` | Cotangent |
| `\coth` | Hyperbolic cotangent |
| `\sec` | Secant |
| `\csc` | Cosecant |
| `\arccot` | Inverse cotangent |
| `\arcsec` | Inverse secant |
| `\arccsc` | Inverse cosecant |
| `\sech` | Hyperbolic secant |
| `\csch` | Hyperbolic cosecant |
| `\arcsinh` | Inverse hyperbolic sine |
| `\arccosh` | Inverse hyperbolic cosine |
| `\arctanh` | Inverse hyperbolic tangent |
| `\arccoth` | Inverse hyperbolic cotangent |
| `\arcsech` | Inverse hyperbolic secant |
| `\arccsch` | Inverse hyperbolic cosecant |
| `\arg` | Argument of a complex number |
| `\ker` | Kernel |
| `\dim` | Dimension |
| `\hom` | Homomorphism |
| `\exp` | Exponential |
| `\deg` | Degree |
| `\mod` | Modulo |

---

## Limit Operators

Type: `.largeOperator` (with limits). In display style, subscripts and superscripts render above/below the operator.

| Command | Display Text | Description |
|---------|-------------|-------------|
| `\lim` | lim | Limit |
| `\limsup` | lim sup | Limit superior |
| `\liminf` | lim inf | Limit inferior |
| `\max` | max | Maximum |
| `\min` | min | Minimum |
| `\sup` | sup | Supremum |
| `\inf` | inf | Infimum |
| `\det` | det | Determinant |
| `\Pr` | Pr | Probability |
| `\gcd` | gcd | Greatest common divisor |

---

## Accents

Applied above a base atom. The Unicode value is the combining character used.

| Command | Unicode | Description |
|---------|---------|-------------|
| `\grave` | U+0300 | Grave accent |
| `\acute` | U+0301 | Acute accent |
| `\hat` | U+0302 | Circumflex (hat) |
| `\widehat` | U+0302 | Wide circumflex (stretches over base) |
| `\tilde` | U+0303 | Tilde |
| `\widetilde` | U+0303 | Wide tilde (stretches over base) |
| `\bar` | U+0304 | Macron (bar) |
| `\breve` | U+0306 | Breve |
| `\dot` | U+0307 | Dot above |
| `\ddot` | U+0308 | Diaeresis (double dot above) |
| `\check` | U+030C | Caron (check) |
| `\vec` | U+20D7 | Vector arrow |
| `\overleftarrow` | U+20D6 | Left arrow above |
| `\overrightarrow` | U+20D7 | Right arrow above |
| `\overleftrightarrow` | U+20E1 | Left right arrow above |

---

## Spacing Commands

Type: `.space`. Values are in mu (math units; 1 em = 18 mu).

| Command | Width | Description |
|---------|-------|-------------|
| `\,` | 3 mu | Thin space |
| `\>` | 4 mu | Medium space |
| `\;` | 5 mu | Thick space |
| `\!` | -3 mu | Negative thin space |
| `\quad` | 18 mu | Quad space (1 em) |
| `\qquad` | 36 mu | Double quad space (2 em) |

---

## Font Commands

These change the font style of enclosed content. Syntax: `\mathXX{content}`.

| Command | Aliases | Description |
|---------|---------|-------------|
| `\mathnormal` | | Default math italic |
| `\mathrm` | `\textrm`, `\rm` | Roman (upright) |
| `\mathbf` | `\textbf`, `\bf` | Bold |
| `\mathcal` | `\cal` | Calligraphic |
| `\mathtt` | `\texttt` | Typewriter (monospace) |
| `\mathit` | `\textit`, `\mit` | Italic |
| `\mathsf` | `\textsf` | Sans-serif |
| `\mathfrak` | `\frak` | Fraktur |
| `\mathbb` | | Blackboard bold |
| `\mathbfit` | `\bm`, `\boldsymbol` | Bold italic |
| `\text` | | Text mode (upright, respects spaces) |

---

## Style Commands

These change the typesetting style, affecting sizing of operators, fractions, and scripts.

| Command | Description |
|---------|-------------|
| `\displaystyle` | Display style (large operators, full-size fractions) |
| `\textstyle` | Text style (inline, smaller operators and fractions) |
| `\scriptstyle` | Script size (superscript/subscript level) |
| `\scriptscriptstyle` | Scriptscript size (nested superscript/subscript level) |

---

## Structural Commands

These are parsed directly by `MTMathListBuilder` and produce specialized atom types.

| Command | Syntax | Description |
|---------|--------|-------------|
| `\frac` | `\frac{num}{den}` | Fraction |
| `\dfrac` | `\dfrac{num}{den}` | Display-style fraction |
| `\tfrac` | `\tfrac{num}{den}` | Text-style fraction |
| `\cfrac` | `\cfrac{num}{den}` | Continued fraction (display-style numerator) |
| `\binom` | `\binom{n}{k}` | Binomial coefficient |
| `\sqrt` | `\sqrt{x}` or `\sqrt[n]{x}` | Square root or nth root |
| `\bra` | `\bra{x}` | Dirac bra notation |
| `\ket` | `\ket{x}` | Dirac ket notation |
| `\braket` | `\braket{x}{y}` | Dirac bracket notation |
| `\operatorname` | `\operatorname{name}` | Custom operator name (upright) |
| `\operatorname*` | `\operatorname*{name}` | Custom operator name with limits |
| `^` | `x^{exp}` | Superscript |
| `_` | `x_{sub}` | Subscript |
| `\overline` | `\overline{x}` | Overline |
| `\underline` | `\underline{x}` | Underline |
| `\left`...`\right` | `\left( ... \right)` | Auto-sized delimiters |

---

## Environments

Entered via `\begin{env}...\end{env}`. Starred variants (e.g., `matrix*`) may also be available.

| Environment | Description |
|-------------|-------------|
| `matrix` | Matrix without delimiters |
| `pmatrix` | Matrix with parentheses |
| `bmatrix` | Matrix with square brackets |
| `Bmatrix` | Matrix with curly braces |
| `vmatrix` | Matrix with vertical bars (determinant) |
| `Vmatrix` | Matrix with double vertical bars (norm) |
| `smallmatrix` | Small inline matrix |
| `aligned` | Aligned equations (with `&` alignment points) |
| `eqalign` | Equation alignment (TeX-style) |
| `split` | Split equation across lines |
| `gather` | Gathered equations (centered) |
| `displaylines` | Display lines (centered, no alignment) |
| `eqnarray` | Equation array |
| `cases` | Piecewise case definitions |

---

## Miscellaneous Symbols

All typed as `.ordinary` unless otherwise noted.

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\degree` | U+00B0 | `.ordinary` | Degree sign |
| `\neg` | U+00AC | `.ordinary` | Not sign (alias: `\lnot`) |
| `\angstrom` | U+00C5 | `.ordinary` | Angstrom sign (alias: `\AA`) |
| `\|` | U+2016 | `.ordinary` | Double vertical line (alias: `\Vert`) |
| `\vert` | U+007C | `.ordinary` | Vertical line |
| `\ldots` | U+2026 | `.ordinary` | Horizontal ellipsis (low) |
| `\prime` | U+2032 | `.ordinary` | Prime |
| `\hbar` | U+210F | `.ordinary` | Planck constant over 2 pi |
| `\Im` | U+2111 | `.ordinary` | Imaginary part |
| `\ell` | U+2113 | `.ordinary` | Script small l |
| `\wp` | U+2118 | `.ordinary` | Weierstrass p |
| `\Re` | U+211C | `.ordinary` | Real part |
| `\mho` | U+2127 | `.ordinary` | Inverted ohm sign |
| `\aleph` | U+2135 | `.ordinary` | Aleph (first transfinite cardinal) |
| `\beth` | U+2136 | `.ordinary` | Beth (second Hebrew letter) |
| `\gimel` | U+2137 | `.ordinary` | Gimel (third Hebrew letter) |
| `\daleth` | U+2138 | `.ordinary` | Daleth (fourth Hebrew letter) |
| `\forall` | U+2200 | `.ordinary` | For all (universal quantifier) |
| `\exists` | U+2203 | `.ordinary` | There exists (existential quantifier) |
| `\nexists` | U+2204 | `.ordinary` | There does not exist |
| `\emptyset` | U+2205 | `.ordinary` | Empty set (alias: `\varnothing`) |
| `\nabla` | U+2207 | `.ordinary` | Nabla (del, gradient) |
| `\infty` | U+221E | `.ordinary` | Infinity |
| `\angle` | U+2220 | `.ordinary` | Angle |
| `\measuredangle` | U+2221 | `.ordinary` | Measured angle |
| `\top` | U+22A4 | `.ordinary` | Down tack (top, verum) |
| `\bot` | U+22A5 | `.ordinary` | Up tack (bottom, falsum) |
| `\vdots` | U+22EE | `.ordinary` | Vertical ellipsis |
| `\cdots` | U+22EF | `.ordinary` | Midline horizontal ellipsis |
| `\ddots` | U+22F1 | `.ordinary` | Down right diagonal ellipsis |
| `\triangle` | U+25B3 | `.ordinary` | White up-pointing triangle |
| `\Box` | U+25A1 | `.ordinary` | White square |
| `\imath` | U+1D6A4 | `.ordinary` | Dotless i |
| `\jmath` | U+1D6A5 | `.ordinary` | Dotless j |
| `\partial` | U+1D715 | `.ordinary` | Partial differential |
| `\upquote` | U+0027 | `.ordinary` | Apostrophe |
| `\lbar` | U+019B | `.ordinary` | Latin small letter lambda with stroke |

---

## Punctuation

Type: `.punctuation` (Punct). TeX inserts thin spacing after punctuation.

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\colon` | U+003A | `.punctuation` | Colon |
| `\cdotp` | U+00B7 | `.punctuation` | Middle dot (centered period) |
| `,` | U+002C | `.punctuation` | Comma |
| `;` | U+003B | `.punctuation` | Semicolon |

---

## LaTeX Special Characters

Characters with special meaning in LaTeX that require a backslash prefix.

| Command | Unicode | Type | Description |
|---------|---------|------|-------------|
| `\{` | U+007B | `.open` | Left curly brace |
| `\}` | U+007D | `.close` | Right curly brace |
| `\$` | U+0024 | `.ordinary` | Dollar sign |
| `\&` | U+0026 | `.ordinary` | Ampersand |
| `\#` | U+0023 | `.ordinary` | Hash/number sign |
| `\%` | U+0025 | `.ordinary` | Percent sign |
| `\_` | U+005F | `.ordinary` | Underscore |
| `\ ` | U+0020 | `.ordinary` | Space |
| `\\` | | | Line break / newline |

---

## Command Aliases

Quick reference for alternative command names that map to the same symbol.

| Alias | Maps To |
|-------|---------|
| `\lnot` | `\neg` |
| `\land` | `\wedge` |
| `\lor` | `\vee` |
| `\ne` | `\neq` |
| `\le` | `\leq` |
| `\ge` | `\geq` |
| `\lbrace` | `\{` |
| `\rbrace` | `\}` |
| `\Vert` | `\|` |
| `\gets` | `\leftarrow` |
| `\to` | `\rightarrow` |
| `\iff` | `\Longleftrightarrow` |
| `\AA` | `\angstrom` |
| `\varnothing` | `\emptyset` |
