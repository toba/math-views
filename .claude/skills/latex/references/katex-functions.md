# KaTeX Function Support Checklist

Support status for KaTeX functions in math-views (SwiftMath). Checked items (`[x]`) are implemented; unchecked items (`[ ]`) are not.

Source: https://katex.org/docs/supported

## Accents

- [x] `\acute{a}` — acute accent
- [x] `\bar{y}` — bar accent
- [x] `\breve{a}` — breve accent
- [x] `\check{a}` — check accent
- [x] `\dot{a}` — dot accent
- [x] `\ddot{a}` — double dot accent
- [ ] `\dddot{a}` — triple dot accent (not implemented)
- [ ] `\ddddot{a}` — quadruple dot accent (not implemented)
- [x] `\grave{a}` — grave accent
- [x] `\hat{\theta}` — hat accent
- [ ] `\mathring{g}` — ring accent (not implemented)
- [x] `\tilde{a}` — tilde accent
- [x] `\vec{F}` — vector arrow accent
- [x] `\widehat{ac}` — wide hat accent
- [x] `\widetilde{ac}` — wide tilde accent
- [ ] `\widecheck{ac}` — wide check accent (not implemented)
- [ ] `\utilde{AB}` — undertilde (not implemented)
- [x] `\overline{AB}` — overline
- [x] `\underline{AB}` — underline
- [x] `\overleftarrow{AB}` — left arrow over
- [x] `\overrightarrow{AB}` — right arrow over
- [x] `\overleftrightarrow{AB}` — left-right arrow over
- [ ] `\overgroup{AB}` — overgroup arc (not implemented)
- [ ] `\undergroup{AB}` — undergroup arc (not implemented)
- [ ] `\Overrightarrow{AB}` — double right arrow over (not implemented)
- [ ] `\underleftarrow{AB}` — left arrow under (not implemented)
- [ ] `\underrightarrow{AB}` — right arrow under (not implemented)
- [ ] `\underleftrightarrow{AB}` — left-right arrow under (not implemented)
- [ ] `\overleftharpoon{ac}` — left harpoon over (not implemented)
- [ ] `\overrightharpoon{ac}` — right harpoon over (not implemented)
- [ ] `\overbrace{AB}` — overbrace (not implemented)
- [ ] `\underbrace{AB}` — underbrace (not implemented)
- [ ] `\overlinesegment{AB}` — line segment over (not implemented)
- [ ] `\underlinesegment{AB}` — line segment under (not implemented)
- [ ] `\underbar{X}` — underbar (not implemented)
- [x] `a'` — prime (via `'` character)
- [x] `a''` — double prime
- [x] `a^{\prime}` — explicit prime superscript

### Text-mode Accents

- [ ] `\'` — text acute (not implemented)
- [ ] `` \` `` — text grave (not implemented)
- [ ] `\~` — text tilde (not implemented)
- [ ] `\.` — text dot (not implemented)
- [ ] `\^` — text circumflex (not implemented)
- [ ] `\"` — text umlaut (not implemented)
- [ ] `\=` — text macron (not implemented)
- [ ] `\u` — text breve (not implemented)
- [ ] `\v` — text caron (not implemented)
- [ ] `\H` — text double acute (not implemented)
- [ ] `\r` — text ring (not implemented)

## Delimiters

- [x] `(` `)` — parentheses
- [x] `\lparen` `\rparen` — parentheses (aliases)
- [x] `[` `]` — square brackets
- [x] `\lbrack` `\rbrack` — square brackets (aliases)
- [x] `\{` `\}` — curly braces
- [x] `\lbrace` `\rbrace` — curly braces (aliases)
- [x] `\langle` `\rangle` — angle brackets
- [x] `\lceil` `\rceil` — ceiling
- [x] `\lfloor` `\rfloor` — floor
- [x] `\lgroup` `\rgroup` — group delimiters
- [x] `|` `\vert` — single vertical bar
- [x] `\|` `\Vert` — double vertical bar
- [x] `\uparrow` — up arrow delimiter
- [x] `\downarrow` — down arrow delimiter
- [x] `\updownarrow` — up-down arrow delimiter
- [x] `\Uparrow` — double up arrow delimiter
- [x] `\Downarrow` — double down arrow delimiter
- [x] `\Updownarrow` — double up-down arrow delimiter
- [x] `\backslash` — backslash delimiter
- [x] `\ulcorner` `\urcorner` — upper corner brackets
- [x] `\llcorner` `\lrcorner` — lower corner brackets
- [x] `\llbracket` `\rrbracket` — double square brackets
- [x] `/` — forward slash delimiter
- [ ] `\lvert` `\rvert` — left/right vertical bar (not implemented)
- [ ] `\lVert` `\rVert` — left/right double vertical bar (not implemented)
- [x] `\left.` `\right.` — invisible delimiter
- [ ] `\lang` `\rang` — angle bracket aliases (not implemented)
- [x] `\lt` `\gt` — less-than/greater-than as delimiters (via `<` `>`)
- [ ] `\lmoustache` `\rmoustache` — moustache delimiters (not implemented)
- [ ] `\lBrace` `\rBrace` — double curly braces (not implemented)

### Delimiter Sizing

- [x] `\left` `\right` — auto-sizing delimiters
- [x] `\big` `\Big` `\bigg` `\Bigg` — fixed-size delimiters
- [x] `\bigl` `\Bigl` `\biggl` `\Biggl` — fixed-size opening delimiters
- [x] `\bigr` `\Bigr` `\biggr` `\Biggr` — fixed-size closing delimiters
- [x] `\bigm` `\Bigm` `\biggm` `\Biggm` — fixed-size middle delimiters
- [ ] `\middle` — auto-sizing middle delimiter (not implemented)

## Environments

