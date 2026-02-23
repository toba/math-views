public import Foundation

/// Reverses a [String: String] dictionary, preferring the shortest (then lexicographically first) key
/// when multiple keys map to the same value.
private func buildReverseMapping(_ forward: [String: String]) -> [String: String] {
    var output = [String: String]()
    for (key, value) in forward {
        if let existing = output[value] {
            if key.count > existing.count { continue }
            if key.count == existing.count, key.compare(existing) == .orderedDescending { continue }
        }
        output[value] = key
    }
    return output
}

/// A factory to create commonly used MathAtoms.
public enum MathAtomFactory {
    public static let aliases = [
        "lnot": "neg",
        "land": "wedge",
        "lor": "vee",
        "ne": "neq",
        "le": "leq",
        "ge": "geq",
        "lbrace": "{",
        "rbrace": "}",
        "Vert": "|",
        "gets": "leftarrow",
        "to": "rightarrow",
        "iff": "Longleftrightarrow",
        "AA": "angstrom",
    ]

    public static let delimiters = [
        ".": "", // . means no delimiter
        "(": "(",
        ")": ")",
        "[": "[",
        "]": "]",
        "<": "\u{2329}",
        ">": "\u{232A}",
        "/": "/",
        "\\": "\\",
        "|": "|",
        "lgroup": "\u{27EE}",
        "rgroup": "\u{27EF}",
        "||": "\u{2016}",
        "Vert": "\u{2016}",
        "vert": "|",
        "uparrow": "\u{2191}",
        "downarrow": "\u{2193}",
        "updownarrow": "\u{2195}",
        "Uparrow": "\u{21D1}",
        "Downarrow": "\u{21D3}",
        "Updownarrow": "\u{21D5}",
        "backslash": "\\",
        "rangle": "\u{232A}",
        "langle": "\u{2329}",
        "rbrace": "}",
        "}": "}",
        "{": "{",
        "lbrace": "{",
        "lceil": "\u{2308}",
        "rceil": "\u{2309}",
        "lfloor": "\u{230A}",
        "rfloor": "\u{230B}",
        // Corner brackets (amssymb)
        "ulcorner": "\u{231C}", // upper left corner
        "urcorner": "\u{231D}", // upper right corner
        "llcorner": "\u{231E}", // lower left corner
        "lrcorner": "\u{231F}", // lower right corner
        // Double square brackets (Strachey brackets)
        "llbracket": "\u{27E6}", // left double bracket
        "rrbracket": "\u{27E7}", // right double bracket
    ]

    public static let delimiterValueToName: [String: String] = buildReverseMapping(delimiters)

    public static let accents = [
        "grave": "\u{0300}",
        "acute": "\u{0301}",
        "hat": "\u{0302}", // In our implementation hat and widehat behave the same.
        "tilde": "\u{0303}", // In our implementation tilde and widetilde behave the same.
        "bar": "\u{0304}",
        "breve": "\u{0306}",
        "dot": "\u{0307}",
        "ddot": "\u{0308}",
        "check": "\u{030C}",
        "vec": "\u{20D7}",
        "widehat": "\u{0302}",
        "widetilde": "\u{0303}",
        "overleftarrow": "\u{20D6}", // Combining left arrow above
        "overrightarrow": "\u{20D7}", // Combining right arrow above (same as vec)
        "overleftrightarrow": "\u{20E1}", // Combining left right arrow above
    ]

    public static let accentValueToName: [String: String] = buildReverseMapping(accents)

    static var supportedLatexSymbolNames: [String] {
        symbolState.symbols.keys.map { String($0) }
    }

    private struct SymbolState {
        var symbols: [String: MathAtom]
        var textToLatex: [String: String]?
    }

    private static var symbolState = SymbolState(
        symbols: initialSymbols,
        textToLatex: nil,
    )

