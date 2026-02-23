public import Foundation

/// `MathListBuilder` is a class for parsing LaTeX into an `MathList` that
/// can be rendered and processed mathematically.
struct EnvProperties {
    var envName: String?
    var ended: Bool
    var numRows: Int
    var alignment: ColumnAlignment? // Optional alignment for starred matrix environments

    init(name: String?, alignment: ColumnAlignment? = nil) {
        envName = name
        numRows = 0
        ended = false
        self.alignment = alignment
    }
}

/// The error encountered when parsing a LaTeX string.
public enum ParseError: Error, Equatable {
    /// The braces { } do not match.
    case mismatchBraces(String)
    /// A command in the string is not recognized.
    case invalidCommand(String)
    /// An expected character such as ] was not found.
    case characterNotFound(String)
    /// The \left or \right command was not followed by a delimiter.
    case missingDelimiter(String)
    /// The delimiter following \left or \right was not a valid delimiter.
    case invalidDelimiter(String)
    /// There is no \right corresponding to the \left command.
    case missingRight(String)
    /// There is no \left corresponding to the \right command.
    case missingLeft(String)
    /// The environment given to the \begin command is not recognized
    case invalidEnv(String)
    /// A command is used which is only valid inside a \begin,\end environment
    case missingEnv(String)
    /// There is no \begin corresponding to the \end command.
    case missingBegin(String)
    /// There is no \end corresponding to the \begin command.
    case missingEnd(String)
    /// The number of columns do not match the environment
    case invalidNumColumns(String)
    /// Internal error, due to a programming mistake.
    case internalError(String)
    /// Limit control applied incorrectly
    case invalidLimits(String)

    public var localizedDescription: String {
        switch self {
            case let .mismatchBraces(m), let .invalidCommand(m), let .characterNotFound(m),
                 let .missingDelimiter(m), let .invalidDelimiter(m), let .missingRight(m),
                 let .missingLeft(m), let .invalidEnv(m), let .missingEnv(m),
                 let .missingBegin(m), let .missingEnd(m), let .invalidNumColumns(m),
                 let .internalError(m), let .invalidLimits(m):
                return m
        }
    }

    /// Bridge to NSError for backward compatibility.
    func asNSError() -> NSError {
        NSError(
            domain: "ParseError", code: 0,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription],
        )
    }
}

/// `MathListBuilder` is a class for parsing LaTeX into an `MathList` that
/// can be rendered and processed mathematically.
public struct MathListBuilder {
    /// The math mode determines rendering style (inline vs display)
    enum MathMode {
        /// Display style - larger operators, limits above/below (e.g., $$...$$, \[...\])
        case display
        /// Inline/text style - compact operators, limits to the side (e.g., $...$, \(...\))
        case inline

        /// Convert MathMode to LineStyle for rendering
        func toLineStyle() -> LineStyle {
            switch self {
                case .display:
                    return .display
                case .inline:
                    return .text
            }
        }
    }

    var string: String
    var currentCharIndex: String.Index
    var currentInnerAtom: Inner?
    var currentEnv: EnvProperties?
    var currentFontStyle: FontStyle
    var spacesAllowed: Bool
    var mathMode: MathMode = .display

    /// Contains any error that occurred during parsing.
    var error: ParseError?

    // MARK: - Character-handling routines

    var hasCharacters: Bool { currentCharIndex < string.endIndex }

    // gets the next character and increments the index
    mutating func nextCharacter() -> Character {
        assert(
            hasCharacters,
            "Retrieving character at index \(currentCharIndex) beyond length \(string.count)",
        )
        let ch = string[currentCharIndex]
        currentCharIndex = string.index(after: currentCharIndex)
        return ch
    }

    mutating func unlookCharacter() {
        assert(currentCharIndex > string.startIndex, "Unlooking when at the first character.")
        if currentCharIndex > string.startIndex {
            currentCharIndex = string.index(before: currentCharIndex)
        }
    }

    // Peek at next command without consuming it (for \not lookahead)
    mutating func peekNextCommand() -> String {
        let savedIndex = currentCharIndex
        skipSpaces()

        guard hasCharacters else {
            currentCharIndex = savedIndex
            return ""
        }

        let char = nextCharacter()
        let command: String

        if char == "\\" {
            command = readCommand()
        } else {
            command = ""
        }

        // Restore position
        currentCharIndex = savedIndex
        return command
    }

    // Consume the next command (after peeking)
    mutating func consumeNextCommand() {
        skipSpaces()

        guard hasCharacters else { return }

        let char = nextCharacter()
        if char == "\\" {
            _ = readCommand()
        }
    }

    mutating func expectCharacter(_ ch: Character) -> Bool {
        assertNotSpace(ch)
        skipSpaces()

        if hasCharacters {
            let nextChar = nextCharacter()
            assertNotSpace(nextChar)
            if nextChar == ch {
                return true
            } else {
                unlookCharacter()
                return false
            }
        }
        return false
    }

    public static let spaceToCommands: [CGFloat: String] = [
        3: ",",
        4: ">",
        5: ";",
        -3: "!",
        18: "quad",
        36: "qquad",
    ]

    public static let styleToCommands: [LineStyle: String] = [
        .display: "displaystyle",
        .text: "textstyle",
        .script: "scriptstyle",
        .scriptOfScript: "scriptscriptstyle",
    ]

    // Comprehensive mapping of \not command combinations to Unicode negated symbols
    public static let notCombinations: [String: String] = [
        // Primary targets (user requested)
        "equiv": "\u{2262}", // ≢ Not equivalent
        "subset": "\u{2284}", // ⊄ Not subset
        "in": "\u{2209}", // ∉ Not element of

        // Additional standard negations
        "sim": "\u{2241}", // ≁ Not similar
        "approx": "\u{2249}", // ≉ Not approximately equal
        "cong": "\u{2247}", // ≇ Not congruent
        "parallel": "\u{2226}", // ∦ Not parallel
        "subseteq": "\u{2288}", // ⊈ Not subset or equal
        "supset": "\u{2285}", // ⊅ Not superset
        "supseteq": "\u{2289}", // ⊉ Not superset or equal
        "=": "\u{2260}", // ≠ Not equal (alternative to \neq)
    ]