- [x] `\begin{matrix}` — undelimited matrix
- [x] `\begin{pmatrix}` — parenthesized matrix
- [x] `\begin{bmatrix}` — bracketed matrix
- [x] `\begin{Bmatrix}` — brace-delimited matrix
- [x] `\begin{vmatrix}` — single-bar matrix (determinant)
- [x] `\begin{Vmatrix}` — double-bar matrix (norm)
- [x] `\begin{smallmatrix}` — inline small matrix
- [ ] `\begin{array}` — general array with column specs (not implemented)
- [ ] `\begin{subarray}` — sub-array for limits (not implemented)
- [x] `\begin{cases}` — piecewise cases
- [ ] `\begin{rcases}` — right-brace cases (not implemented)
- [x] `\begin{aligned}` — aligned equations
- [x] `\begin{split}` — split equation
- [x] `\begin{gather}` — gathered equations
- [x] `\begin{displaylines}` — display lines
- [x] `\begin{eqnarray}` — equation array (3 columns)
- [ ] `\begin{equation}` — numbered equation (not implemented)
- [ ] `\begin{align}` — numbered aligned equations (not implemented)
- [ ] `\begin{alignat}` — aligned at specific points (not implemented)
- [ ] `\begin{CD}` — commutative diagrams (not implemented)
- [ ] `\begin{dcases}` — display-style cases (not implemented)
- [ ] `\begin{drcases}` — display-style right cases (not implemented)
- [ ] `\begin{darray}` — display-style array (not implemented)
- [x] `\begin{matrix*}` — matrix with optional alignment
- [x] `\begin{pmatrix*}` — parenthesized matrix with alignment
- [x] `\begin{bmatrix*}` — bracketed matrix with alignment
- [x] `\begin{Bmatrix*}` — brace matrix with alignment
- [x] `\begin{vmatrix*}` — bar matrix with alignment
- [x] `\begin{Vmatrix*}` — double-bar matrix with alignment
- [ ] `\begin{equation*}` — unnumbered equation (not implemented)
- [ ] `\begin{gather*}` — unnumbered gather (not implemented)
- [ ] `\begin{align*}` — unnumbered align (not implemented)
- [ ] `\begin{alignat*}` — unnumbered alignat (not implemented)
- [ ] `\begin{gathered}` — gathered sub-environment (not implemented)
- [ ] `\begin{alignedat}` — alignedat sub-environment (not implemented)
- [ ] `\begin{multline}` — multi-line equation (not implemented)

## HTML

- [ ] `\href{url}{text}` — hyperlink (not implemented)
- [ ] `\url{url}` — URL display (not implemented)
- [ ] `\includegraphics{url}` — include image (not implemented)
- [ ] `\htmlId{id}{content}` — HTML ID (not implemented)
- [ ] `\htmlClass{class}{content}` — HTML class (not implemented)
- [ ] `\htmlStyle{style}{content}` — HTML style (not implemented)
- [ ] `\htmlData{key}{value}{content}` — HTML data attribute (not implemented)

## Letters and Unicode

### Greek Letters (Lowercase)

- [x] `\alpha` — alpha
- [x] `\beta` — beta
- [x] `\gamma` — gamma
- [x] `\delta` — delta
- [x] `\epsilon` — epsilon
- [x] `\varepsilon` — variant epsilon
- [x] `\zeta` — zeta
- [x] `\eta` — eta
- [x] `\theta` — theta
- [x] `\vartheta` — variant theta
- [x] `\iota` — iota
- [x] `\kappa` — kappa
- [x] `\varkappa` — variant kappa
- [x] `\lambda` — lambda
- [x] `\mu` — mu
- [x] `\nu` — nu
- [x] `\xi` — xi
- [x] `\omicron` — omicron
- [x] `\pi` — pi
- [x] `\varpi` — variant pi
- [x] `\rho` — rho
- [x] `\varrho` — variant rho
- [x] `\sigma` — sigma
- [x] `\varsigma` — variant sigma (final form)
- [x] `\tau` — tau
- [x] `\upsilon` — upsilon
- [x] `\phi` — phi
- [x] `\varphi` — variant phi
- [x] `\chi` — chi
- [x] `\psi` — psi
- [x] `\omega` — omega
- [ ] `\digamma` — digamma (not implemented, font unsupported)
- [ ] `\thetasym` — theta symbol alias (not implemented)

### Greek Letters (Uppercase)

- [x] `\Gamma` — capital gamma
- [x] `\Delta` — capital delta
- [x] `\Theta` — capital theta
- [x] `\Lambda` — capital lambda
- [x] `\Xi` — capital xi
- [x] `\Pi` — capital pi
- [x] `\Sigma` — capital sigma
- [x] `\Upsilon` — capital upsilon
- [x] `\Phi` — capital phi
- [x] `\Psi` — capital psi
- [x] `\Omega` — capital omega
- [ ] `\varGamma` — variant capital gamma (not implemented)
- [ ] `\varDelta` — variant capital delta (not implemented)
- [ ] `\varTheta` — variant capital theta (not implemented)
- [ ] `\varLambda` — variant capital lambda (not implemented)
- [ ] `\varXi` — variant capital xi (not implemented)
- [ ] `\varPi` — variant capital pi (not implemented)
- [ ] `\varSigma` — variant capital sigma (not implemented)
- [ ] `\varUpsilon` — variant capital upsilon (not implemented)
- [ ] `\varPhi` — variant capital phi (not implemented)
- [ ] `\varPsi` — variant capital psi (not implemented)
- [ ] `\varOmega` — variant capital omega (not implemented)
- [ ] `\Alpha` ... `\Omicron` — upright capitals that KaTeX defines (not implemented)

### Other Letters

- [x] `\imath` — dotless i
- [x] `\jmath` — dotless j
- [x] `\nabla` — nabla/del
- [x] `\partial` — partial derivative
- [x] `\ell` — script l
- [x] `\hbar` — h-bar
- [ ] `\hslash` — h-slash variant (not implemented)
- [x] `\aleph` — aleph
- [x] `\beth` — beth
- [x] `\gimel` — gimel
- [x] `\daleth` — daleth
- [x] `\wp` — Weierstrass p
- [x] `\Re` — real part
- [x] `\Im` — imaginary part
- [ ] `\Bbbk` — blackboard k (not implemented)
- [ ] `\Game` — game symbol (not implemented)
- [ ] `\FinV` — Fin V symbol (not implemented)
- [ ] `\cnums` `\Complex` — complex numbers (not implemented)
- [ ] `\natnums` `\NN` — natural numbers (not implemented)
- [ ] `\RR` — real numbers (not implemented)
- [ ] `\ZZ` — integers (not implemented)
- [ ] `\alefsym` `\alef` — aleph aliases (not implemented)
- [ ] `\real` `\reals` `\Reals` — real part aliases (not implemented)
- [ ] `\image` `\Imag` — imaginary part aliases (not implemented)
- [ ] `\weierp` — Weierstrass alias (not implemented)

## Layout

### Annotation

- [ ] `\cancel{5}` — cancel (strikethrough) (not implemented)
- [ ] `\bcancel{5}` — back cancel (not implemented)
- [ ] `\xcancel{ABC}` — cross cancel (not implemented)
- [x] `\not` — generic negation (combining slash)
- [ ] `\sout{abc}` — strikeout (not implemented)
- [ ] `\boxed{\pi=\frac c d}` — boxed expression (not implemented)
- [ ] `\tag{hi}` — equation tag (not implemented)
- [ ] `\tag*{hi}` — unparenthesized tag (not implemented)
- [ ] `\angl` — actuarial angle (not implemented)
- [ ] `\phase` — phase angle (not implemented)

### Line Breaks