    public static var textToLatexSymbolName: [String: String] {
        if let cached = symbolState.textToLatex {
            return cached
        }
        var output = [String: String]()
        for (key, atom) in symbolState.symbols {
            if atom.nucleus.isEmpty { continue }
            if let existingText = output[atom.nucleus] {
                if key.count > existingText.count {
                    continue
                } else if key.count == existingText.count {
                    if key.compare(existingText) == .orderedDescending {
                        continue
                    }
                }
            }
            output[atom.nucleus] = key
        }
        symbolState.textToLatex = output
        return output
    }

    //  public static let sharedInstance = MathAtomFactory()

    static let fontStyles: [String: FontStyle] = [
        "mathnormal": .defaultStyle,
        "mathrm": .roman,
        "textrm": .roman,
        "rm": .roman,
        "mathbf": .bold,
        "bf": .bold,
        "textbf": .bold,
        "mathcal": .calligraphic,
        "cal": .calligraphic,
        "mathtt": .typewriter,
        "texttt": .typewriter,
        "mathit": .italic,
        "textit": .italic,
        "mit": .italic,
        "mathsf": .sansSerif,
        "textsf": .sansSerif,
        "mathfrak": .fraktur,
        "frak": .fraktur,
        "mathbb": .blackboard,
        "mathbfit": .boldItalic,
        "bm": .boldItalic,
        "boldsymbol": .boldItalic,
        "text": .roman,
        // Note: operatorname is handled specially in MathListBuilder to create proper operators
    ]

    public static func fontStyle(named fontName: String) -> FontStyle? {
        fontStyles[fontName]
    }

    public static func fontNameForStyle(_ fontStyle: FontStyle) -> String {
        switch fontStyle {
            case .defaultStyle: return "mathnormal"
            case .roman: return "mathrm"
            case .bold: return "mathbf"
            case .fraktur: return "mathfrak"
            case .calligraphic: return "mathcal"
            case .italic: return "mathit"
            case .sansSerif: return "mathsf"
            case .blackboard: return "mathbb"
            case .typewriter: return "mathtt"
            case .boldItalic: return "bm"
        }
    }

    /// Returns an atom for the multiplication sign (i.e., \times or "*")
    public static func times() -> MathAtom {
        MathAtom(type: .binaryOperator, value: UnicodeSymbol.multiplication)
    }

    /// Returns an atom for the division sign (i.e., \div or "/")
    public static func divide() -> MathAtom {
        MathAtom(type: .binaryOperator, value: UnicodeSymbol.division)
    }

    /// Returns an atom which is a placeholder square
    public static func placeholder() -> MathAtom {
        MathAtom(type: .placeholder, value: UnicodeSymbol.whiteSquare)
    }

    /// Returns a fraction with a placeholder for the numerator and denominator
    public static func placeholderFraction() -> Fraction {
        let fraction = Fraction()
        fraction.numerator = MathList()
        fraction.numerator?.add(placeholder())
        fraction.denominator = MathList()
        fraction.denominator?.add(placeholder())
        return fraction
    }

    /// Returns a square root with a placeholder as the radicand.
    public static func placeholderSquareRoot() -> Radical {
        let radical = Radical()
        radical.radicand = MathList()
        radical.radicand?.add(placeholder())
        return radical
    }

    /// Returns a radical with a placeholder as the radicand.
    public static func placeholderRadical() -> Radical {
        let radical = Radical()
        radical.radicand = MathList()
        radical.degree = MathList()
        radical.radicand?.add(placeholder())
        radical.degree?.add(placeholder())
        return radical
    }

    /// Latin Small Letter Dotless I (U+0131) - base character that can be styled
    private static let dotlessI: Character = "\u{0131}"
    /// Latin Small Letter Dotless J (U+0237) - base character that can be styled
    private static let dotlessJ: Character = "\u{0237}"

