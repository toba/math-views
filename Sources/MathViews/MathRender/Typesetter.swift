import CoreText
import Foundation

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Inter Element Spacing

/// The amount of space to insert between two adjacent atoms.
///
/// TeX defines a matrix of spacing rules indexed by left-atom-type × right-atom-type.
/// Some spacing is suppressed in script styles (sub/superscripts) to keep them compact.
enum InterElementSpaceType: Int {
    case invalid = -1
    case none = 0
    /// Thin space (3 mu). Always applied regardless of style.
    case thin
    /// Thin space (3 mu) but suppressed in script and scriptOfScript styles.
    case nonScriptThin
    /// Medium space (4 mu) but suppressed in script styles.
    case nonScriptMedium
    /// Thick space (5 mu) but suppressed in script styles.
    case nonScriptThick
}

/// The TeX inter-element spacing matrix.
///
/// Rows represent the left atom type, columns the right atom type. The value at
/// `[left][right]` determines how much horizontal space the typesetter inserts.
/// This matrix is derived from Appendix G of *The TeXbook* by Donald Knuth.
let interElementSpaces: [[InterElementSpaceType]] =
    //   ordinary   operator   binary     relation  open       close     punct     fraction
    [
        [.none, .thin, .nonScriptMedium, .nonScriptThick, .none, .none, .none, .nonScriptThin], // ordinary
        [.thin, .thin, .invalid, .nonScriptThick, .none, .none, .none, .nonScriptThin], // operator
        [.nonScriptMedium, .nonScriptMedium, .invalid, .invalid, .nonScriptMedium, .invalid, .invalid,
         .nonScriptMedium], // binary
        [.nonScriptThick, .nonScriptThick, .invalid, .none, .nonScriptThick, .none, .none, .nonScriptThick], // relation
        [.none, .none, .invalid, .none, .none, .none, .none, .none], // open
        [.none, .thin, .nonScriptMedium, .nonScriptThick, .none, .none, .none, .nonScriptThin], // close
        [.nonScriptThin, .nonScriptThin, .invalid, .nonScriptThin, .nonScriptThin, .nonScriptThin, .nonScriptThin, .nonScriptThin], // punct
        [.nonScriptThin, .thin, .nonScriptMedium, .nonScriptThick, .nonScriptThin, .none, .nonScriptThin, .nonScriptThin], // fraction
        [.nonScriptMedium, .nonScriptThin, .nonScriptMedium, .nonScriptThick, .none, .none, .none, .nonScriptThin],
    ] // radical

// Get's the index for the given type. If row is true, the index is for the row (i.e. left element) otherwise it is for the column (right element)
func interElementSpaceIndex(for type: MathAtomType, row: Bool) -> Int {
    switch type {
        // A placeholder is treated as ordinary
        case .color, .textColor, .colorBox, .ordinary, .placeholder: return 0
        case .largeOperator: return 1
        case .binaryOperator: return 2
        case .relation: return 3
        case .open: return 4
        case .close: return 5
        case .punctuation: return 6
        // Fraction and inner are treated the same.
        case .fraction, .inner: return 7
        case .radical:
            if row {
                // Radicals have inter element spaces only when on the left side.
                // Note: This is a departure from latex but we don't want \sqrt{4}4 to look weird so we put a space in between.
                // They have the same spacing as ordinary except with ordinary.
                return 8
            } else {
                // Treat radical as ordinary on the right side
                return 0
            }
        // Numbers, variables, and unary operators are treated as ordinary
        case .number, .variable, .unaryOperator: return 0
        // Decorative types (accent, underline, overline) are treated as ordinary
        case .accent, .underline, .overline: return 0
        // Special types that don't typically participate in spacing are treated as ordinary
        case .boundary, .space, .style, .table: return 0
    }
}

// MARK: - Italics