- [ ] `\\` — line break in environments (partial: works in matrix/aligned environments)
- [ ] `\newline` — newline (not implemented)
- [ ] `\nobreak` — prevent break (not implemented)
- [ ] `\allowbreak` — allow break (not implemented)

### Vertical Layout

- [x] `x_n` — subscript
- [x] `e^x` — superscript
- [x] `_u^o` — sub/superscript
- [ ] `\stackrel{!}{=}` — stack relation (not implemented)
- [ ] `\overset{!}{=}` — overset (not implemented)
- [ ] `\underset{!}{=}` — underset (not implemented)
- [ ] `\atop` — atop (fraction without bar) (not implemented)
- [ ] `\raisebox{dim}{content}` — raise box (not implemented)
- [ ] `\substack` — sub-stack for limits (not implemented)
- [ ] `\vcenter` — vertical center (not implemented)

### Overlap and Spacing

- [x] `\,` `\thinspace` — thin space (3mu)
- [x] `\>` `\:` `\medspace` — medium space (4mu)
- [x] `\;` `\thickspace` — thick space (5mu)
- [x] `\!` `\negthinspace` — negative thin space (-3mu)
- [x] `\negmedspace` — negative medium space (-4mu)
- [x] `\negthickspace` — negative thick space (-5mu)
- [x] `\enspace` — en-space (9mu)
- [x] `\quad` — quad space (18mu)
- [x] `\qquad` — double quad space (36mu)
- [x] `\ ` — explicit space
- [ ] `~` — non-breaking space (not implemented)
- [ ] `\space` — space alias (not implemented)
- [ ] `\nobreakspace` — non-breaking space (not implemented)
- [ ] `\kern{distance}` — manual kerning (not implemented)
- [x] `\mkern{distance}` — math kerning (mu units)
- [ ] `\mskip{distance}` — math skip (not implemented)
- [ ] `\hskip{distance}` — horizontal skip (not implemented)
- [ ] `\hspace{distance}` — horizontal space (not implemented)
- [ ] `\hspace*{distance}` — forced horizontal space (not implemented)
- [ ] `\phantom{content}` — invisible content with spacing (not implemented)
- [ ] `\hphantom{content}` — horizontal phantom (not implemented)
- [ ] `\vphantom{content}` — vertical phantom (not implemented)
- [ ] `\mathstrut` — math strut (not implemented)
- [ ] `\mathllap` — math left overlap (not implemented)
- [ ] `\mathrlap` — math right overlap (not implemented)
- [ ] `\mathclap` — math center overlap (not implemented)
- [ ] `\llap` — left overlap (not implemented)
- [ ] `\rlap` — right overlap (not implemented)
- [ ] `\clap` — center overlap (not implemented)
- [ ] `\smash` — smash (not implemented)

## Logic and Set Theory

- [x] `\forall` — for all
- [ ] `\complement` — set complement (not implemented)
- [ ] `\therefore` — therefore (not implemented)
- [x] `\emptyset` — empty set
- [x] `\exists` — exists
- [x] `\subset` — subset
- [ ] `\because` — because (not implemented)
- [x] `\varnothing` — variant empty set
- [x] `\nexists` — not exists
- [x] `\supset` — superset
- [x] `\mapsto` — maps to
- [x] `\in` — element of
- [x] `\notin` — not element of
- [x] `\ni` — contains (reverse element)
- [x] `\notni` — does not contain
- [x] `\mid` — divides / such that
- [x] `\neg` `\lnot` — logical not
- [x] `\land` `\wedge` — logical and
- [x] `\lor` `\vee` — logical or
- [x] `\implies` — implies
- [x] `\impliedby` — implied by (via alias)
- [x] `\iff` — if and only if
- [x] `\to` `\rightarrow` — to (right arrow)
- [x] `\gets` `\leftarrow` — gets (left arrow)
- [x] `\leftrightarrow` — left-right arrow
- [ ] `\Set{...}` — set builder notation (not implemented)
- [ ] `\set{...}` — set notation (not implemented)
- [ ] `\exist` — exists alias (not implemented)
- [ ] `\isin` — element of alias (not implemented)
- [ ] `\empty` — empty set alias (not implemented)

## Macros

- [ ] `\def` — define macro (not implemented)
- [ ] `\gdef` — global define (not implemented)
- [ ] `\edef` — expanded define (not implemented)
- [ ] `\xdef` — global expanded define (not implemented)
- [ ] `\let` — let assignment (not implemented)
- [ ] `\futurelet` — future let (not implemented)
- [ ] `\newcommand` — new command (not implemented)
- [ ] `\renewcommand` — renew command (not implemented)
- [ ] `\providecommand` — provide command (not implemented)
- [ ] `\char` — character by code (not implemented)
- [ ] `\mathchoice` — math choice (not implemented)
- [ ] `\TextOrMath` — text or math selector (not implemented)
- [ ] `\@ifstar` — star test (not implemented)
- [ ] `\@ifnextchar` — next char test (not implemented)
- [ ] `\relax` — relax (not implemented)
- [ ] `\expandafter` — expand after (not implemented)
- [ ] `\noexpand` — no expand (not implemented)

## Operators

### Big Operators

- [x] `\sum` — summation
- [x] `\prod` — product
- [x] `\coprod` — coproduct
- [x] `\int` — integral
- [x] `\iint` — double integral
- [x] `\iiint` — triple integral
- [x] `\iiiint` — quadruple integral
- [x] `\oint` — contour integral
- [ ] `\oiint` — surface integral (not implemented)
- [ ] `\oiiint` — volume integral (not implemented)
- [ ] `\intop` — integral with limits (not implemented)
- [ ] `\smallint` — small integral (not implemented)
- [x] `\bigwedge` — big wedge
- [x] `\bigvee` — big vee
- [x] `\bigcap` — big intersection
- [x] `\bigcup` — big union
- [x] `\bigodot` — big odot
- [x] `\bigoplus` — big oplus
- [x] `\bigotimes` — big otimes
- [x] `\biguplus` — big uplus
- [x] `\bigsqcup` — big square cup

### Binary Operators