    public static func atom(fromAccentedCharacter character: Character) -> MathAtom? {
        if let symbol = supportedAccentedCharacters[character] {
            // first handle any special characters
            if let atom = atom(forLatexSymbol: symbol.0) {
                return atom
            }

            if let accent = MathAtomFactory.accent(named: symbol.0) {
                // The command is an accent
                let list = MathList()
                let baseChar = Array(symbol.1)[0]
                // Use dotless variants for 'i' and 'j' to avoid double dots with accents.
                // We use the base Latin dotless characters (U+0131, U+0237) rather than
                // the pre-styled mathematical italic versions (U+1D6A4, U+1D6A5) so that
                // font style (roman, bold, etc.) is properly applied during rendering.
                if baseChar == "i" {
                    list.add(MathAtom(type: .ordinary, value: String(dotlessI)))
                } else if baseChar == "j" {
                    list.add(MathAtom(type: .ordinary, value: String(dotlessJ)))
                } else {
                    list.add(atom(forCharacter: baseChar))
                }
                accent.innerList = list
                return accent
            }
        }
        return nil
    }

    // MARK: -

    /// Gets the atom with the right type for the given character. If an atom
    /// cannot be determined for a given character this returns nil.
    /// This function follows latex conventions for assigning types to the atoms.
    /// The following characters are not supported and will return nil:
    /// - Any non-ascii character.
    /// - Any control character or spaces (< 0x21)
    /// - Latex control chars: $ % # & ~ '
    /// - Chars with special meaning in latex: ^ _ { } \
    /// All other characters, including those with accents, will have a non-nil atom returned.
    public static func atom(forCharacter character: Character) -> MathAtom? {
        let characterString = String(character)
        switch characterString {
            case "\u{0410}" ... "\u{044F}":
                // Cyrillic alphabet
                return MathAtom(type: .ordinary, value: characterString)
            case _ where supportedAccentedCharacters.keys.contains(character):
                // support for áéíóúýàèìòùâêîôûäëïöüÿãñõçøåæœß'ÁÉÍÓÚÝÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÃÑÕÇØÅÆŒ
                return atom(fromAccentedCharacter: character)
            case _ where character.utf32Char < 0x0021 || character.utf32Char > 0x007E:
                return nil
            case "$", "%", "#", "&", "~", "\'", "^", "_", "{", "}", "\\":
                return nil
            case "(", "[":
                return MathAtom(type: .open, value: characterString)
            case ")", "]", "!", "?":
                return MathAtom(type: .close, value: characterString)
            case ",", ";":
                return MathAtom(type: .punctuation, value: characterString)
            case "=", ">", "<":
                return MathAtom(type: .relation, value: characterString)
            case ":":
                // Math colon is ratio. Regular colon is \colon
                return MathAtom(type: .relation, value: "\u{2236}")
            case "-":
                return MathAtom(type: .binaryOperator, value: "\u{2212}")
            case "+", "*":
                return MathAtom(type: .binaryOperator, value: characterString)
            case ".", "0" ... "9":
                return MathAtom(type: .number, value: characterString)
            case "a" ... "z", "A" ... "Z":
                return MathAtom(type: .variable, value: characterString)
            case "\"", "/", "@", "`", "|":
                return MathAtom(type: .ordinary, value: characterString)
            default:
                assertionFailure(
                    "Unknown ASCII character '\(character)'. Should have been handled earlier.",
                )
                return nil
        }
    }

    /// Returns a `MathList` with one atom per character in the given string. This function
    /// does not do any LaTeX conversion or interpretation. It simply uses `atom(forCharacter:)` to
    /// convert the characters to atoms. Any character that cannot be converted is ignored.
    public static func atomList(for string: String) -> MathList {
        let list = MathList()
        for character in string {
            if let newAtom = atom(forCharacter: character) {
                list.add(newAtom)
            }
        }
        return list
    }