// mathit
func italicized(_ ch: Character) -> UTF32Char {
    var unicode = ch.utf32Char

    // Special cases for italics
    if ch == "h" { return UnicodeSymbol.planksConstant }
    // Dotless i (U+0131) → Mathematical Italic Small Dotless I (U+1D6A4)
    if ch == "\u{0131}" { return 0x1D6A4 }
    // Dotless j (U+0237) → Mathematical Italic Small Dotless J (U+1D6A5)
    if ch == "\u{0237}" { return 0x1D6A5 }

    if ch.isUpperEnglish {
        unicode = UnicodeSymbol.capitalItalicStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        unicode = UnicodeSymbol.lowerItalicStart + (ch.utf32Char - Character("a").utf32Char)
    } else if ch.isCapitalGreek {
        // Capital Greek characters
        unicode =
            UnicodeSymbol.greekCapitalItalicStart + (ch.utf32Char - UnicodeSymbol.capitalGreekStart)
    } else if ch.isLowerGreek {
        // Greek characters
        unicode = UnicodeSymbol
            .greekLowerItalicStart + (ch.utf32Char - UnicodeSymbol.lowerGreekStart)
    } else if ch.isGreekSymbol {
        return UnicodeSymbol.greekSymbolItalicStart + ch.greekSymbolOrder!
    }
    // Note there are no italicized numbers in unicode so we don't support italicizing numbers.
    return unicode
}

// mathbf
func bolded(_ ch: Character) -> UTF32Char {
    var unicode = ch.utf32Char
    if ch.isUpperEnglish {
        unicode = UnicodeSymbol.mathCapitalBoldStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        unicode = UnicodeSymbol.mathLowerBoldStart + (ch.utf32Char - Character("a").utf32Char)
    } else if ch.isCapitalGreek {
        // Capital Greek characters
        unicode = UnicodeSymbol
            .greekCapitalBoldStart + (ch.utf32Char - UnicodeSymbol.capitalGreekStart)
    } else if ch.isLowerGreek {
        // Greek characters
        unicode = UnicodeSymbol.greekLowerBoldStart + (ch.utf32Char - UnicodeSymbol.lowerGreekStart)
    } else if ch.isGreekSymbol {
        return UnicodeSymbol.greekSymbolBoldStart + ch.greekSymbolOrder!
    } else if ch.isNumber {
        unicode = UnicodeSymbol.numberBoldStart + (ch.utf32Char - Character("0").utf32Char)
    }
    return unicode
}

// mathbfit
func boldItalic(_ ch: Character) -> UTF32Char {
    var unicode = ch.utf32Char
    if ch.isUpperEnglish {
        unicode = UnicodeSymbol
            .mathCapitalBoldItalicStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        unicode = UnicodeSymbol.mathLowerBoldItalicStart + (ch.utf32Char - Character("a").utf32Char)
    } else if ch.isCapitalGreek {
        // Capital Greek characters
        unicode =
            UnicodeSymbol
                .greekCapitalBoldItalicStart + (ch.utf32Char - UnicodeSymbol.capitalGreekStart)
    } else if ch.isLowerGreek {
        // Greek characters
        unicode =
            UnicodeSymbol.greekLowerBoldItalicStart + (ch.utf32Char - UnicodeSymbol.lowerGreekStart)
    } else if ch.isGreekSymbol {
        return UnicodeSymbol.greekSymbolBoldItalicStart + ch.greekSymbolOrder!
    } else if ch.isNumber {
        // No bold italic for numbers so we just bold them.
        unicode = bolded(ch)
    }
    return unicode
}

// LaTeX default
func defaultStyleChar(_ ch: Character) -> UTF32Char {
    if ch.isLowerEnglish || ch.isUpperEnglish || ch.isLowerGreek || ch.isGreekSymbol {
        return italicized(ch)
    } else if ch == "\u{0131}" || ch == "\u{0237}" {
        // Dotless i (U+0131) and dotless j (U+0237) should be italicized in default style
        return italicized(ch)
    } else if ch.isNumber || ch.isCapitalGreek {
        // In the default style numbers and capital greek is roman
        return ch.utf32Char
    } else if ch == "." {
        // . is treated as a number in our code, but it doesn't change fonts.
        return ch.utf32Char
    } else {
        preconditionFailure("Unknown character \(ch) for default style.")
    }
}