- [x] `+` — addition
- [x] `-` — subtraction
- [x] `*` — asterisk
- [x] `/` — division slash
- [x] `\cdot` — center dot
- [x] `\cdotp` — center dot (punctuation)
- [x] `\centerdot` — center dot
- [x] `\circ` — circle operator
- [x] `\times` — multiplication
- [x] `\div` — division
- [x] `\pm` — plus-minus
- [x] `\mp` — minus-plus
- [x] `\ast` — asterisk operator
- [x] `\star` — star operator
- [x] `\diamond` — diamond
- [x] `\bullet` — bullet
- [x] `\wedge` `\land` — logical and
- [x] `\vee` `\lor` — logical or
- [x] `\cap` — intersection
- [x] `\cup` — union
- [x] `\sqcap` — square cap
- [x] `\sqcup` — square cup
- [x] `\wr` — wreath product
- [x] `\setminus` — set minus
- [x] `\uplus` — multiset union
- [x] `\oplus` — circled plus
- [x] `\ominus` — circled minus
- [x] `\otimes` — circled times
- [x] `\oslash` — circled slash
- [x] `\odot` — circled dot
- [x] `\amalg` — amalgamation
- [x] `\dagger` — dagger
- [x] `\ddagger` — double dagger
- [x] `\ltimes` — left semidirect product
- [x] `\rtimes` — right semidirect product
- [x] `\circledast` — circled asterisk
- [x] `\circledcirc` — circled circle
- [x] `\circleddash` — circled dash
- [x] `\boxdot` — boxed dot
- [x] `\boxminus` — boxed minus
- [x] `\boxplus` — boxed plus
- [x] `\boxtimes` — boxed times
- [x] `\divideontimes` — divided on times
- [x] `\dotplus` — dot plus
- [x] `\lhd` — left normal subgroup
- [x] `\rhd` — right normal subgroup
- [x] `\unlhd` — left normal subgroup or equal
- [x] `\unrhd` — right normal subgroup or equal
- [x] `\intercal` — intercal
- [x] `\barwedge` — bar wedge
- [x] `\veebar` — vee bar
- [x] `\curlywedge` — curly wedge
- [x] `\curlyvee` — curly vee
- [x] `\doublebarwedge` — double bar wedge
- [ ] `\bigcirc` — big circle (not implemented)
- [ ] `\bmod` — binary mod (not implemented)
- [ ] `\mod` — mod with spacing (not implemented)
- [ ] `\Cap` `\doublecap` — double cap (not implemented)
- [ ] `\Cup` `\doublecup` — double cup (not implemented)
- [ ] `\gtrdot` — greater-than dot (not implemented)
- [ ] `\lessdot` — less-than dot (not implemented)
- [ ] `\leftthreetimes` — left three times (not implemented)
- [ ] `\rightthreetimes` — right three times (not implemented)
- [ ] `\smallsetminus` — small set minus (not implemented)
- [ ] `\And` `\&` — ampersand operator (not implemented)
- [ ] `\plusmn` — plus-minus alias (not implemented)

### Fractions and Binomials

- [x] `\frac{a}{b}` — fraction
- [x] `\dfrac{a}{b}` — display-style fraction
- [x] `\tfrac{a}{b}` — text-style fraction
- [x] `\cfrac{a}{1+...}` — continued fraction
- [x] `\binom{n}{k}` — binomial coefficient
- [ ] `\dbinom{n}{k}` — display-style binomial (not implemented)
- [ ] `\tbinom{n}{k}` — text-style binomial (not implemented)
- [ ] `{a \over b}` — old-style fraction (not implemented)
- [ ] `{a \above{2pt} b}` — fraction with custom bar (not implemented)
- [ ] `{n \choose k}` — old-style binomial (not implemented)
- [ ] `{n \brace k}` — Stirling subset (not implemented)
- [ ] `{n \brack k}` — Stirling cycle (not implemented)
- [ ] `\genfrac` — generalized fraction (not implemented)

### Math Operators (Named Functions)

- [x] `\arcsin` — arc sine
- [x] `\arccos` — arc cosine
- [x] `\arctan` — arc tangent
- [x] `\sin` — sine
- [x] `\cos` — cosine
- [x] `\tan` — tangent
- [x] `\cot` — cotangent
- [x] `\sec` — secant
- [x] `\csc` — cosecant
- [x] `\sinh` — hyperbolic sine
- [x] `\cosh` — hyperbolic cosine
- [x] `\tanh` — hyperbolic tangent
- [x] `\coth` — hyperbolic cotangent
- [x] `\sech` — hyperbolic secant
- [x] `\csch` — hyperbolic cosecant
- [x] `\log` — logarithm
- [x] `\lg` — common logarithm
- [x] `\ln` — natural logarithm
- [x] `\exp` — exponential
- [x] `\arg` — argument
- [x] `\ker` — kernel
- [x] `\dim` — dimension
- [x] `\hom` — homomorphism
- [x] `\deg` — degree
- [x] `\mod` — modulo
- [x] `\lim` — limit
- [x] `\limsup` — limit superior
- [x] `\liminf` — limit inferior
- [x] `\max` — maximum
- [x] `\min` — minimum
- [x] `\sup` — supremum
- [x] `\inf` — infimum
- [x] `\det` — determinant
- [x] `\Pr` — probability
- [x] `\gcd` — greatest common divisor
- [x] `\operatorname{f}` — custom operator name
- [x] `\operatorname*{f}` — custom operator with limits
- [ ] `\operatornamewithlimits{f}` — alias for operatorname* (not implemented)
- [ ] `\arctg` — arc tangent (alt) (not implemented)
- [ ] `\arcctg` — arc cotangent (alt) (not implemented)
- [ ] `\cotg` — cotangent (alt) (not implemented)
- [ ] `\ctg` — cotangent (alt) (not implemented)
- [ ] `\cth` — hyperbolic cotangent (alt) (not implemented)
- [ ] `\tg` — tangent (alt) (not implemented)
- [ ] `\th` — hyperbolic tangent (alt) (not implemented)
- [ ] `\sh` — hyperbolic sine (alt) (not implemented)
- [ ] `\ch` — hyperbolic cosine (alt) (not implemented)
- [ ] `\cosec` — cosecant alias (not implemented)
- [ ] `\argmax` — argmax (not implemented)
- [ ] `\argmin` — argmin (not implemented)
- [ ] `\plim` — probability limit (not implemented)
- [ ] `\projlim` — projective limit (not implemented)
- [ ] `\injlim` — injective limit (not implemented)
- [ ] `\varinjlim` — variant injective limit (not implemented)
- [ ] `\varliminf` — variant limit inferior (not implemented)
- [ ] `\varlimsup` — variant limit superior (not implemented)
- [ ] `\varprojlim` — variant projective limit (not implemented)

### Roots

- [x] `\sqrt{x}` — square root
- [x] `\sqrt[3]{x}` — nth root

## Relations

