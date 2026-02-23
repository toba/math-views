public import Foundation

/// Parses LaTeX math strings into a ``MathList`` (abstract syntax tree).
///
/// See <doc:RenderingPipeline> for how parsing fits into the rendering pipeline.
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
        let character = string[currentCharIndex]
        currentCharIndex = string.index(after: currentCharIndex)
        return character
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

        let character = nextCharacter()
        let command: String

        if character == "\\" {
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

        let character = nextCharacter()
        if character == "\\" {
            _ = readCommand()
        }
    }

    mutating func expectCharacter(_ character: Character) -> Bool {
        assertNotSpace(character)
        skipSpaces()

        if hasCharacters {
            let expectedCharacter = nextCharacter()
            assertNotSpace(expectedCharacter)
            if expectedCharacter == character {
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
        -4: "negmedspace",
        -5: "negthickspace",
        9: "enspace",
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
    func detectAndStripDelimiters(from input: String) -> (String, MathMode) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

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
            return (input, .display)
        }

        // No delimiters found - default to display mode (current behavior for backward compatibility)
        return (input, .display)
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
                                       stopChar stopCharacter: Character?) -> MathList?
    {
        let list = MathList()
        assert(!(oneCharOnly && stopCharacter != nil), "Cannot set both oneCharOnly and stopChar.")
        var prevAtom: MathAtom?
        while hasCharacters {
            if error != nil { return nil } // If there is an error thus far then bail out.

            var atom: MathAtom?
            let character = nextCharacter()

            if oneCharOnly {
                if character == "^" || character == "}" || character == "_" || character == "&" {
                    // this is not the character we are looking for.
                    // They are meant for the caller to look at.
                    unlookCharacter()
                    return list
                }
            }
            // If there is a stop character, keep scanning 'til we find it
            if stopCharacter != nil, character == stopCharacter! {
                return list
            }

            if character == "^" {
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
            } else if character == "_" {
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
            } else if character == "{" {
                // this puts us in a recursive routine, and sets oneCharOnly to false and no stop character
                if let subList = buildInternal(false, stopChar: "}") {
                    prevAtom = subList.atoms.last
                    list.append(subList)
                    if oneCharOnly {
                        return list
                    }
                }
                continue
            } else if character == "}" {
                // \ means a command
                assert(!oneCharOnly, "This should have been handled before")
                assert(stopCharacter == nil, "This should have been handled before")
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
            } else if character == "\\" {
                let command = readCommand()
                let done = stopCommand(command, list: list, stopChar: stopCharacter)
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
            } else if character == "&" {
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
            } else if spacesAllowed, character == " " {
                // If spaces are allowed then spaces do not need escaping with a \ before being used.
                atom = MathAtomFactory.atom(forLatexSymbol: " ")
            } else {
                atom = MathAtomFactory.atom(forCharacter: character)
                if atom == nil {
                    // Not a recognized character in standard math mode
                    // In text mode (spacesAllowed && roman style), accept any Unicode character for fallback font support
                    // This enables Chinese, Japanese, Korean, emoji, etc. in \text{} commands
                    if spacesAllowed, currentFontStyle == .roman {
                        atom = MathAtom(type: .ordinary, value: String(character))
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
        if stopCharacter != nil {
            if stopCharacter == "}" {
                // We did not find a corresponding closing brace.
                setError(.mismatchBraces("Missing closing brace"))
            } else {
                // we never found our stop character
                let errorMessage = "Expected character not found: \(stopCharacter!)"
                setError(.characterNotFound(errorMessage))
            }
        }
        return list
    }
}