// mathcal/mathscr (calligraphic or script)
func calligraphic(_ ch: Character) -> UTF32Char {
    // Calligraphic has lots of exceptions:
    switch ch {
        case "B": return 0x212C // Script B (Bernoulli)
        case "E": return 0x2130 // Script E (emf)
        case "F": return 0x2131 // Script F (Fourier)
        case "H": return 0x210B // Script H (hamiltonian)
        case "I": return 0x2110 // Script I
        case "L": return 0x2112 // Script L (Laplace)
        case "M": return 0x2133 // Script M (M-matrix)
        case "R": return 0x211B // Script R (Riemann integral)
        case "e": return 0x212F // Script e (Natural exponent)
        case "g": return 0x210A // Script g (real number)
        case "o": return 0x2134 // Script o (order)
        default: break
    }
    var unicode: UTF32Char
    if ch.isUpperEnglish {
        unicode = UnicodeSymbol.mathCapitalScriptStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        // Latin Modern Math does not have lower case calligraphic characters, so we use
        // the default style instead of showing a ?
        unicode = defaultStyleChar(ch)
    } else {
        // Calligraphic characters don't exist for greek or numbers, we give them the
        // default treatment.
        unicode = defaultStyleChar(ch)
    }
    return unicode
}

// mathtt (monospace)
func typewriter(_ ch: Character) -> UTF32Char {
    if ch.isUpperEnglish {
        return UnicodeSymbol.mathCapitalTTStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        return UnicodeSymbol.mathLowerTTStart + (ch.utf32Char - Character("a").utf32Char)
    } else if ch.isNumber {
        return UnicodeSymbol.numberTTStart + (ch.utf32Char - Character("0").utf32Char)
    }
    // Monospace characters don't exist for greek, we give them the
    // default treatment.
    return defaultStyleChar(ch)
}

// mathsf
func sansSerif(_ ch: Character) -> UTF32Char {
    if ch.isUpperEnglish {
        UnicodeSymbol.mathCapitalSansSerifStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        UnicodeSymbol.mathLowerSansSerifStart + (ch.utf32Char - Character("a").utf32Char)
    } else if ch.isNumber {
        UnicodeSymbol.numberSansSerifStart + (ch.utf32Char - Character("0").utf32Char)
    } else {
        // Sans-serif characters don't exist for greek, we give them the
        // default treatment.
        defaultStyleChar(ch)
    }
}

// mathfrak
func fraktur(_ ch: Character) -> UTF32Char {
    // Fraktur has exceptions:
    switch ch {
        case "C": return 0x212D // C Fraktur
        case "H": return 0x210C // Hilbert space
        case "I": return 0x2111 // Imaginary
        case "R": return 0x211C // Real
        case "Z": return 0x2128 // Z Fraktur
        default: break
    }
    if ch.isUpperEnglish {
        return UnicodeSymbol.mathCapitalFrakturStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        return UnicodeSymbol.mathLowerFrakturStart + (ch.utf32Char - Character("a").utf32Char)
    }
    // Fraktur characters don't exist for greek & numbers, we give them the
    // default treatment.
    return defaultStyleChar(ch)
}

// mathbb (double struck)
func blackboard(_ ch: Character) -> UTF32Char {
    // Blackboard has lots of exceptions:
    switch ch {
        case "C": return 0x2102 // Complex numbers
        case "H": return 0x210D // Quaternions
        case "N": return 0x2115 // Natural numbers
        case "P": return 0x2119 // Primes
        case "Q": return 0x211A // Rationals
        case "R": return 0x211D // Reals
        case "Z": return 0x2124 // Integers
        default: break
    }
    if ch.isUpperEnglish {
        return UnicodeSymbol.mathCapitalBlackboardStart + (ch.utf32Char - Character("A").utf32Char)
    } else if ch.isLowerEnglish {
        return UnicodeSymbol.mathLowerBlackboardStart + (ch.utf32Char - Character("a").utf32Char)
    } else if ch.isNumber {
        return UnicodeSymbol.numberBlackboardStart + (ch.utf32Char - Character("0").utf32Char)
    }
    // Blackboard characters don't exist for greek, we give them the
    // default treatment.
    return defaultStyleChar(ch)
}