- [x] `=` — equals
- [x] `<` — less than
- [x] `>` — greater than
- [x] `:` — colon (as ratio)
- [x] `\approx` — approximately equal
- [x] `\approxeq` — approximately equal (variant)
- [x] `\asymp` — asymptotically equal
- [x] `\bowtie` — bowtie
- [x] `\cong` — congruent
- [x] `\dashv` — dash-vee (reverse turnstile)
- [x] `\doteq` — dot-equal
- [x] `\equiv` — equivalent
- [x] `\ge` `\geq` — greater or equal
- [x] `\geqslant` — greater or equal (slanted)
- [x] `\gg` — much greater than
- [x] `\in` `\isin` — element of
- [x] `\le` `\leq` — less or equal
- [x] `\leqslant` — less or equal (slanted)
- [x] `\ll` — much less than
- [x] `\mid` — divides
- [x] `\models` — models
- [x] `\ne` `\neq` — not equal
- [x] `\ni` — contains
- [x] `\notin` — not element of
- [x] `\parallel` — parallel
- [x] `\perp` — perpendicular
- [x] `\prec` — precedes
- [x] `\preceq` — precedes or equals
- [x] `\propto` — proportional to
- [x] `\sim` — similar
- [x] `\simeq` — similar or equal
- [x] `\sqsubset` — square subset
- [x] `\sqsubseteq` — square subset or equal
- [x] `\sqsupset` — square superset
- [x] `\sqsupseteq` — square superset or equal
- [x] `\subset` — subset
- [x] `\subseteq` — subset or equal
- [x] `\succ` — succeeds
- [x] `\succeq` — succeeds or equals
- [x] `\supset` — superset
- [x] `\supseteq` — superset or equal
- [x] `\vdash` — turnstile
- [ ] `\vDash` — double turnstile (not implemented)
- [ ] `\Vdash` — triple turnstile (not implemented)
- [ ] `\Vvdash` — Vv-dash (not implemented)
- [ ] `\between` — between (not implemented)
- [ ] `\bumpeq` — bumpy equal (not implemented)
- [ ] `\Bumpeq` — bumpy equal (variant) (not implemented)
- [ ] `\circeq` — circle equal (not implemented)
- [ ] `\curlyeqprec` — curly eq precedes (not implemented)
- [ ] `\curlyeqsucc` — curly eq succeeds (not implemented)
- [ ] `\doteqdot` `\Doteq` — dot-equal-dot (not implemented)
- [ ] `\eqcirc` — eq circle (not implemented)
- [ ] `\eqsim` — eq similar (not implemented)
- [ ] `\eqslantgtr` — eq slant greater (not implemented)
- [ ] `\eqslantless` — eq slant less (not implemented)
- [ ] `\fallingdotseq` — falling dot sequence (not implemented)
- [ ] `\geqq` — greater or equal (double) (not implemented)
- [ ] `\ggg` `\gggtr` — triple greater (not implemented)
- [ ] `\gt` — greater than (alias) (not implemented)
- [ ] `\gtrapprox` — greater approx (not implemented)
- [ ] `\gtreqless` — greater eq less (not implemented)
- [ ] `\gtreqqless` — greater eq-eq less (not implemented)
- [ ] `\gtrless` — greater less (not implemented)
- [ ] `\gtrsim` — greater similar (not implemented)
- [ ] `\imageof` — image of (not implemented)
- [ ] `\Join` — join (not implemented)
- [ ] `\leqq` — less or equal (double) (not implemented)
- [ ] `\lessapprox` — less approx (not implemented)
- [ ] `\lesseqgtr` — less eq greater (not implemented)
- [ ] `\lesseqqgtr` — less eq-eq greater (not implemented)
- [ ] `\lessgtr` — less greater (not implemented)
- [ ] `\lesssim` — less similar (not implemented)
- [ ] `\lll` `\llless` — triple less (not implemented)
- [ ] `\lt` — less than (alias) (not implemented)
- [ ] `\origof` — original of (not implemented)
- [ ] `\pitchfork` — pitchfork (not implemented)
- [ ] `\precapprox` — precedes approx (not implemented)
- [ ] `\preccurlyeq` — precedes curly eq (not implemented)
- [ ] `\precsim` — precedes similar (not implemented)
- [ ] `\risingdotseq` — rising dot sequence (not implemented)
- [ ] `\shortmid` — short mid (not implemented)
- [ ] `\shortparallel` — short parallel (not implemented)
- [ ] `\smallfrown` — small frown (not implemented)
- [ ] `\smallsmile` — small smile (not implemented)
- [ ] `\smile` — smile (not implemented)
- [ ] `\sqsubset` — square subset (already listed above)
- [ ] `\Subset` — double subset (not implemented)
- [ ] `\subseteqq` — subset eq (double) (not implemented)
- [ ] `\succsim` — succeeds similar (not implemented)
- [ ] `\succapprox` — succeeds approx (not implemented)
- [ ] `\succcurlyeq` — succeeds curly eq (not implemented)
- [ ] `\Supset` — double superset (not implemented)
- [ ] `\supseteqq` — superset eq (double) (not implemented)
- [ ] `\thickapprox` — thick approx (not implemented)
- [ ] `\thicksim` — thick similar (not implemented)
- [ ] `\trianglelefteq` — triangle left eq (not implemented)
- [ ] `\triangleq` — triangle eq (not implemented)
- [ ] `\trianglerighteq` — triangle right eq (not implemented)
- [ ] `\varpropto` — variant proportional (not implemented)
- [ ] `\vartriangle` — variant triangle (not implemented)
- [ ] `\vartriangleleft` — variant triangle left (not implemented)
- [ ] `\vartriangleright` — variant triangle right (not implemented)
- [ ] `\vcentcolon` `\ratio` — vertical center colon (not implemented)
- [ ] `\dblcolon` `\coloncolon` — double colon (not implemented)
- [ ] `\coloneq` `\colonminus` — colon-eq (not implemented)
- [ ] `\Coloneq` `\coloncolonminus` — double colon-eq (not implemented)
- [ ] `\coloneqq` `\colonequals` — colon-equals (not implemented)
- [ ] `\Coloneqq` `\coloncolonequals` — double colon-equals (not implemented)
- [ ] `\eqcolon` `\minuscolon` — eq-colon (not implemented)
- [ ] `\Eqcolon` `\minuscoloncolon` — eq-double-colon (not implemented)
- [ ] `\eqqcolon` `\equalscolon` — equals-colon (not implemented)
- [ ] `\Eqqcolon` `\equalscoloncolon` — equals-double-colon (not implemented)
- [ ] `\colonapprox` — colon-approx (not implemented)
- [ ] `\Colonapprox` `\coloncolonapprox` — double colon-approx (not implemented)
- [ ] `\colonsim` — colon-sim (not implemented)
- [ ] `\Colonsim` `\coloncolonsim` — double colon-sim (not implemented)
- [ ] `\simcolon` — sim-colon (not implemented)
- [ ] `\simcoloncolon` — sim-double-colon (not implemented)
- [ ] `\approxcolon` — approx-colon (not implemented)
- [ ] `\approxcoloncolon` — approx-double-colon (not implemented)