    /// Delimiter sizing commands with their size multipliers (relative to font size).
    /// Values based on standard TeX: at 10pt, \big=8.5pt, \Big=11.5pt, \bigg=14.5pt, \Bigg=17.5pt
    /// These translate to approximately 0.85x, 1.15x, 1.45x, 1.75x of font size.
    /// We use slightly larger values to ensure visible size differences.
    public static let delimiterSizeCommands: [String: CGFloat] = [
        // Basic sizing commands
        "big": 1.0,
        "Big": 1.4,
        "bigg": 1.8,
        "Bigg": 2.2,
        // Left variants (same sizes, just semantic distinction in LaTeX)
        "bigl": 1.0,
        "Bigl": 1.4,
        "biggl": 1.8,
        "Biggl": 2.2,
        // Right variants
        "bigr": 1.0,
        "Bigr": 1.4,
        "biggr": 1.8,
        "Biggr": 2.2,
        // Middle variants (used between delimiters)
        "bigm": 1.0,
        "Bigm": 1.4,
        "biggm": 1.8,
        "Biggm": 2.2,
    ]

    init(string: String) {
        self.error = nil
        self.string = string
        currentCharIndex = string.startIndex
        currentFontStyle = .defaultStyle
        spacesAllowed = false
    }

    // MARK: - Delimiter Detection

    /// Detects and strips LaTeX math delimiters from the input string.
    /// Returns the cleaned content and the detected math mode.
    /// Supports: $...$ \(...\) $$...$$ \[...\] and environments
    func detectAndStripDelimiters(from str: String) -> (String, MathMode) {
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check display delimiters first (more specific patterns)

        // \[...\] - LaTeX display math
        if trimmed.hasPrefix("\\["), trimmed.hasSuffix("\\]"), trimmed.count > 4 {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 2)
            let end = trimmed.index(trimmed.endIndex, offsetBy: -2)
            return (String(trimmed[start ..< end]), .display)
        }