    /// Returns an atom with the right type for a given latex symbol (e.g. theta)
    /// If the latex symbol is unknown this will return nil. This supports LaTeX aliases as well.
    public static func atom(forLatexSymbol name: String) -> MathAtom? {
        var name = name
        if let canonicalName = aliases[name] {
            name = canonicalName
        }
        return symbolState.symbols[name]?.copy()
    }

    /// Finds the name of the LaTeX symbol name for the given atom. This function is a reverse
    /// of the above function. If no latex symbol name corresponds to the atom, then this returns `nil`
    /// If nucleus of the atom is empty, then this will return `nil`.
    /// Note: This is not an exact reverse of the above in the case of aliases. If an LaTeX alias
    /// points to a given symbol, then this function will return the original symbol name and not the
    /// alias.
    /// Note: This function does not convert MathSpaces to latex command names either.
    public static func latexSymbolName(for atom: MathAtom) -> String? {
        guard !atom.nucleus.isEmpty else { return nil }
        return textToLatexSymbolName[atom.nucleus]
    }

    /// Define a latex symbol for rendering. This function allows defining custom symbols that are
    /// not already present in the default set, or override existing symbols with new meaning.
    /// e.g. to define a symbol for "lcm" one can call:
    /// `MathAtomFactory.add(latexSymbol:"lcm", value:MathAtomFactory.`operator`(named: "lcm", hasLimits: false))`
    public static func add(latexSymbol name: String, value: MathAtom) {
        // Ensure textToLatex is initialized before mutating
        if symbolState.textToLatex == nil {
            var output = [String: String]()
            for (key, atom) in symbolState.symbols {
                if atom.nucleus.isEmpty { continue }
                if let existingText = output[atom.nucleus] {
                    if key.count > existingText.count { continue }
                    if key.count == existingText.count,
                       key.compare(existingText) == .orderedDescending
                    {
                        continue
                    }
                }
                output[atom.nucleus] = key
            }
            symbolState.textToLatex = output
        }
        symbolState.symbols[name] = value
        symbolState.textToLatex?[value.nucleus] = name
    }

    /// Returns a large opertor for the given name. If limits is true, limits are set up on
    /// the operator and displayed differently.
    public static func `operator`(named name: String, hasLimits: Bool) -> LargeOperator {
        LargeOperator(value: name, hasLimits: hasLimits)
    }

    /// Returns an accent with the given name. The name of the accent is the LaTeX name
    /// such as `grave`, `hat` etc. If the name is not a recognized accent name, this
    /// returns nil. The `innerList` of the returned `Accent` is nil.
    public static func accent(named name: String) -> Accent? {
        if let accentValue = accents[name] {
            let accent = Accent(value: accentValue)
            // Mark stretchy arrow accents (\overleftarrow, \overrightarrow, \overleftrightarrow)
            // These should stretch to match content width
            // \vec is NOT stretchy - it should use a small fixed-size arrow
            let stretchyAccents: Set<String> = [
                "overleftarrow",
                "overrightarrow",
                "overleftrightarrow",
            ]
            accent.isStretchy = stretchyAccents.contains(name)

            // Mark wide accents (\widehat, \widetilde, \widecheck)
            // These should stretch horizontally to cover content width
            // \hat, \tilde, \check are NOT wide - they use fixed-size accents
            let wideAccents: Set<String> = ["widehat", "widetilde", "widecheck"]
            accent.isWide = wideAccents.contains(name)

            return accent
        }
        return nil
    }

    /// Returns the accent name for the given accent. This is the reverse of the above
    /// function.
    public static func accentName(_ accent: Accent) -> String? {
        accentValueToName[accent.nucleus]
    }

    /// Creates a new boundary atom for the given delimiter name. If the delimiter name
    /// is not recognized it returns nil. A delimiter name can be a single character such
    /// as '(' or a latex command such as 'uparrow'.
    /// @note In order to distinguish between the delimiter '|' and the delimiter '\|' the delimiter '\|'
    /// the has been renamed to '||'.
    public static func boundary(forDelimiter name: String) -> MathAtom? {
        if let delimValue = delimiters[name] {
            return MathAtom(type: .boundary, value: delimValue)
        }
        return nil
    }