### Negated Relations

- [x] `\ncong` — not congruent
- [x] `\ne` `\neq` — not equal
- [x] `\ngeq` — not greater or equal
- [x] `\ngeqslant` — not greater or equal (slant)
- [x] `\ngtr` — not greater
- [x] `\nleq` — not less or equal
- [x] `\nleqslant` — not less or equal (slant)
- [x] `\nless` — not less
- [x] `\nmid` — not divides
- [x] `\nparallel` — not parallel
- [x] `\nprec` — not precedes
- [x] `\npreceq` — not precedes or equal
- [x] `\nsim` — not similar
- [x] `\nsubseteq` — not subset or equal
- [x] `\nsucc` — not succeeds
- [x] `\nsucceq` — not succeeds or equal
- [x] `\nsupseteq` — not superset or equal
- [x] `\ntriangleleft` — not triangle left
- [x] `\ntrianglelefteq` — not triangle left eq
- [x] `\ntriangleright` — not triangle right
- [x] `\ntrianglerighteq` — not triangle right eq
- [x] `\nvdash` — not turnstile
- [x] `\nvDash` — not double turnstile
- [x] `\nVdash` — not V-dash
- [x] `\nVDash` — not V-double-dash
- [x] `\nshortmid` — not short mid
- [x] `\nshortparallel` — not short parallel
- [x] `\nsqsubseteq` — not square subset eq
- [x] `\nsqsupseteq` — not square superset eq
- [x] `\gnapprox` — greater not approx
- [x] `\gneq` — greater not equal
- [x] `\gneqq` — greater not equal (double)
- [x] `\gnsim` — greater not similar
- [x] `\lnapprox` — less not approx
- [x] `\lneq` — less not equal
- [x] `\lneqq` — less not equal (double)
- [x] `\lnsim` — less not similar
- [x] `\notni` — not contains
- [x] `\nni` — not contains (alias)
- [x] `\precnapprox` — precedes not approx
- [x] `\precneqq` — precedes not equal (double)
- [x] `\precnsim` — precedes not similar
- [x] `\subsetneq` — subset not equal
- [x] `\subsetneqq` — subset not equal (double)
- [x] `\succnapprox` — succeeds not approx
- [x] `\succneqq` — succeeds not equal (double)
- [x] `\succnsim` — succeeds not similar
- [x] `\supsetneq` — superset not equal
- [x] `\supsetneqq` — superset not equal (double)
- [x] `\varsubsetneq` — variant subset not equal
- [x] `\varsubsetneqq` — variant subset not equal (double)
- [x] `\varsupsetneq` — variant superset not equal
- [x] `\varsupsetneqq` — variant superset not equal (double)
- [ ] `\notin` — not in (listed under relations)
- [ ] `\ngeqq` — not greater equal (double) (not implemented)
- [ ] `\nleqq` — not less equal (double) (not implemented)
- [ ] `\nsupseteqq` — not superset equal (double) (not implemented)
- [ ] `\nsubseteqq` — not subset equal (double) (not implemented)
- [ ] `\gvertneqq` — greater vert not equal (double) (not implemented)
- [ ] `\lvertneqq` — less vert not equal (double) (not implemented)
- [ ] `\precnapprox` — already listed above
- [ ] `\succnapprox` — already listed above

### Arrows

- [x] `\leftarrow` `\gets` — left arrow
- [x] `\rightarrow` `\to` — right arrow
- [x] `\uparrow` — up arrow
- [x] `\downarrow` — down arrow
- [x] `\leftrightarrow` — left-right arrow
- [x] `\updownarrow` — up-down arrow
- [x] `\Leftarrow` — double left arrow
- [x] `\Rightarrow` — double right arrow
- [x] `\Uparrow` — double up arrow
- [x] `\Downarrow` — double down arrow
- [x] `\Leftrightarrow` — double left-right arrow
- [x] `\Updownarrow` — double up-down arrow
- [x] `\longleftarrow` — long left arrow
- [x] `\longrightarrow` — long right arrow
- [x] `\longleftrightarrow` — long left-right arrow
- [x] `\Longleftarrow` — long double left arrow
- [x] `\Longrightarrow` — long double right arrow
- [x] `\Longleftrightarrow` — long double left-right arrow
- [x] `\longmapsto` — long maps to
- [x] `\mapsto` — maps to
- [x] `\hookrightarrow` — hook right arrow
- [x] `\hookleftarrow` — hook left arrow
- [x] `\nearrow` — northeast arrow
- [x] `\nwarrow` — northwest arrow
- [x] `\searrow` — southeast arrow
- [x] `\swarrow` — southwest arrow
- [x] `\iff` — if and only if (long double arrow)
- [x] `\implies` — implies (long double right arrow)
- [ ] `\impliedby` — implied by (long double left arrow) (not implemented as standalone)
- [ ] `\circlearrowleft` — circular left arrow (not implemented)
- [ ] `\circlearrowright` — circular right arrow (not implemented)
- [ ] `\curvearrowleft` — curve left arrow (not implemented)
- [ ] `\curvearrowright` — curve right arrow (not implemented)
- [ ] `\dashleftarrow` — dashed left arrow (not implemented)
- [ ] `\dashrightarrow` — dashed right arrow (not implemented)
- [ ] `\downdownarrows` — double down arrows (not implemented)
- [ ] `\downharpoonleft` — down harpoon left (not implemented)
- [ ] `\downharpoonright` — down harpoon right (not implemented)
- [ ] `\leftarrowtail` — left arrow tail (not implemented)
- [ ] `\leftharpoonup` — left harpoon up (not implemented)
- [ ] `\leftharpoondown` — left harpoon down (not implemented)
- [ ] `\leftleftarrows` — double left arrows (not implemented)
- [ ] `\leftrightarrows` — left-right arrows pair (not implemented)
- [ ] `\leftrightharpoons` — left-right harpoons (not implemented)
- [ ] `\leftrightsquigarrow` — squiggly left-right arrow (not implemented)
- [ ] `\Lleftarrow` — triple left arrow (not implemented)
- [ ] `\looparrowleft` — loop left arrow (not implemented)
- [ ] `\looparrowright` — loop right arrow (not implemented)
- [ ] `\Lsh` — left shift (not implemented)
- [ ] `\nleftarrow` — negated left arrow (not implemented)
- [ ] `\nLeftarrow` — negated double left arrow (not implemented)
- [ ] `\nleftrightarrow` — negated left-right arrow (not implemented)
- [ ] `\nLeftrightarrow` — negated double left-right arrow (not implemented)
- [ ] `\nrightarrow` — negated right arrow (not implemented)
- [ ] `\nRightarrow` — negated double right arrow (not implemented)
- [ ] `\restriction` — restriction (not implemented)
- [ ] `\rightarrowtail` — right arrow tail (not implemented)
- [ ] `\rightharpoondown` — right harpoon down (not implemented)
- [ ] `\rightharpoonup` — right harpoon up (not implemented)
- [ ] `\rightleftarrows` — right-left arrows pair (not implemented)
- [ ] `\rightleftharpoons` — right-left harpoons (not implemented)
- [ ] `\rightrightarrows` — double right arrows (not implemented)
- [ ] `\rightsquigarrow` — squiggly right arrow (not implemented)
- [ ] `\Rrightarrow` — triple right arrow (not implemented)
- [ ] `\Rsh` — right shift (not implemented)
- [ ] `\twoheadleftarrow` — two-head left arrow (not implemented)
- [ ] `\twoheadrightarrow` — two-head right arrow (not implemented)
- [ ] `\upharpoonleft` — up harpoon left (not implemented)
- [ ] `\upharpoonright` — up harpoon right (not implemented)
- [ ] `\upuparrows` — double up arrows (not implemented)

