# MathViews

Native LaTeX math rendering for iOS and macOS using CoreText and CoreGraphics. Typesets formulae using the same rules as LaTeX, rendering them without `WKWebView` or JavaScript.

MathViews descends from [iosMath](https://github.com/nickygerritsen/iosMath) (Kostub Deshmukh) via [SwiftMath](https://github.com/nickygerritsen/SwiftMath) (Mike Griebling), rewritten as a modern Swift 6 package with a native SwiftUI API.

## Examples

```latex
x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}
```

![Quadratic Formula](docs/img/quadratic-light.png#gh-light-mode-only)
![Quadratic Formula](docs/img/quadratic-dark.png#gh-dark-mode-only)

```latex
f(x) = \int\limits_{-\infty}^\infty\!\hat f(\xi)\,e^{2 \pi i \xi x}\,\mathrm{d}\xi
```

![Calculus](docs/img/calculus-light.png#gh-light-mode-only)
![Calculus](docs/img/calculus-dark.png#gh-dark-mode-only)

```latex
\frac{1}{n}\sum_{i=1}^{n}x_i \geq \sqrt[n]{\prod_{i=1}^{n}x_i}
```

![AM-GM](docs/img/amgm-light.png#gh-light-mode-only)
![AM-GM](docs/img/amgm-dark.png#gh-dark-mode-only)

```latex
\frac{1}{\left(\sqrt{\phi \sqrt{5}}-\phi\right) e^{\frac25 \pi}}
= 1+\frac{e^{-2\pi}} {1 +\frac{e^{-4\pi}} {1+\frac{e^{-6\pi}} {1+\frac{e^{-8\pi}} {1+\cdots} } } }
```

![Ramanujan Identity](docs/img/ramanujan-light.png#gh-light-mode-only)
![Ramanujan Identity](docs/img/ramanujan-dark.png#gh-dark-mode-only)

More examples in [docs/EXAMPLES.md](docs/EXAMPLES.md).

## Fonts

![Font previews](docs/img/FontsPreviewLight.png#gh-light-mode-only)
![Font previews](docs/img/FontsPreview.png#gh-dark-mode-only)

Six bundled OpenType math fonts:

| Font | Case |
|------|------|
| Latin Modern Math | `.latinModernFont` |
| TeX Gyre Termes | `.termesFont` |
| XITS Math | `.xitsFont` |
| Noto Sans Math | `.notoSansFont` |
| Libertinus Math | `.libertinusFont` |
| Garamond Math | `.garamondFont` |

A Python script (`Sources/MathViews/mathFonts.bundle/math_table_to_plist.py`) is included for generating the `.plist` files required by any additional OTF math font.

## Installation

Add the package in Xcode or `Package.swift`:

```swift
.package(url: "https://github.com/toba/math-views", from: "1.0.0")
```

Requires iOS 18+ / macOS 15+. Swift 6.

## Usage

### MathView (SwiftUI)

`MathView` is a native SwiftUI view — no `UIViewRepresentable` wrapper needed.

```swift
import MathViews

MathView(latex: "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}")
    .font(.termesFont)
    .fontSize(24)
    .textColor(.primary)
```

Available modifiers:

| Modifier | Default | Description |
|----------|---------|-------------|
| `.font(_:)` | `.latinModernFont` | Math font |
| `.fontSize(_:)` | `20` | Point size |
| `.textColor(_:)` | `.primary` | Text color |
| `.labelMode(_:)` | `.display` | `.display` or `.text` |
| `.textAlignment(_:)` | `.center` | `.left`, `.center`, `.right` |
| `.contentInsets(_:)` | `EdgeInsets()` | Padding around the equation |
| `.maxLayoutWidth(_:)` | `nil` | Enable automatic line wrapping |

### MathImage (headless rendering)

`MathImage` renders LaTeX to a `CGImage` without any view:

```swift
var img = MathImage(
    latex: "E = mc^2",
    fontSize: 30,
    textColor: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
)
let (error, cgImage, layout) = img.asImage()
```

### Line wrapping

Set `.maxLayoutWidth(_:)` to enable automatic line breaking between atoms:

```swift
MathView(latex: "a+b+c+d+e+f+g+h+i+j")
    .maxLayoutWidth(200)
```

See [docs/MULTILINE_IMPLEMENTATION_NOTES.md](docs/MULTILINE_IMPLEMENTATION_NOTES.md) for implementation details.

### Math delimiters

Both inline and display LaTeX delimiters are supported:

```swift
MathView(latex: "$E = mc^2$")           // inline (text style)
MathView(latex: "$$\\sum_{k=1}^n k$$")  // display style
MathView(latex: "\\(x^2\\)")            // inline (LaTeX style)
MathView(latex: "\\[x^2\\]")            // display (LaTeX style)
```

Equations without delimiters default to display mode.

### Custom commands

```swift
MathAtomFactory.addLatexSymbol(
    "lcm",
    value: MathAtomFactory.operator(withName: "lcm", limits: false)
)
// Now \lcm works in any LaTeX string
```

## Features

* Fractions (`\frac`, `\dfrac`, `\tfrac`, `\cfrac`) and continued fractions
* Exponents and subscripts
* Square roots and n-th roots
* Trigonometric functions (including inverse hyperbolic: `\arcsinh`, `\arccosh`, etc.)
* Calculus — limits, derivatives, integrals (`\iint`, `\iiint`, `\iiiint`)
* Big operators (sum, product, etc.)
* Big delimiters (`\left`/`\right`) and manual sizing (`\big`, `\Big`, `\bigg`, `\Bigg`)
* Greek alphabet and bold Greek (`\boldsymbol`)
* Combinatorics (`\binom`, `\choose`)
* Math accents (`\hat`, `\tilde`, `\bar`, `\vec`, `\dot`, `\ddot`, `\widehat`, `\widetilde`)
* Vector arrows with automatic stretching (`\overrightarrow`, `\overleftarrow`, `\overleftrightarrow`)
* Matrices (`\smallmatrix`, starred variants with alignment) and `\substack`
* Operator names (`\operatorname`, `\operatorname*`)
* Dirac notation (`\bra`, `\ket`, `\braket`)
* Colors for text and background
* Font style commands (`\bf`, `\text`, `\displaystyle`, `\textstyle`, etc.)
* Inline and display math mode delimiters
* Automatic line wrapping

## License

MathViews is available under the MIT license. See [LICENSE](LICENSE).

### Font licenses

* Latin Modern Math, TeX Gyre Termes — [GUST Font License](Sources/MathViews/mathFonts.bundle/GUST-FONT-LICENSE.txt)
* XITS Math — [SIL Open Font License](Sources/MathViews/mathFonts.bundle/OFL.txt)
* Noto Sans Math — [SIL Open Font License](Sources/MathViews/mathFonts.bundle/OFL.txt)
* Libertinus Math — [SIL Open Font License](Sources/MathViews/mathFonts.bundle/OFL.txt)
* Garamond Math — [SIL Open Font License](Sources/MathViews/mathFonts.bundle/OFL.txt)