    /// Returns the delimiter name for a boundary atom. This is a reverse of the above function.
    /// If the atom is not a boundary atom or if the delimiter value is unknown this returns `nil`.
    /// @note This is not an exact reverse of the above function. Some delimiters have two names (e.g.
    /// `<` and `langle`) and this function always returns the shorter name.
    public static func delimiterName(of boundary: MathAtom) -> String? {
        guard boundary.type == .boundary else { return nil }
        return delimiterValueToName[boundary.nucleus]
    }

    /// Returns a fraction with the given numerator and denominator.
    public static func fraction(withNumerator numerator: MathList,
                                denominator: MathList) -> Fraction
    {
        let fraction = Fraction()
        fraction.numerator = numerator
        fraction.denominator = denominator
        return fraction
    }

    public static func mathListForCharacters(_ chars: String) -> MathList? {
        let list = MathList()
        for character in chars {
            if let atom = atom(forCharacter: character) {
                list.add(atom)
            }
        }
        return list
    }

    /// Simplification of above function when numerator and denominator are simple strings.
    /// This function converts the strings to a `Fraction`.
    public static func fraction(
        withNumeratorString numeratorString: String, denominatorString: String,
    ) -> Fraction {
        let numerator = Self.atomList(for: numeratorString)
        let denominator = Self.atomList(for: denominatorString)
        return Self.fraction(withNumerator: numerator, denominator: denominator)
    }

    static let matrixEnvs = [
        "matrix": [],
        "pmatrix": ["(", ")"],
        "bmatrix": ["[", "]"],
        "Bmatrix": ["{", "}"],
        "vmatrix": ["vert", "vert"],
        "Vmatrix": ["Vert", "Vert"],
        "smallmatrix": [],
        // Starred versions with optional alignment
        "matrix*": [],
        "pmatrix*": ["(", ")"],
        "bmatrix*": ["[", "]"],
        "Bmatrix*": ["{", "}"],
        "vmatrix*": ["vert", "vert"],
        "Vmatrix*": ["Vert", "Vert"],
    ]