### Extensible Arrows

- [ ] `\xleftarrow{abc}` — extensible left arrow (not implemented)
- [ ] `\xrightarrow{abc}` — extensible right arrow (not implemented)
- [ ] `\xLeftarrow{abc}` — extensible double left arrow (not implemented)
- [ ] `\xRightarrow{abc}` — extensible double right arrow (not implemented)
- [ ] `\xleftrightarrow{abc}` — extensible left-right arrow (not implemented)
- [ ] `\xLeftrightarrow{abc}` — extensible double left-right arrow (not implemented)
- [ ] `\xhookleftarrow{abc}` — extensible hook left arrow (not implemented)
- [ ] `\xhookrightarrow{abc}` — extensible hook right arrow (not implemented)
- [ ] `\xtwoheadleftarrow{abc}` — extensible two-head left (not implemented)
- [ ] `\xtwoheadrightarrow{abc}` — extensible two-head right (not implemented)
- [ ] `\xleftharpoonup{abc}` — extensible left harpoon up (not implemented)
- [ ] `\xrightharpoonup{abc}` — extensible right harpoon up (not implemented)
- [ ] `\xleftharpoondown{abc}` — extensible left harpoon down (not implemented)
- [ ] `\xrightharpoondown{abc}` — extensible right harpoon down (not implemented)
- [ ] `\xleftrightharpoons{abc}` — extensible left-right harpoons (not implemented)
- [ ] `\xrightleftharpoons{abc}` — extensible right-left harpoons (not implemented)
- [ ] `\xtofrom{abc}` — extensible to-from (not implemented)
- [ ] `\xmapsto{abc}` — extensible maps-to (not implemented)
- [ ] `\xlongequal{abc}` — extensible long equal (not implemented)

## Special Notation

### Bra-ket Notation

- [x] `\bra{\phi}` — bra (Dirac notation)
- [x] `\ket{\psi}` — ket (Dirac notation)
- [x] `\braket{\phi|\psi}` — braket (inner product)
- [ ] `\Bra{\phi}` — auto-sizing bra (not implemented)
- [ ] `\Ket{\psi}` — auto-sizing ket (not implemented)
- [ ] `\Braket{\phi|\psi}` — auto-sizing braket (not implemented)

### Modular Arithmetic

- [x] `\pmod{a}` — parenthesized mod
- [ ] `x \mod a` — mod with spacing (not implemented)
- [ ] `x \bmod a` — binary mod (not implemented)
- [ ] `x \pod a` — pod (parentheses only) (not implemented)

## Style, Color, Size, and Font

### Class Assignment

- [ ] `\mathbin` — binary operator class (not implemented)
- [ ] `\mathclose` — closing class (not implemented)
- [ ] `\mathinner` — inner class (not implemented)
- [ ] `\mathop` — operator class (not implemented)
- [ ] `\mathopen` — opening class (not implemented)
- [ ] `\mathord` — ordinary class (not implemented)
- [ ] `\mathpunct` — punctuation class (not implemented)
- [ ] `\mathrel` — relation class (not implemented)

### Color

- [x] `\color{blue}` — set text color
- [x] `\textcolor{blue}{text}` — colored text
- [x] `\colorbox{aqua}{text}` — colored background box
- [ ] `\fcolorbox{red}{aqua}{text}` — framed color box (not implemented)

### Font

- [x] `\mathrm{Ab0}` — roman (upright)
- [x] `\mathbf{Ab0}` — bold
- [x] `\mathit{Ab0}` — italic
- [x] `\mathsf{Ab0}` — sans-serif
- [x] `\mathtt{Ab0}` — typewriter
- [x] `\mathcal{AB}` — calligraphic
- [x] `\mathfrak{Ab}` — fraktur
- [x] `\mathbb{AB}` — blackboard bold
- [x] `\mathbfit{Ab}` — bold italic
- [x] `\text{Ab0}` — text mode (roman)
- [x] `\textrm{Ab0}` — text roman
- [x] `\textbf{Ab0}` — text bold
- [x] `\textit{Ab0}` — text italic
- [x] `\textsf{Ab0}` — text sans-serif
- [x] `\texttt{Ab0}` — text typewriter
- [x] `\rm` — switch to roman
- [x] `\bf` — switch to bold
- [x] `\it` `\mit` — switch to italic
- [x] `\sf` — switch to sans-serif
- [x] `\tt` — switch to typewriter
- [x] `\cal` — switch to calligraphic
- [x] `\frak` — switch to fraktur
- [x] `\bm{Ab0}` — bold math (bold italic)
- [x] `\boldsymbol{Ab0}` — bold symbol
- [x] `\bold{Ab0}` — bold (alias)
- [ ] `\mathnormal{Ab0}` — math normal (not implemented)
- [ ] `\mathscr{AB}` — script (not implemented)
- [ ] `\mathsfit{Ab0}` — sans-serif italic (not implemented)
- [ ] `\Bbb{AB}` — blackboard bold alias (not implemented)
- [ ] `\textup{Ab0}` — text upright (not implemented)
- [ ] `\textmd{Ab0}` — text medium (not implemented)
- [ ] `\textnormal{Ab0}` — text normal (not implemented)
- [ ] `\emph{Ab0}` — emphasis (not implemented)
- [ ] `\pmb{Ab0}` — poor man's bold (not implemented)

### Size

- [ ] `\Huge` — huge size (not implemented)
- [ ] `\huge` — huge size (not implemented)
- [ ] `\LARGE` — very large (not implemented)
- [ ] `\Large` — large (not implemented)
- [ ] `\large` — large (not implemented)
- [ ] `\normalsize` — normal size (not implemented)
- [ ] `\small` — small (not implemented)
- [ ] `\footnotesize` — footnote size (not implemented)
- [ ] `\scriptsize` — script size (not implemented)
- [ ] `\tiny` — tiny size (not implemented)