func styleCharacter(_ ch: Character, fontStyle: FontStyle) -> UTF32Char {
    switch fontStyle {
        case .defaultStyle: return defaultStyleChar(ch)
        case .roman: return ch.utf32Char
        case .bold: return bolded(ch)
        case .italic: return italicized(ch)
        case .boldItalic: return boldItalic(ch)
        case .calligraphic: return calligraphic(ch)
        case .typewriter: return typewriter(ch)
        case .sansSerif: return sansSerif(ch)
        case .fraktur: return fraktur(ch)
        case .blackboard: return blackboard(ch)
    }
}

func changeFont(_ str: String, fontStyle: FontStyle) -> String {
    var retval = ""
    let codes = Array(str)
    for i in 0 ..< str.count {
        let ch = codes[i]
        var unicode = styleCharacter(ch, fontStyle: fontStyle)
        unicode = NSSwapHostIntToLittle(unicode)
        let charStr = String(UnicodeScalar(unicode)!)
        retval.append(charStr)
    }
    return retval
}

func bboxDetails(_ bbox: CGRect, ascent: inout CGFloat, descent: inout CGFloat) {
    ascent = max(0, bbox.maxY - 0)

    // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
    descent = max(0, 0 - bbox.minY)
}

// MARK: - Typesetter

/// `Typesetter` is the core rendering engine that converts mathematical atom structures (`MathList`)
/// into displayable visual representations (`MathListDisplay`).
///
/// ## Overview
///
/// This class implements the fundamental typesetting algorithm for mathematical equations, following TeX's
/// typesetting rules for spacing, positioning, and layout. It handles:
///
/// - **Atom processing**: Converts mathematical atoms into display objects with proper positioning
/// - **Inter-element spacing**: Applies TeX spacing rules between different atom types (operators, relations, etc.)
/// - **Script positioning**: Places superscripts and subscripts at appropriate positions and sizes
/// - **Line breaking**: Supports automatic line wrapping with intelligent breaking points
/// - **Complex structures**: Handles fractions, radicals, matrices, delimiters, accents, and large operators
///
/// ## Architecture
///
/// The typesetter uses a stateful approach where it maintains:
/// - Current position (`currentPosition`) for placing elements
/// - Display atom array (`displayAtoms`) collecting rendered elements
/// - Font and style information for determining sizes and positioning
/// - Line breaking state when width constraints are active
///
/// ## Line Breaking
///
/// MathViews implements sophisticated multiline support with two complementary mechanisms:
///
/// ### 1. Interatom Line Breaking (Primary)
/// Breaks equations **between atoms** when content exceeds width constraints. This preserves semantic
/// structure and respects TeX spacing rules. Supported for:
/// - Variables, operators, relations, punctuation
/// - Fractions, radicals, large operators (inline when they fit)
/// - Delimited expressions, colored sections, matrices
/// - Atoms with scripts (superscripts/subscripts)
///
/// ### 2. Universal Line Breaking (Fallback)
/// Uses Core Text for Unicode-aware breaking within very long text atoms, with number protection
/// to prevent splitting numerical values.
///
/// ### Advanced Features
/// - **Dynamic line height**: Adjusts spacing based on actual content height (tall fractions get more space)
/// - **Break quality scoring**: Prefers breaking after operators rather than arbitrary positions
/// - **Look-ahead optimization**: Considers upcoming atoms to find better break points
/// - **Early exit optimization**: Skips expensive checks when remaining content clearly fits
///
/// ## Usage
///
/// The main entry point is the static `makeLineDisplay(for:)` method:
///
/// ```swift
/// // Basic rendering (no line breaking)
/// let display = Typesetter.makeLineDisplay(for: mathList, font: font, style: .display)
///
/// // With line breaking support
/// let display = Typesetter.makeLineDisplay(for: mathList, font: font, style: .display, maxWidth: 300)
/// ```
///
/// ## Implementation Notes
///
/// - Total implementation: ~7,900 lines including helper functions and spacing rules
/// - Tokenization infrastructure: Additional ~2,000 lines for advanced line breaking (see `Tokenization/` folder)
/// - Threading: Uses locks for thread-safe access to spacing tables
/// - Performance: Includes early-exit optimizations when content fits within constraints
///
/// For detailed line breaking implementation notes, see `MULTILINE_IMPLEMENTATION_NOTES.md`.
class Typesetter {
    var font: FontInstance!
    var displayAtoms = [Display]()
    var currentPosition = CGPoint.zero
    var style: LineStyle { didSet { _styleFont = nil } }
    private var _styleFont: FontInstance?
    var styleFont: FontInstance {
        if _styleFont == nil {
            _styleFont = font.withSize( Self.styleSize(style, font: font))
        }
        return _styleFont!
    }