    /// Builds a table for a given environment with the given rows. Returns a `MathAtom` containing the
    /// table and any other atoms necessary for the given environment. Returns nil and sets error
    /// if the table could not be built.
    /// @param env The environment to use to build the table. If the env is nil, then the default table is built.
    /// @note The reason this function returns a `MathAtom` and not a `MathTable` is because some
    /// matrix environments are have builtin delimiters added to the table and hence are returned as inner atoms.
    ///
    /// Column constraints by environment (matching KaTeX behavior):
    /// - `aligned`, `eqalign`: Any number of columns (1, 2, 3, 4+) with r-l-r-l alignment pattern
    /// - `split`: Maximum 2 columns with r-l alignment
    /// - `gather`, `displaylines`: Exactly 1 column, centered
    /// - `cases`: 1 or 2 columns, left-aligned
    /// - `eqnarray`: Exactly 3 columns with r-c-l alignment
    public static func table(
        withEnvironment env: String?, alignment: ColumnAlignment? = nil, rows: [[MathList]],
    ) throws(ParseError) -> MathAtom {
        let table = MathTable(environment: env)

        for i in 0 ..< rows.count {
            let row = rows[i]
            for j in 0 ..< row.count {
                table.setCell( row[j], row: i, column: j)
            }
        }

        if env == nil {
            table.interColumnSpacing = 0
            table.interRowAdditionalSpacing = 1
            for i in 0 ..< table.numColumns {
                table.setAlignment( .left, forColumn: i)
            }
            return table
        } else if let env {
            if let delimiters = matrixEnvs[env] {
                table.environment = "matrix"

                // smallmatrix uses script style and tighter spacing for inline use
                let isSmallMatrix = (env == "smallmatrix")

                table.interRowAdditionalSpacing = 0
                table.interColumnSpacing = isSmallMatrix ? 6 : 18

                let style = MathStyle(style: isSmallMatrix ? .script : .text)

                for i in 0 ..< table.cells.count {
                    for j in 0 ..< table.cells[i].count {
                        table.cells[i][j].insert(style, at: 0)
                    }
                }

                // Apply alignment for starred matrix environments
                if let align = alignment {
                    for col in 0 ..< table.numColumns {
                        table.setAlignment( align, forColumn: col)
                    }
                }

                if delimiters.count == 2 {
                    let inner = Inner()
                    inner.leftBoundary = Self.boundary(forDelimiter: delimiters[0])
                    inner.rightBoundary = Self.boundary(forDelimiter: delimiters[1])
                    inner.innerList = MathList(atoms: [table])
                    return inner
                } else {
                    return table
                }
            } else if env == "eqalign" || env == "split" || env == "aligned" {
                if env == "split", table.numColumns > 2 {
                    throw .invalidNumColumns("split environment can have at most 2 columns")
                }

                let spacer = MathAtom(type: .ordinary, value: "")

                for i in 0 ..< table.cells.count {
                    var colIndex = 1
                    while colIndex < table.cells[i].count {
                        table.cells[i][colIndex].insert(spacer, at: 0)
                        colIndex += 2
                    }
                }

                table.interRowAdditionalSpacing = 1
                table.interColumnSpacing = 0

                for col in 0 ..< table.numColumns {
                    table.setAlignment( col.isMultiple(of: 2) ? .right : .left, forColumn: col)
                }

                return table
            } else if env == "displaylines" || env == "gather" {
                if table.numColumns != 1 {
                    throw .invalidNumColumns("\(env) environment can only have 1 column")
                }

                table.interRowAdditionalSpacing = 1
                table.interColumnSpacing = 0

                table.setAlignment( .center, forColumn: 0)

                return table
            } else if env == "eqnarray" {
                if table.numColumns != 3 {
                    throw .invalidNumColumns("\(env) environment can only have 3 columns")
                }

                table.interRowAdditionalSpacing = 1
                table.interColumnSpacing = 18

                table.setAlignment( .right, forColumn: 0)
                table.setAlignment( .center, forColumn: 1)
                table.setAlignment( .left, forColumn: 2)

                return table
            } else if env == "cases" {
                if table.numColumns != 1, table.numColumns != 2 {
                    throw .invalidNumColumns("cases environment can have 1 or 2 columns")
                }

                table.interRowAdditionalSpacing = 0
                table.interColumnSpacing = 18

                table.setAlignment( .left, forColumn: 0)
                if table.numColumns == 2 {
                    table.setAlignment( .left, forColumn: 1)
                }

                let style = MathStyle(style: .text)
                for i in 0 ..< table.cells.count {
                    for j in 0 ..< table.cells[i].count {
                        table.cells[i][j].insert(style, at: 0)
                    }
                }

                let inner = Inner()
                inner.leftBoundary = Self.boundary(forDelimiter: "{")
                inner.rightBoundary = Self.boundary(forDelimiter: ".")
                let space = Self.atom(forLatexSymbol: ",")!

                inner.innerList = MathList(atoms: [space, table])

                return inner
            } else {
                throw .invalidEnv("Unknown environment \(env)")
            }
        }
        throw .internalError("Unexpected nil environment")
    }

    @available(
        *, deprecated,
        message: "Use the throwing variant: table(withEnvironment:alignment:rows:) throws(ParseError)"
    )
    public static func table(
        withEnvironment env: String?,
        alignment: ColumnAlignment? = nil,
        rows: [[MathList]],
        error _: inout NSError?,
    ) -> MathAtom? {
        do {
            return try table(withEnvironment: env, alignment: alignment, rows: rows)
        } catch {
            return nil
        }
    }
}