        // $$...$$ - TeX display math (check before single $)
        if trimmed.hasPrefix("$$"), trimmed.hasSuffix("$$"), trimmed.count > 4 {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 2)
            let end = trimmed.index(trimmed.endIndex, offsetBy: -2)
            return (String(trimmed[start ..< end]), .display)
        }

        // Check inline delimiters

        // \(...\) - LaTeX inline math
        if trimmed.hasPrefix("\\("), trimmed.hasSuffix("\\)"), trimmed.count > 4 {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 2)
            let end = trimmed.index(trimmed.endIndex, offsetBy: -2)
            return (String(trimmed[start ..< end]), .inline)
        }

        // $...$ - TeX inline math (must check after $$)
        if trimmed.hasPrefix("$"), trimmed.hasSuffix("$"), trimmed.count > 2,
           !trimmed.hasPrefix("$$")
        {
            let start = trimmed.index(after: trimmed.startIndex)
            let end = trimmed.index(before: trimmed.endIndex)
            return (String(trimmed[start ..< end]), .inline)
        }

        // Check if it's an environment (\begin{...}\end{...})
        // These are handled by existing logic and are display mode by default
        if trimmed.hasPrefix("\\begin{") {
            return (str, .display)
        }

        // No delimiters found - default to display mode (current behavior for backward compatibility)
        return (str, .display)
    }

    // MARK: - MathList builder functions

    /// Builds a mathlist from the internal `string`. Returns nil if there is an error.
    public mutating func build() -> MathList? {
        // Detect and strip delimiters, updating the string and mode
        let (cleanedString, mode) = detectAndStripDelimiters(from: string)
        string = cleanedString
        currentCharIndex = cleanedString.startIndex
        mathMode = mode

        // If inline mode, we could optionally prepend a \textstyle command
        // to force inline rendering of operators. For now, just track the mode.

        let list = buildInternal(false)
        if hasCharacters, error == nil {
            setError(.mismatchBraces("Mismatched braces: \(string)"))
            return nil
        }
        if error != nil {
            return nil
        }

        // Note: For inline mode, we insert \textstyle to match LaTeX behavior.
        // However, fractionStyle() has been modified to keep fractions at the
        // same font size in both display and text modes (not one level smaller).
        // Large operators show limits above/below in text style due to the updated
        // condition in makeLargeOp() that checks both .display and .text styles.
        if mode == .inline, list != nil, !list!.atoms.isEmpty {
            // Prepend \textstyle to force inline rendering
            let styleAtom = MathStyle(style: .text)
            list!.atoms.insert(styleAtom, at: 0)
        }

        return list
    }

    /// Construct a math list from a given string. If there is parse error, returns
    /// nil. To retrieve the error use the function `MathListBuilder.build(fromString:error:)`.
    public static func build(fromString string: String) -> MathList? {
        var builder = MathListBuilder(string: string)
        return builder.build()
    }

    /// Construct a math list from a given string, throwing on parse errors.
    public static func buildChecked(fromString string: String) throws(ParseError) -> MathList {
        var builder = MathListBuilder(string: string)
        let output = builder.build()
        if let error = builder.error { throw error }
        return output ?? MathList()
    }

    /// Construct a math list from a given string. If there is an error while
    /// constructing the string, this returns nil. The error is returned in the
    /// `error` parameter.
    @available(
        *, deprecated, message: "Use the throwing variant: build(fromString:) throws(ParseError)"
    )
    public static func build(fromString string: String, error: inout NSError?) -> MathList? {
        var builder = MathListBuilder(string: string)
        let output = builder.build()
        if let parseError = builder.error {
            error = parseError.asNSError()
            return nil
        }
        return output
    }

    /// Construct a math list from a given string and return the detected style.
    /// This method detects LaTeX delimiters like \[...\], $$...$$, $...$, \(...\)
    /// and returns the appropriate rendering style (.display or .text).
    ///
    /// If there is a parse error, returns nil for the MathList.
    ///
    /// - Parameter string: The LaTeX string to parse
    /// - Returns: A tuple containing the parsed MathList and the detected LineStyle
    public static func buildWithStyle(fromString string: String) -> (
        mathList: MathList?, style: LineStyle,
    ) {
        var builder = MathListBuilder(string: string)
        let mathList = builder.build()
        let style = builder.mathMode.toLineStyle()
        return (mathList, style)
    }

    /// Construct a math list and detect style, throwing on parse errors.
    public static func buildWithStyleChecked(fromString string: String) throws(ParseError) -> (
        mathList: MathList, style: LineStyle,
    ) {
        var builder = MathListBuilder(string: string)
        let output = builder.build()
        let style = builder.mathMode.toLineStyle()
        if let error = builder.error { throw error }
        return (output ?? MathList(), style)
    }

    @available(
        *, deprecated,
        message: "Use the throwing variant: buildWithStyle(fromString:) throws(ParseError)"
    )
    public static func buildWithStyle(fromString string: String, error: inout NSError?) -> (
        mathList: MathList?, style: LineStyle,
    ) {
        var builder = MathListBuilder(string: string)
        let output = builder.build()
        let style = builder.mathMode.toLineStyle()
        if let parseError = builder.error {
            error = parseError.asNSError()
            return (nil, style)
        }
        return (output, style)
    }

    public mutating func buildInternal(_ oneCharOnly: Bool) -> MathList? {
        buildInternal(oneCharOnly, stopChar: nil)
    }

    public mutating func buildInternal(_ oneCharOnly: Bool,
                                       stopChar stop: Character?) -> MathList?
    {
        let list = MathList()
        assert(!(oneCharOnly && stop != nil), "Cannot set both oneCharOnly and stopChar.")
        var prevAtom: MathAtom?
        while hasCharacters {
            if error != nil { return nil } // If there is an error thus far then bail out.

            var atom: MathAtom?
            let char = nextCharacter()

            if oneCharOnly {
                if char == "^" || char == "}" || char == "_" || char == "&" {
                    // this is not the character we are looking for.
                    // They are meant for the caller to look at.
                    unlookCharacter()
                    return list
                }
            }
            // If there is a stop character, keep scanning 'til we find it
            if stop != nil, char == stop! {
                return list
            }

            if char == "^" {
                assert(!oneCharOnly, "This should have been handled before")
                if prevAtom == nil || prevAtom!.superScript != nil || !prevAtom!.isScriptAllowed() {
                    // If there is no previous atom, or if it already has a superscript
                    // or if scripts are not allowed for it, then add an empty node.
                    prevAtom = MathAtom(type: .ordinary, value: "")
                    list.add(prevAtom!)
                }
                // this is a superscript for the previous atom
                // note: if the next char is the stopChar it will be consumed by the ^ and so it doesn't count as stop
                prevAtom!.superScript = buildInternal(true)
                continue
            } else if char == "_" {
                assert(!oneCharOnly, "This should have been handled before")
                if prevAtom == nil || prevAtom!.subScript != nil || !prevAtom!.isScriptAllowed() {
                    // If there is no previous atom, or if it already has a subcript
                    // or if scripts are not allowed for it, then add an empty node.
                    prevAtom = MathAtom(type: .ordinary, value: "")
                    list.add(prevAtom!)
                }
                // this is a subscript for the previous atom
                // note: if the next char is the stopChar it will be consumed by the _ and so it doesn't count as stop
                prevAtom!.subScript = buildInternal(true)
                continue
            } else if char == "{" {
                // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
                if let subList = buildInternal(false, stopChar: "}") {
                    prevAtom = subList.atoms.last
                    list.append(subList)
                    if oneCharOnly {
                        return list
                    }
                }
                continue
            } else if char == "}" {
                // \ means a command
                assert(!oneCharOnly, "This should have been handled before")
                assert(stop == nil, "This should have been handled before")
                // Special case: } terminates implicit table (envName == nil) created by \\
                // This happens when \\ is used inside braces: \substack{a \\ b}
                if currentEnv != nil, currentEnv!.envName == nil {
                    // Mark environment as ended, don't consume the }
                    currentEnv!.ended = true
                    return list
                }
                // We encountered a closing brace when there is no stop set, that means there was no
                // corresponding opening brace.
                setError(.mismatchBraces("Mismatched braces."))
                return nil
            } else if char == "\\" {
                let command = readCommand()
                let done = stopCommand(command, list: list, stopChar: stop)
                if done != nil {
                    return done
                } else if error != nil {
                    return nil
                }
                if applyModifier(command, atom: prevAtom) {
                    continue
                }

                if let fontStyle = MathAtomFactory.fontStyle(named: command) {
                    let oldSpacesAllowed = spacesAllowed
                    // Text has special consideration where it allows spaces without escaping.
                    spacesAllowed = command == "text"
                    let oldFontStyle = currentFontStyle
                    currentFontStyle = fontStyle
                    if let sublist = buildInternal(true) {
                        // Restore the font style.
                        currentFontStyle = oldFontStyle
                        spacesAllowed = oldSpacesAllowed

                        prevAtom = sublist.atoms.last
                        list.append(sublist)
                        if oneCharOnly {
                            return list
                        }
                    }
                    continue
                }
                atom = atomForCommand(command)
                if atom == nil {
                    // this was an unknown command,
                    // we flag an error and return
                    // (note setError will not set the error if there is already one, so we flag internal error
                    // in the odd case that an _error is not set.
                    setError(.internalError("Internal error"))
                    return nil
                }
            } else if char == "&" {
                // used for column separation in tables
                assert(!oneCharOnly, "This should have been handled before")
                if currentEnv != nil {
                    return list
                } else {
                    // Create a new table with the current list and a default env
                    if let table = buildTable(env: nil, firstList: list, isRow: false) {
                        return MathList(atom: table)
                    } else {
                        return nil
                    }
                }
            } else if spacesAllowed, char == " " {
                // If spaces are allowed then spaces do not need escaping with a \ before being used.
                atom = MathAtomFactory.atom(forLatexSymbol: " ")
            } else {
                atom = MathAtomFactory.atom(forCharacter: char)
                if atom == nil {
                    // Not a recognized character in standard math mode
                    // In text mode (spacesAllowed && roman style), accept any Unicode character for fallback font support
                    // This enables Chinese, Japanese, Korean, emoji, etc. in \text{} commands
                    if spacesAllowed, currentFontStyle == .roman {
                        atom = MathAtom(type: .ordinary, value: String(char))
                    } else {
                        // In math mode or non-text commands, skip unrecognized characters
                        continue
                    }
                }
            }

            assert(atom != nil, "Atom shouldn't be nil")
            atom?.fontStyle = currentFontStyle
            // If this is an accent atom (e.g., from an accented character like "é"),
            // propagate the font style to the inner list atoms that don't already have
            // an explicit font style. This handles Unicode accented characters which are
            // converted to accents by atom(fromAccentedCharacter:) without font style context.
            // We only set font style on atoms with .defaultStyle to avoid overriding
            // explicit font style commands like \textbf inside accents.
            if let accent = atom as? Accent, let innerList = accent.innerList {
                for innerAtom in innerList.atoms where innerAtom.fontStyle == .defaultStyle {
                    innerAtom.fontStyle = currentFontStyle
                }
            }
            list.add(atom)
            prevAtom = atom

            if oneCharOnly {
                return list
            }
        }
        if stop != nil {
            if stop == "}" {
                // We did not find a corresponding closing brace.
                setError(.mismatchBraces("Missing closing brace"))
            } else {
                // we never found our stop character
                let errorMessage = "Expected character not found: \(stop!)"
                setError(.characterNotFound(errorMessage))
            }
        }
        return list
    }

    // MARK: - MathList to LaTeX conversion

    /// This converts the MathList to LaTeX.
    public static func mathListToString(_ ml: MathList?) -> String {
        var str = ""
        var currentfontStyle = FontStyle.defaultStyle
        if let atomList = ml {
            for atom in atomList.atoms {
                if currentfontStyle != atom.fontStyle {
                    if currentfontStyle != .defaultStyle {
                        str += "}"
                    }
                    if atom.fontStyle != .defaultStyle {
                        let fontStyleName = MathAtomFactory.fontNameForStyle(atom.fontStyle)
                        str += "\\\(fontStyleName){"
                    }
                    currentfontStyle = atom.fontStyle
                }
                if atom.type == .fraction {
                    if let frac = atom as? Fraction {
                        if frac.isContinuedFraction {
                            // Generate \cfrac with optional alignment
                            if frac.alignment != "c" {
                                str +=
                                    "\\cfrac[\(frac.alignment)]{\(mathListToString(frac.numerator!))}{\(mathListToString(frac.denominator!))}"
                            } else {
                                str +=
                                    "\\cfrac{\(mathListToString(frac.numerator!))}{\(mathListToString(frac.denominator!))}"
                            }
                        } else if frac.hasRule {
                            str +=
                                "\\frac{\(mathListToString(frac.numerator!))}{\(mathListToString(frac.denominator!))}"
                        } else {
                            let command: String
                            if frac.leftDelimiter.isEmpty, frac.rightDelimiter.isEmpty {
                                command = "atop"
                            } else if frac.leftDelimiter == "(", frac.rightDelimiter == ")" {
                                command = "choose"
                            } else if frac.leftDelimiter == "{", frac.rightDelimiter == "}" {
                                command = "brace"
                            } else if frac.leftDelimiter == "[", frac.rightDelimiter == "]" {
                                command = "brack"
                            } else {
                                command = "atopwithdelims\(frac.leftDelimiter)\(frac.rightDelimiter)"
                            }
                            str +=
                                "{\(mathListToString(frac.numerator!)) \\\(command) \(mathListToString(frac.denominator!))}"
                        }
                    }
                } else if atom.type == .radical {
                    str += "\\sqrt"
                    if let rad = atom as? Radical {
                        if rad.degree != nil {
                            str += "[\(mathListToString(rad.degree!))]"
                        }
                        str += "{\(mathListToString(rad.radicand!))}"
                    }
                } else if atom.type == .inner {
                    if let inner = atom as? Inner {
                        if inner.leftBoundary != nil || inner.rightBoundary != nil {
                            if inner.leftBoundary != nil {
                                str += "\\left\(delimiterString( inner.leftBoundary!)) "
                            } else {
                                str += "\\left. "
                            }

                            str += mathListToString(inner.innerList!)

                            if inner.rightBoundary != nil {
                                str += "\\right\(delimiterString( inner.rightBoundary!)) "
                            } else {
                                str += "\\right. "
                            }
                        } else {
                            str += "{\(mathListToString(inner.innerList!))}"
                        }
                    }
                } else if atom.type == .table {
                    if let table = atom as? MathTable {
                        if !table.environment.isEmpty {
                            str += "\\begin{\(table.environment)}"
                        }

                        for i in 0 ..< table.numRows {
                            let row = table.cells[i]
                            for j in 0 ..< row.count {
                                let cell = row[j]
                                if table.environment == "matrix" {
                                    if cell.atoms.count >= 1, cell.atoms[0].type == .style {
                                        // remove first atom
                                        cell.atoms.removeFirst()
                                    }
                                }
                                if table.environment == "eqalign" || table.environment == "aligned"
                                    || table.environment == "split"
                                {
                                    if j == 1, cell.atoms.count >= 1,
                                       cell.atoms[0].type == .ordinary,
                                       cell.atoms[0].nucleus.isEmpty
                                    {
                                        // remove empty nucleus added for spacing
                                        cell.atoms.removeFirst()
                                    }
                                }
                                str += mathListToString(cell)
                                if j < row.count - 1 {
                                    str += "&"
                                }
                            }
                            if i < table.numRows - 1 {
                                str += "\\\\ "
                            }
                        }
                        if !table.environment.isEmpty {
                            str += "\\end{\(table.environment)}"
                        }
                    }
                } else if atom.type == .overline {
                    if let overline = atom as? OverLine {
                        str += "\\overline"
                        str += "{\(mathListToString(overline.innerList!))}"
                    }
                } else if atom.type == .underline {
                    if let underline = atom as? UnderLine {
                        str += "\\underline"
                        str += "{\(mathListToString(underline.innerList!))}"
                    }
                } else if atom.type == .accent {
                    if let accent = atom as? Accent {
                        str +=
                            "\\\(MathAtomFactory.accentName(accent)!){\(mathListToString(accent.innerList!))}"
                    }
                } else if atom.type == .largeOperator {
                    if let op = atom as? LargeOperator,
                       let command = MathAtomFactory.latexSymbolName(for: atom),
                       let originalOp = MathAtomFactory
                       .atom(forLatexSymbol: command) as? LargeOperator
                    {
                        str += "\\\(command) "
                        if originalOp.hasLimits != op.hasLimits {
                            if op.hasLimits {
                                str += "\\limits "
                            } else {
                                str += "\\nolimits "
                            }
                        }
                    }
                } else if atom.type == .space {
                    if let space = atom as? MathSpace {
                        if let command = Self.spaceToCommands[space.space] {
                            str += "\\\(command) "
                        } else {
                            str += String(format: "\\mkern%.1fmu", space.space)
                        }
                    }
                } else if atom.type == .style {
                    if let style = atom as? MathStyle {
                        if let command = Self.styleToCommands[style.style] {
                            str += "\\\(command) "
                        }
                    }
                } else if atom.nucleus.isEmpty {
                    str += "{}"
                } else if atom.nucleus == "\u{2236}" {
                    // math colon
                    str += ":"
                } else if atom.nucleus == "\u{2212}" {
                    // math minus
                    str += "-"
                } else {
                    if let command = MathAtomFactory.latexSymbolName(for: atom) {
                        str += "\\\(command) "
                    } else {
                        str += "\(atom.nucleus)"
                    }
                }

                if atom.superScript != nil {
                    str += "^{\(mathListToString(atom.superScript!))}"
                }

                if atom.subScript != nil {
                    str += "_{\(mathListToString(atom.subScript!))}"
                }
            }
        }
        if currentfontStyle != .defaultStyle {
            str += "}"
        }
        return str
    }

    public static func delimiterString(_ delim: MathAtom) -> String {
        if let command = MathAtomFactory.delimiterName(of: delim) {
            let singleChars = ["(", ")", "[", "]", "<", ">", "|", ".", "/"]
            if singleChars.contains(command) {
                return command
            } else if command == "||" {
                return "\\|"
            } else {
                return "\\\(command)"
            }
        }
        return ""
    }

    mutating func atomForCommand(_ command: String) -> MathAtom? {
        if let atom = MathAtomFactory.atom(forLatexSymbol: command) {
            return atom
        }
        if let accent = MathAtomFactory.accent(named: command) {
            // The command is an accent
            accent.innerList = buildInternal(true)
            return accent
        } else if command == "frac" {
            // A fraction command has 2 arguments
            let frac = Fraction()
            frac.numerator = buildInternal(true)
            frac.denominator = buildInternal(true)
            return frac
        } else if command == "cfrac" {
            // A continued fraction command with optional alignment and 2 arguments
            let frac = Fraction()
            frac.isContinuedFraction = true

            // Parse optional alignment parameter [l], [r], [c]
            skipSpaces()
            if hasCharacters, string[currentCharIndex] == "[" {
                _ = nextCharacter() // consume '['
                if hasCharacters {
                    let alignmentChar = nextCharacter()
                    if alignmentChar == "l" || alignmentChar == "r" || alignmentChar == "c" {
                        frac.alignment = String(alignmentChar)
                    }
                }
                // Consume closing ']'
                if hasCharacters, string[currentCharIndex] == "]" {
                    _ = nextCharacter()
                }
            }

            frac.numerator = buildInternal(true)
            frac.denominator = buildInternal(true)
            return frac
        } else if command == "dfrac" {
            // Display-style fraction command has 2 arguments
            let frac = Fraction()
            let numerator = buildInternal(true)
            let denominator = buildInternal(true)

            // Prepend \displaystyle to force display mode rendering
            let displayStyle = MathStyle(style: .display)
            numerator?.insert(displayStyle, at: 0)
            denominator?.insert(displayStyle, at: 0)

            frac.numerator = numerator
            frac.denominator = denominator
            return frac
        } else if command == "tfrac" {
            // Text-style fraction command has 2 arguments
            let frac = Fraction()
            let numerator = buildInternal(true)
            let denominator = buildInternal(true)

            // Prepend \textstyle to force text mode rendering
            let textStyle = MathStyle(style: .text)
            numerator?.insert(textStyle, at: 0)
            denominator?.insert(textStyle, at: 0)

            frac.numerator = numerator
            frac.denominator = denominator
            return frac
        } else if command == "binom" {
            // A binom command has 2 arguments
            let frac = Fraction(hasRule: false)
            frac.numerator = buildInternal(true)
            frac.denominator = buildInternal(true)
            frac.leftDelimiter = "("
            frac.rightDelimiter = ")"
            return frac
        } else if command == "bra" {
            // Dirac bra notation: \bra{psi} -> ⟨psi|
            let inner = Inner()
            inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: "langle")
            inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: "|")
            inner.innerList = buildInternal(true)
            return inner
        } else if command == "ket" {
            // Dirac ket notation: \ket{psi} -> |psi⟩
            let inner = Inner()
            inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: "|")
            inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: "rangle")
            inner.innerList = buildInternal(true)
            return inner
        } else if command == "braket" {
            // Dirac braket notation: \braket{phi}{psi} -> ⟨phi|psi⟩
            let inner = Inner()
            inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: "langle")
            inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: "rangle")
            // Build the inner content: phi | psi
            let phi = buildInternal(true)
            let psi = buildInternal(true)
            let content = MathList()
            if let phiList = phi {
                for atom in phiList.atoms {
                    content.add(atom)
                }
            }
            // Add the | separator
            content.add(MathAtom(type: .ordinary, value: "|"))
            if let psiList = psi {
                for atom in psiList.atoms {
                    content.add(atom)
                }
            }
            inner.innerList = content
            return inner
        } else if command == "operatorname" || command == "operatorname*" {
            // \operatorname{name} creates a custom operator with proper spacing
            // \operatorname*{name} creates an operator with limits above/below
            let hasLimits = command.hasSuffix("*")

            // Parse the operator name
            let content = buildInternal(true)

            // Convert the parsed content to a string
            var operatorName = ""
            if let atoms = content?.atoms {
                for atom in atoms {
                    operatorName += atom.nucleus
                }
            }

            if operatorName.isEmpty {
                let errorMessage = "Missing operator name for \\operatorname"
                setError(.invalidCommand(errorMessage))
                return nil
            }

            return LargeOperator(value: operatorName, hasLimits: hasLimits)
        } else if command == "sqrt" {
            // A sqrt command with one argument
            let rad = Radical()
            guard hasCharacters else {
                rad.radicand = buildInternal(true)
                return rad
            }
            let ch = nextCharacter()
            if ch == "[" {
                // special handling for sqrt[degree]{radicand}
                rad.degree = buildInternal(false, stopChar: "]")
                rad.radicand = buildInternal(true)
            } else {
                unlookCharacter()
                rad.radicand = buildInternal(true)
            }
            return rad
        } else if command == "left" {
            // Save the current inner while a new one gets built.
            let oldInner = currentInnerAtom
            currentInnerAtom = Inner()
            currentInnerAtom!.leftBoundary = boundaryAtom(for: "left")
            if currentInnerAtom!.leftBoundary == nil {
                return nil
            }
            currentInnerAtom!.innerList = buildInternal(false)
            if currentInnerAtom!.rightBoundary == nil {
                // A right node would have set the right boundary so we must be missing the right node.
                let errorMessage = "Missing \\right"
                setError(.missingRight(errorMessage))
                return nil
            }
            // reinstate the old inner atom.
            let newInner = currentInnerAtom
            currentInnerAtom = oldInner
            return newInner
        } else if command == "overline" {
            // The overline command has 1 arguments
            let over = OverLine()
            over.innerList = buildInternal(true)
            return over
        } else if command == "underline" {
            // The underline command has 1 arguments
            let under = UnderLine()
            under.innerList = buildInternal(true)
            return under
        } else if command == "substack" {
            // \substack reads ONE braced argument containing rows separated by \\
            // Similar to how \frac reads {numerator}{denominator}

            // Read the braced content using standard pattern
            let content = buildInternal(true)

            if content == nil {
                return nil
            }

            // The content may already be a table if \\ was encountered
            // Check if we got a table from the \\ parsing
            if content!.atoms.count == 1, let tableAtom = content!.atoms.first as? MathTable {
                return tableAtom
            }

            // Otherwise, single row - wrap in table
            var rows = [[MathList]]()
            rows.append([content!])

            do {
                return try MathAtomFactory.table(withEnvironment: nil, rows: rows)
            } catch {
                if self.error == nil {
                    self.error = error
                }
                return nil
            }
        } else if command == "begin" {
            let env = readEnvironment()
            if env == nil {
                return nil
            }
            return buildTable(env: env, firstList: nil, isRow: false)
        } else if command == "color" {
            // A color command has 2 arguments
            let mathColor = MathColorAtom()
            let color = readColor()
            if color == nil {
                return nil
            }
            mathColor.colorString = color!
            mathColor.innerList = buildInternal(true)
            return mathColor
        } else if command == "textcolor" {
            // A textcolor command has 2 arguments
            let mathColor = MathTextColor()
            let color = readColor()
            if color == nil {
                return nil
            }
            mathColor.colorString = color!
            mathColor.innerList = buildInternal(true)
            return mathColor
        } else if command == "colorbox" {
            // A color command has 2 arguments
            let mathColorbox = MathColorBox()
            let color = readColor()
            if color == nil {
                return nil
            }
            mathColorbox.colorString = color!
            mathColorbox.innerList = buildInternal(true)
            return mathColorbox
        } else if command == "pmod" {
            // A pmod command has 1 argument - creates (mod n)
            let inner = Inner()
            inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: "(")
            inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: ")")

            let innerList = MathList()

            // Add the "mod" operator (upright text)
            let modOperator = MathAtomFactory.atom(forLatexSymbol: "mod")!
            innerList.add(modOperator)

            // Add medium space between "mod" and argument (6mu)
            let space = MathSpace(space: 6.0)
            innerList.add(space)

            // Parse the argument from braces
            let argument = buildInternal(true)
            if let argList = argument {
                innerList.append(argList)
            }

            inner.innerList = innerList
            return inner
        } else if command == "not" {
            // Handle \not command with lookahead for comprehensive negation support
            let nextCommand = peekNextCommand()

            if let negatedUnicode = Self.notCombinations[nextCommand] {
                consumeNextCommand() // Remove base symbol from stream
                return MathAtom(type: .relation, value: negatedUnicode)
            } else {
                let errorMessage = "Unsupported \\not\\\(nextCommand) combination"
                setError(.invalidCommand(errorMessage))
                return nil
            }
        } else if let sizeMultiplier = Self.delimiterSizeCommands[command] {
            // Handle \big, \Big, \bigg, \Bigg and their variants
            let delim = readDelimiter()
            if delim == nil {
                let errorMessage = "Missing delimiter for \\\(command)"
                setError(.missingDelimiter(errorMessage))
                return nil
            }
            let boundary = MathAtomFactory.boundary(forDelimiter: delim!)
            if boundary == nil {
                let errorMessage = "Invalid delimiter for \\\(command): \(delim!)"
                setError(.invalidDelimiter(errorMessage))
                return nil
            }

            // Create Inner with explicit delimiter height
            let inner = Inner()

            // Determine if this is a left, right, or middle delimiter based on command suffix
            let isLeft = command.hasSuffix("l")
            let isRight = command.hasSuffix("r")
            // let isMiddle = command.hasSuffix("m")  // For future use

            if isLeft {
                inner.leftBoundary = boundary
                inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: ".")
            } else if isRight {
                inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: ".")
                inner.rightBoundary = boundary
            } else {
                // For \big, \Big, \bigg, \Bigg and \bigm variants, use the delimiter on both sides
                // but with empty inner content - it's just a sized delimiter
                inner.leftBoundary = boundary
                inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: ".")
            }

            inner.innerList = MathList()
            inner
                .delimiterHeight =
                sizeMultiplier // Store multiplier, typesetter will compute actual height

            return inner
        } else {
            let errorMessage = "Invalid command \\\(command)"
            setError(.invalidCommand(errorMessage))
            return nil
        }
    }

    mutating func readColor() -> String? {
        if !expectCharacter("{") {
            // We didn't find an opening brace, so no env found.
            setError(.characterNotFound("Missing {"))
            return nil
        }

        // Ignore spaces and nonascii.
        skipSpaces()

        // a string of all upper and lower case characters.
        var mutable = ""
        while hasCharacters {
            let ch = nextCharacter()
            if ch == "#" || (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z")
                || (ch >= "0" && ch <= "9")
            {
                mutable.append(ch) // appendString:[NSString stringWithCharacters:&ch length:1]];
            } else {
                // we went too far
                unlookCharacter()
                break
            }
        }

        if !expectCharacter("}") {
            // We didn't find an closing brace, so invalid format.
            setError(.characterNotFound("Missing }"))
            return nil
        }
        return mutable
    }

    mutating func skipSpaces() {
        while hasCharacters {
            let ch = nextCharacter().utf32Char
            if ch < 0x21 || ch > 0x7E {
                // skip non ascii characters and spaces
                continue
            } else {
                unlookCharacter()
                return
            }
        }
    }

    static var fractionCommands: [String: [Character]] {
        [
            "over": [],
            "atop": [],
            "choose": ["(", ")"],
            "brack": ["[", "]"],
            "brace": ["{", "}"],
        ]
    }

    mutating func stopCommand(
        _ command: String,
        list: MathList,
        stopChar: Character?,
    ) -> MathList? {
        if command == "right" {
            if currentInnerAtom == nil {
                let errorMessage = "Missing \\left"
                setError(.missingLeft(errorMessage))
                return nil
            }
            currentInnerAtom!.rightBoundary = boundaryAtom(for: "right")
            if currentInnerAtom!.rightBoundary == nil {
                return nil
            }
            // return the list read so far.
            return list
        } else if let delims = Self.fractionCommands[command] {
            var frac: Fraction! = nil
            if command == "over" {
                frac = Fraction()
            } else {
                frac = Fraction(hasRule: false)
            }
            if delims.count == 2 {
                frac.leftDelimiter = String(delims[0])
                frac.rightDelimiter = String(delims[1])
            }
            frac.numerator = list
            frac.denominator = buildInternal(false, stopChar: stopChar)
            if error != nil {
                return nil
            }
            let fracList = MathList()
            fracList.add(frac)
            return fracList
        } else if command == "\\" || command == "cr" {
            if currentEnv != nil {
                // Stop the current list and increment the row count
                currentEnv!.numRows += 1
                return list
            } else {
                // Create a new table with the current list and a default env
                if let table = buildTable(env: nil, firstList: list, isRow: true) {
                    return MathList(atom: table)
                }
            }
        } else if command == "end" {
            if currentEnv == nil {
                let errorMessage = "Missing \\begin"
                setError(.missingBegin(errorMessage))
                return nil
            }
            let env = readEnvironment()
            if env == nil {
                return nil
            }
            if env! != currentEnv!.envName {
                let errorMessage =
                    "Begin environment name \(currentEnv!.envName ?? "(none)") does not match end name: \(env!)"
                setError(.invalidEnv(errorMessage))
                return nil
            }
            // Finish the current environment.
            currentEnv!.ended = true
            return list
        }
        return nil
    }

    // Applies the modifier to the atom. Returns true if modifier applied.
    mutating func applyModifier(_ modifier: String, atom: MathAtom?) -> Bool {
        if modifier == "limits" {
            if let op = atom as? LargeOperator {
                op.hasLimits = true
            } else {
                setError(.invalidLimits("Limits can only be applied to an operator."))
            }
            return true
        } else if modifier == "nolimits" {
            if let op = atom as? LargeOperator {
                op.hasLimits = false
            } else {
                setError(.invalidLimits("No limits can only be applied to an operator."))
            }
            return true
        }
        return false
    }

    mutating func setError(_ newError: ParseError) {
        // Only record the first error.
        if error == nil {
            error = newError
        }
    }

    mutating func atom(forCommand command: String) -> MathAtom? {
        if let atom = MathAtomFactory.atom(forLatexSymbol: command) {
            return atom
        }
        if let accent = MathAtomFactory.accent(named: command) {
            accent.innerList = buildInternal(true)
            return accent
        } else if command == "frac" {
            let frac = Fraction()
            frac.numerator = buildInternal(true)
            frac.denominator = buildInternal(true)
            return frac
        } else if command == "cfrac" {
            let frac = Fraction()
            frac.isContinuedFraction = true

            // Parse optional alignment parameter [l], [r], [c]
            skipSpaces()
            if hasCharacters, string[currentCharIndex] == "[" {
                _ = nextCharacter() // consume '['
                if hasCharacters {
                    let alignmentChar = nextCharacter()
                    if alignmentChar == "l" || alignmentChar == "r" || alignmentChar == "c" {
                        frac.alignment = String(alignmentChar)
                    }
                }
                // Consume closing ']'
                if hasCharacters, string[currentCharIndex] == "]" {
                    _ = nextCharacter()
                }
            }

            frac.numerator = buildInternal(true)
            frac.denominator = buildInternal(true)
            return frac
        } else if command == "dfrac" {
            // Display-style fraction command has 2 arguments
            let frac = Fraction()
            let numerator = buildInternal(true)
            let denominator = buildInternal(true)

            // Prepend \displaystyle to force display mode rendering
            let displayStyle = MathStyle(style: .display)
            numerator?.insert(displayStyle, at: 0)
            denominator?.insert(displayStyle, at: 0)

            frac.numerator = numerator
            frac.denominator = denominator
            return frac
        } else if command == "tfrac" {
            // Text-style fraction command has 2 arguments
            let frac = Fraction()
            let numerator = buildInternal(true)
            let denominator = buildInternal(true)

            // Prepend \textstyle to force text mode rendering
            let textStyle = MathStyle(style: .text)
            numerator?.insert(textStyle, at: 0)
            denominator?.insert(textStyle, at: 0)

            frac.numerator = numerator
            frac.denominator = denominator
            return frac
        } else if command == "binom" {
            let frac = Fraction(hasRule: false)
            frac.numerator = buildInternal(true)
            frac.denominator = buildInternal(true)
            frac.leftDelimiter = "("
            frac.rightDelimiter = ")"
            return frac
        } else if command == "bra" {
            // Dirac bra notation: \bra{psi} -> ⟨psi|
            let inner = Inner()
            inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: "langle")
            inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: "|")
            inner.innerList = buildInternal(true)
            return inner
        } else if command == "ket" {
            // Dirac ket notation: \ket{psi} -> |psi⟩
            let inner = Inner()
            inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: "|")
            inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: "rangle")
            inner.innerList = buildInternal(true)
            return inner
        } else if command == "braket" {
            // Dirac braket notation: \braket{phi}{psi} -> ⟨phi|psi⟩
            let inner = Inner()
            inner.leftBoundary = MathAtomFactory.boundary(forDelimiter: "langle")
            inner.rightBoundary = MathAtomFactory.boundary(forDelimiter: "rangle")
            let phi = buildInternal(true)
            let psi = buildInternal(true)
            let content = MathList()
            if let phiList = phi {
                for atom in phiList.atoms {
                    content.add(atom)
                }
            }
            content.add(MathAtom(type: .ordinary, value: "|"))
            if let psiList = psi {
                for atom in psiList.atoms {
                    content.add(atom)
                }
            }
            inner.innerList = content
            return inner
        } else if command == "operatorname" || command == "operatorname*" {
            // \operatorname{name} creates a custom operator with proper spacing
            // \operatorname*{name} creates an operator with limits above/below
            let hasLimits = command.hasSuffix("*")

            let content = buildInternal(true)
            var operatorName = ""
            if let atoms = content?.atoms {
                for atom in atoms {
                    operatorName += atom.nucleus
                }
            }
            if operatorName.isEmpty {
                setError(.invalidCommand("Missing operator name for \\operatorname"))
                return nil
            }
            return LargeOperator(value: operatorName, hasLimits: hasLimits)
        } else if command == "sqrt" {
            let rad = Radical()
            guard hasCharacters else {
                rad.radicand = buildInternal(true)
                return rad
            }
            let char = nextCharacter()
            if char == "[" {
                rad.degree = buildInternal(false, stopChar: "]")
                rad.radicand = buildInternal(true)
            } else {
                unlookCharacter()
                rad.radicand = buildInternal(true)
            }
            return rad
        } else if command == "left" {
            let oldInner = currentInnerAtom
            currentInnerAtom = Inner()
            currentInnerAtom?.leftBoundary = boundaryAtom(for: "left")
            if currentInnerAtom?.leftBoundary == nil {
                return nil
            }
            currentInnerAtom!.innerList = buildInternal(false)
            if currentInnerAtom?.rightBoundary == nil {
                setError(.missingRight("Missing \\right"))
                return nil
            }
            let newInner = currentInnerAtom
            currentInnerAtom = oldInner
            return newInner
        } else if command == "overline" {
            let over = OverLine()
            over.innerList = buildInternal(true)

            return over
        } else if command == "underline" {
            let under = UnderLine()
            under.innerList = buildInternal(true)

            return under
        } else if command == "begin" {
            if let env = readEnvironment() {
                // Check if this is a starred matrix environment and read optional alignment
                var alignment: ColumnAlignment?
                if env.hasSuffix("*") {
                    alignment = readOptionalAlignment()
                    if self.error != nil {
                        return nil
                    }
                }

                return buildTable(env: env, alignment: alignment, firstList: nil, isRow: false)
            } else {
                return nil
            }
        } else if command == "color" {
            // A color command has 2 arguments
            let mathColor = MathColorAtom()
            mathColor.colorString = readColor()!
            mathColor.innerList = buildInternal(true)
            return mathColor
        } else if command == "colorbox" {
            // A color command has 2 arguments
            let mathColorbox = MathColorBox()
            mathColorbox.colorString = readColor()!
            mathColorbox.innerList = buildInternal(true)
            return mathColorbox
        } else {
            setError(.invalidCommand("Invalid command \\\(command)"))
            return nil
        }
    }

    mutating func readEnvironment() -> String? {
        if !expectCharacter("{") {
            // We didn't find an opening brace, so no env found.
            setError(.characterNotFound("Missing {"))
            return nil
        }

        skipSpaces()
        let env = readString()

        if !expectCharacter("}") {
            // We didn"t find an closing brace, so invalid format.
            setError(.characterNotFound("Missing }"))
            return nil
        }
        return env
    }

    /// Reads optional alignment parameter for starred matrix environments: [r], [l], or [c]
    mutating func readOptionalAlignment() -> ColumnAlignment? {
        skipSpaces()

        // Check if there's an opening bracket
        guard hasCharacters, string[currentCharIndex] == "[" else {
            return nil
        }

        _ = nextCharacter() // consume '['
        skipSpaces()

        guard hasCharacters else {
            setError(.characterNotFound("Missing alignment specifier after ["))
            return nil
        }

        let alignChar = nextCharacter()
        let alignment: ColumnAlignment?

        switch alignChar {
            case "l":
                alignment = .left
            case "c":
                alignment = .center
            case "r":
                alignment = .right
            default:
                setError(
                    .invalidEnv("Invalid alignment specifier: \(alignChar). Must be l, c, or r"),
                )
                return nil
        }

        skipSpaces()

        if !expectCharacter("]") {
            setError(.characterNotFound("Missing ] after alignment specifier"))
            return nil
        }

        return alignment
    }

    func assertNotSpace(_ ch: Character) {
        assert(ch >= "\u{21}" && ch <= "\u{7E}", "Expected non-space character \(ch)")
    }

    mutating func buildTable(
        env: String?, alignment: ColumnAlignment? = nil, firstList: MathList?, isRow: Bool,
    ) -> MathAtom? {
        // Save the current env till an new one gets built.
        let oldEnv = currentEnv

        currentEnv = EnvProperties(name: env, alignment: alignment)

        var currentRow = 0
        var currentCol = 0

        var rows = [[MathList]]()
        rows.append([MathList]())
        if firstList != nil {
            rows[currentRow].append(firstList!)
            if isRow {
                currentEnv!.numRows += 1
                currentRow += 1
                rows.append([MathList]())
            } else {
                currentCol += 1
            }
        }
        while !currentEnv!.ended, hasCharacters {
            let list = buildInternal(false)
            if list == nil {
                // If there is an error building the list, bail out early.
                return nil
            }
            rows[currentRow].append(list!)
            currentCol += 1
            if currentEnv!.numRows > currentRow {
                currentRow = currentEnv!.numRows
                rows.append([MathList]())
                currentCol = 0
            }
        }

        if !currentEnv!.ended, currentEnv!.envName != nil {
            setError(.missingEnd("Missing \\end"))
            return nil
        }

        do {
            let table = try MathAtomFactory.table(
                withEnvironment: currentEnv?.envName, alignment: currentEnv?.alignment, rows: rows,
            )
            currentEnv = oldEnv
            return table
        } catch {
            if self.error == nil {
                self.error = error
            }
            return nil
        }
    }

    mutating func boundaryAtom(for delimiterType: String) -> MathAtom? {
        let delim = readDelimiter()
        if delim == nil {
            let errorMessage = "Missing delimiter for \\\(delimiterType)"
            setError(.missingDelimiter(errorMessage))
            return nil
        }
        let boundary = MathAtomFactory.boundary(forDelimiter: delim!)
        if boundary == nil {
            let errorMessage = "Invalid delimiter for \(delimiterType): \(delim!)"
            setError(.invalidDelimiter(errorMessage))
            return nil
        }
        return boundary
    }

    mutating func readDelimiter() -> String? {
        skipSpaces()
        while hasCharacters {
            let char = nextCharacter()
            assertNotSpace(char)
            if char == "\\" {
                let command = readCommand()
                if command == "|" {
                    return "||"
                }
                return command
            } else {
                return String(char)
            }
        }
        return nil
    }

    mutating func readCommand() -> String {
        let singleChars = "{}$#%_| ,>;!\\"
        if hasCharacters {
            let char = nextCharacter()
            if singleChars.contains(char) {
                return String(char)
            } else {
                unlookCharacter()
            }
        }
        return readString()
    }

    mutating func readString() -> String {
        // a string of all upper and lower case characters (and asterisks for starred environments)
        var output = ""
        while hasCharacters {
            let char = nextCharacter()
            if char.isLowercase || char.isUppercase || char == "*" {
                output.append(char)
            } else {
                unlookCharacter()
                break
            }
        }
        return output
    }
}