    var cramped = false
    var spaced = false
    var maxWidth: CGFloat = 0 // Maximum width for line breaking, 0 means no constraint

    static func makeLineDisplay(
        for mathList: MathList?,
        font: FontInstance?,
        style: LineStyle,
        maxWidth: CGFloat = 0,
    ) -> MathListDisplay? {
        let finalizedList = mathList?.finalized
        return makeLineDisplay(
            for: finalizedList, font: font, style: style, cramped: false, spaced: false,
            maxWidth: maxWidth,
        )
    }

    static func makeLineDisplay(
        for mathList: MathList?,
        font: FontInstance?,
        style: LineStyle,
        cramped: Bool,
        spaced: Bool = false,
        maxWidth: CGFloat = 0,
    ) -> MathListDisplay? {
        assert(font != nil)

        // Always use tokenization approach
        // The tokenization path handles both constrained (maxWidth > 0) and unconstrained (maxWidth = 0) rendering
        return makeLineDisplayWithTokenization(
            for: mathList,
            font: font,
            style: style,
            cramped: cramped,
            spaced: spaced,
            maxWidth: maxWidth,
        )
    }

    static var placeholderColor: PlatformColor { PlatformColor.blue }

    init(
        withFont font: FontInstance?,
        style: LineStyle,
        cramped: Bool,
        spaced: Bool,
        maxWidth: CGFloat = 0,
    ) {
        self.font = font
        displayAtoms = [Display]()
        currentPosition = CGPoint.zero
        self.cramped = cramped
        self.spaced = spaced
        self.maxWidth = maxWidth
        self.style = style
    }

    static func preprocessMathList(_ ml: MathList?) -> [MathAtom] {
        // Note: Some of the preprocessing described by the TeX algorithm is done in the finalize method of MathList.
        // Specifically rules 5 & 6 in Appendix G are handled by finalize.
        // This function does not do a complete preprocessing as specified by TeX either. It removes any special atom types
        // that are not included in TeX and applies Rule 14 to merge ordinary characters.
        var preprocessed = [MathAtom]() //  arrayWithCapacity:ml.atoms.count)
        var prevNode: MathAtom! = nil
        preprocessed.reserveCapacity(ml!.atoms.count)
        for atom in ml!.atoms {
            if atom.type == .variable || atom.type == .number {
                // This is not a TeX type node. TeX does this during parsing the input.
                // switch to using the italic math font
                // We convert it to ordinary
                let newFont = changeFont(atom.nucleus,
                                         fontStyle: atom.fontStyle) // mathItalicize(atom.nucleus)
                atom.type = .ordinary
                atom.nucleus = newFont
            } else if atom.type == .unaryOperator {
                // Neither of these are TeX nodes. TeX treats these as Ordinary. So will we.
                atom.type = .ordinary
            } else if atom.type == .binaryOperator {
                // CRITICAL FIX: Convert binary operators to ordinary (unary) in appropriate contexts
                // According to TeX rules (TeXbook Appendix G, Rule 5), a binary operator is converted
                // to ordinary when it appears after: Bin, Op, Rel, Open, Punct, or at the beginning
                // This handles cases like "=-2" where minus should be unary, not binary
                let shouldConvertToOrdinary: Bool
                if prevNode == nil {
                    // At the beginning of the list
                    shouldConvertToOrdinary = true
                } else {
                    switch prevNode.type {
                        case .binaryOperator, .relation, .open, .punctuation, .largeOperator:
                            shouldConvertToOrdinary = true
                        default:
                            shouldConvertToOrdinary = false
                    }
                }

                if shouldConvertToOrdinary {
                    atom.type = .ordinary
                }
            }

            if atom.type == .ordinary {
                // This is Rule 14 to merge ordinary characters.
                // combine ordinary atoms together
                // CRITICAL FIX: Only fuse atoms with the same fontStyle
                // This prevents fusing roman text (\text{...}) with italic math variables (A, B, etc.)
                // which would cause incorrect line breaking when the combined string is tokenized
                if prevNode != nil, prevNode.type == .ordinary, prevNode.subScript == nil,
                   prevNode.superScript == nil, prevNode.fontStyle == atom.fontStyle
                {
                    prevNode.fuse(with: atom)
                    // skip the current node, we are done here.
                    continue
                }
            }

            // Italic correction could be added here or in second pass
            prevNode = atom
            preprocessed.append(atom)
        }
        return preprocessed
    }