### Style

- [x] `\displaystyle` — display style
- [x] `\textstyle` — text style
- [x] `\scriptstyle` — script style
- [x] `\scriptscriptstyle` — scriptscript style
- [ ] `\limits` — force limits above/below (not implemented as command)
- [ ] `\nolimits` — force limits to the side (not implemented as command)
- [ ] `\verb` — verbatim mode (not implemented)

## Symbols and Punctuation

- [x] `\#` — hash
- [x] `\%` — percent
- [x] `\&` — ampersand
- [x] `\_` — underscore
- [x] `\$` — dollar sign
- [x] `\angle` — angle
- [x] `\measuredangle` — measured angle
- [ ] `\sphericalangle` — spherical angle (not implemented)
- [x] `\top` — top
- [x] `\bot` — bottom
- [x] `\infty` — infinity
- [ ] `\infin` — infinity alias (not implemented)
- [x] `\nabla` — nabla
- [x] `\partial` — partial derivative
- [x] `\prime` — prime
- [ ] `\backprime` — back prime (not implemented)
- [x] `\ldots` — lower dots
- [x] `\cdots` — center dots
- [x] `\vdots` — vertical dots
- [x] `\ddots` — diagonal dots
- [ ] `\dotsb` — dots for binary ops (not implemented)
- [ ] `\dotsc` — dots for commas (not implemented)
- [ ] `\dotsi` — dots for integrals (not implemented)
- [ ] `\dotsm` — dots for multiplication (not implemented)
- [ ] `\dotso` — other dots (not implemented)
- [ ] `\dots` — generic dots (not implemented)
- [ ] `\sdot` — single dot (not implemented)
- [ ] `\mathellipsis` — math ellipsis (not implemented)
- [x] `\Box` `\square` — box/square
- [x] `\triangle` — triangle
- [ ] `\triangledown` — triangle down (not implemented)
- [ ] `\triangleleft` — triangle left (not implemented)
- [ ] `\triangleright` — triangle right (not implemented)
- [ ] `\bigtriangleup` — big triangle up (not implemented)
- [ ] `\bigtriangledown` — big triangle down (not implemented)
- [ ] `\blacksquare` — filled square (not implemented)
- [ ] `\blacktriangle` — filled triangle (not implemented)
- [ ] `\blacktriangledown` — filled triangle down (not implemented)
- [ ] `\blacktriangleleft` — filled triangle left (not implemented)
- [ ] `\blacktriangleright` — filled triangle right (not implemented)
- [x] `\dagger` `\dag` — dagger
- [x] `\ddagger` `\ddag` — double dagger
- [ ] `\Dagger` — dagger alias (not implemented)
- [x] `\degree` — degree symbol
- [x] `\mho` — mho (inverted ohm)
- [x] `\imath` — dotless i
- [x] `\jmath` — dotless j
- [x] `\ell` — script l
- [x] `\hbar` — h-bar
- [x] `\Re` — real part (Fraktur R)
- [x] `\Im` — imaginary part (Fraktur I)
- [x] `\wp` — Weierstrass p
- [x] `\aleph` — aleph
- [x] `\beth` — beth
- [x] `\gimel` — gimel
- [x] `\daleth` — daleth
- [x] `\neg` — negation
- [x] `\forall` — for all
- [x] `\exists` — exists
- [x] `\nexists` — not exists
- [x] `\emptyset` — empty set
- [x] `\varnothing` — variant empty set
- [x] `\vert` `|` — vertical bar
- [x] `\colon` — colon (punctuation)
- [ ] `\surd` — surd (radical symbol) (not implemented)
- [ ] `\star` — five-pointed star (listed under binary operators)
- [ ] `\bigstar` — large star (not implemented)
- [ ] `\diamond` — diamond (listed under binary operators)
- [ ] `\Diamond` `\lozenge` — lozenge (not implemented)
- [ ] `\blacklozenge` — filled lozenge (not implemented)
- [ ] `\clubsuit` `\clubs` — club suit (not implemented)
- [ ] `\diamondsuit` `\diamonds` — diamond suit (not implemented)
- [ ] `\heartsuit` `\hearts` — heart suit (not implemented)
- [ ] `\spadesuit` `\spades` — spade suit (not implemented)
- [ ] `\maltese` — Maltese cross (not implemented)
- [ ] `\flat` — flat (music) (not implemented)
- [ ] `\natural` — natural (music) (not implemented)
- [ ] `\sharp` — sharp (music) (not implemented)
- [ ] `\checkmark` — checkmark (not implemented)
- [ ] `\diagdown` — diagonal down (not implemented)
- [ ] `\diagup` — diagonal up (not implemented)
- [ ] `\circledR` — registered (not implemented)
- [ ] `\circledS` — circled S (not implemented)
- [ ] `\copyright` — copyright (not implemented)
- [ ] `\pounds` `\mathsterling` — pound sign (not implemented)
- [ ] `\yen` — yen sign (not implemented)
- [ ] `\minuso` — minus-o (not implemented)
- [ ] `\P` — pilcrow (paragraph) (not implemented)
- [ ] `\S` — section sign (not implemented)
- [ ] `\KaTeX` — KaTeX logo (not implemented)
- [ ] `\LaTeX` — LaTeX logo (not implemented)
- [ ] `\TeX` — TeX logo (not implemented)

## Units

KaTeX supports various units for spacing and sizing. math-views uses `mu` (math units) internally.

- [x] `mu` — math units (used internally for spacing)
- [ ] `em` — em width (not implemented)
- [ ] `ex` — ex height (not implemented)
- [ ] `pt` — points (not implemented)
- [ ] `bp` — big points (not implemented)
- [ ] `pc` — picas (not implemented)
- [ ] `dd` — didot points (not implemented)
- [ ] `cc` — ciceros (not implemented)
- [ ] `nd` — new didot (not implemented)
- [ ] `nc` — new cicero (not implemented)
- [ ] `mm` — millimeters (not implemented)
- [ ] `cm` — centimeters (not implemented)
- [ ] `in` — inches (not implemented)
- [ ] `sp` — scaled points (not implemented)

## Math Mode Delimiters

- [x] `$...$` — inline math
- [x] `$$...$$` — display math
- [x] `\(...\)` — inline math (LaTeX style)
- [x] `\[...\]` — display math (LaTeX style)

## Subscripts and Superscripts

- [x] `_` — subscript
- [x] `^` — superscript
- [x] `_{...}` — grouped subscript
- [x] `^{...}` — grouped superscript

## Grouping

- [x] `{...}` — group (brace delimited)