    // returns the size of the font in this style
    static func styleSize(_ style: LineStyle, font: FontInstance?) -> CGFloat {
        let original = font!.fontSize
        let scaled: CGFloat
        switch style {
            case .display, .text:
                scaled = original
            case .script:
                scaled = original * font!.mathTable!.scriptScaleDown
            case .scriptOfScript:
                scaled = original * font!.mathTable!.scriptScriptScaleDown
        }
        // Apply minimum font size threshold to prevent deeply nested exponents
        // from becoming unreadable (common for expressions like 2^{2^{2^2}})
        // Minimum of 6pt ensures readability while maintaining proper hierarchy
        return max(scaled, 6.0)
    }

    // MARK: - Spacing

    // Returned in units of mu = 1/18 em.
    func spacingInMu(_ type: InterElementSpaceType) -> Int {
        // let valid = [LineStyle.display, .text]
        switch type {
            case .invalid: return -1
            case .none: return 0
            case .thin: return 3
            case .nonScriptThin: return style.isAboveScript ? 3 : 0
            case .nonScriptMedium: return style.isAboveScript ? 4 : 0
            case .nonScriptThick: return style.isAboveScript ? 5 : 0
        }
    }

    func interElementSpace(_ left: MathAtomType, right: MathAtomType) -> CGFloat {
        let leftIndex = interElementSpaceIndex(for: left, row: true)
        let rightIndex = interElementSpaceIndex(for: right, row: false)
        let spaceArray = interElementSpaces[Int(leftIndex)]
        let spaceTypeObj = spaceArray[Int(rightIndex)]
        let spaceType = spaceTypeObj
        assert(spaceType != .invalid, "Invalid space between \(left) and \(right)")

        let spaceMultiplier = spacingInMu(spaceType)
        if spaceMultiplier > 0 {
            // 1 em = size of font in pt. space multiplier is in multiples mu or 1/18 em
            return CGFloat(spaceMultiplier) * styleFont.mathTable!.muUnit
        }
        return 0
    }

    // MARK: - Subscript/Superscript

    func scriptStyle() -> LineStyle {
        switch style {
            case .display, .text: return .script
            case .script, .scriptOfScript: return .scriptOfScript
        }
    }

    // subscript is always cramped
    func subscriptCramped() -> Bool { true }

    // superscript is cramped only if the current style is cramped
    func superScriptCramped() -> Bool { cramped }

    func superScriptShiftUp() -> CGFloat {
        if cramped {
            return styleFont.mathTable!.superscriptShiftUpCramped
        } else {
            return styleFont.mathTable!.superscriptShiftUp
        }
    }

    // make scripts for the last atom
    // index is the index of the element which is getting the sub/super scripts.
    func makeScripts(_ atom: MathAtom?, display: Display?, index: UInt, delta: CGFloat) {
        guard let atom else { return }
        guard atom.subScript != nil || atom.superScript != nil else { return }
        guard let mathTable = styleFont.mathTable else { return }

        var superScriptShiftUp = 0.0
        var subscriptShiftDown = 0.0

        display?.hasScript = true
        if !(display is CTLineDisplay), let display {
            // get the font in script style
            let scriptFontSize = Self.styleSize(scriptStyle(), font: font)
            let scriptFont = font.withSize( scriptFontSize)
            let scriptFontMetrics = scriptFont.mathTable

            // if it is not a simple line then
            if let scriptFontMetrics {
                superScriptShiftUp = display.ascent - scriptFontMetrics.superscriptBaselineDropMax
                subscriptShiftDown = display.descent + scriptFontMetrics.subscriptBaselineDropMin
            }
        }

        if atom.superScript == nil {
            guard
                let _subscript = Typesetter.makeLineDisplay(
                    for: atom.subScript, font: font, style: scriptStyle(), cramped: subscriptCramped(),
                )
            else { return }
            _subscript.type = .subscript
            _subscript.index = Int(index)

            subscriptShiftDown = fmax(subscriptShiftDown, mathTable.subscriptShiftDown)
            subscriptShiftDown = fmax(
                subscriptShiftDown,
                _subscript.ascent - mathTable.subscriptTopMax,
            )
            // add the subscript
            _subscript.position = CGPoint(
                x: currentPosition.x,
                y: currentPosition.y - subscriptShiftDown,
            )
            displayAtoms.append(_subscript)
            // update the position
            currentPosition.x += _subscript.width + mathTable.spaceAfterScript
            return
        }

        guard
            let superScript = Typesetter.makeLineDisplay(
                for: atom.superScript, font: font, style: scriptStyle(), cramped: superScriptCramped(),
            )
        else { return }
        superScript.type = .superscript
        superScript.index = Int(index)
        superScriptShiftUp = fmax(superScriptShiftUp, self.superScriptShiftUp())
        superScriptShiftUp = fmax(
            superScriptShiftUp, superScript.descent + mathTable.superscriptBottomMin,
        )

        if atom.subScript == nil {
            superScript.position = CGPoint(
                x: currentPosition.x, y: currentPosition.y + superScriptShiftUp,
            )
            displayAtoms.append(superScript)
            // update the position
            currentPosition.x += superScript.width + mathTable.spaceAfterScript
            return
        }
        guard
            let ssubscript = Typesetter.makeLineDisplay(
                for: atom.subScript, font: font, style: scriptStyle(), cramped: subscriptCramped(),
            )
        else { return }
        ssubscript.type = .subscript
        ssubscript.index = Int(index)
        subscriptShiftDown = fmax(subscriptShiftDown, mathTable.subscriptShiftDown)

        // joint positioning of subscript & superscript
        let subSuperScriptGap =
            (superScriptShiftUp - superScript.descent) + (subscriptShiftDown - ssubscript.ascent)
        if subSuperScriptGap < mathTable.subSuperscriptGapMin {
            // Set the gap to atleast as much
            subscriptShiftDown += mathTable.subSuperscriptGapMin - subSuperScriptGap
            let superscriptBottomDelta =
                mathTable
                    .superscriptBottomMaxWithSubscript - (superScriptShiftUp - superScript.descent)
            if superscriptBottomDelta > 0 {
                // superscript is lower than the max allowed by the font with a subscript.
                superScriptShiftUp += superscriptBottomDelta
                subscriptShiftDown -= superscriptBottomDelta
            }
        }
        // The delta is the italic correction above that shift superscript position
        superScript.position = CGPoint(
            x:
            currentPosition.x + delta, y: currentPosition.y + superScriptShiftUp,
        )
        displayAtoms.append(superScript)
        ssubscript.position = CGPoint(
            x: currentPosition.x,
            y: currentPosition.y - subscriptShiftDown,
        )
        displayAtoms.append(ssubscript)
        currentPosition.x +=
            max(superScript.width + delta, ssubscript.width) + mathTable.spaceAfterScript
    }

    // MARK: - Helper Functions

    func safeUIntFromLocation(_ location: Int) -> UInt {
        if location < 0 { return 0 }
        return UInt(location)
    }
}
