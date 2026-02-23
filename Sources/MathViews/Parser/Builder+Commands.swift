import Foundation

// MARK: - Command handling and LaTeX serialization

extension MathListBuilder {
    // MARK: - MathList to LaTeX conversion

    /// Converts a ``MathList`` back into a LaTeX string, the inverse of ``buildChecked(fromString:)``.
    public static func mathListToString(_ mathList: MathList?) -> String {
        var result = ""
        var currentfontStyle = FontStyle.defaultStyle
        if let atomList = mathList {
            for atom in atomList.atoms {
                if currentfontStyle != atom.fontStyle {
                    if currentfontStyle != .defaultStyle {
                        result += "}"
                    }
                    if atom.fontStyle != .defaultStyle {
                        let fontStyleName = MathAtomFactory.fontNameForStyle(atom.fontStyle)
                        result += "\\\(fontStyleName){"
                    }
                    currentfontStyle = atom.fontStyle
                }
                if atom.type == .fraction {
                    if let fraction = atom as? Fraction {
                        if fraction.isContinuedFraction {
                            // Generate \cfrac with optional alignment
                            if fraction.alignment != "c" {
                                result +=
                                    "\\cfrac[\(fraction.alignment)]{\(mathListToString(fraction.numerator!))}{\(mathListToString(fraction.denominator!))}"
                            } else {
                                result +=
                                    "\\cfrac{\(mathListToString(fraction.numerator!))}{\(mathListToString(fraction.denominator!))}"
                            }
                        } else if fraction.hasRule {
                            result +=
                                "\\frac{\(mathListToString(fraction.numerator!))}{\(mathListToString(fraction.denominator!))}"
                        } else {
                            let command: String
                            if fraction.leftDelimiter.isEmpty, fraction.rightDelimiter.isEmpty {
                                command = "atop"
                            } else if fraction.leftDelimiter == "(",
                                      fraction.rightDelimiter == ")"
                            {
                                command = "choose"
                            } else if fraction.leftDelimiter == "{",
                                      fraction.rightDelimiter == "}"
                            {
                                command = "brace"
                            } else if fraction.leftDelimiter == "[",
                                      fraction.rightDelimiter == "]"
                            {
                                command = "brack"
                            } else {
                                command = "atopwithdelims\(fraction.leftDelimiter)\(fraction.rightDelimiter)"
                            }
                            result +=
                                "{\(mathListToString(fraction.numerator!)) \\\(command) \(mathListToString(fraction.denominator!))}"
                        }
                    }
                } else if atom.type == .radical {
                    result += "\\sqrt"
                    if let radical = atom as? Radical {
                        if radical.degree != nil {
                            result += "[\(mathListToString(radical.degree!))]"
                        }
                        result += "{\(mathListToString(radical.radicand!))}"
                    }
                } else if atom.type == .inner {
                    if let innerAtom = atom as? Inner {
                        if innerAtom.leftBoundary != nil || innerAtom.rightBoundary != nil {
                            if innerAtom.leftBoundary != nil {
                                result += "\\left\(delimiterString(innerAtom.leftBoundary!)) "
                            } else {
                                result += "\\left. "
                            }

                            result += mathListToString(innerAtom.innerList!)

                            if innerAtom.rightBoundary != nil {
                                result += "\\right\(delimiterString(innerAtom.rightBoundary!)) "
                            } else {
                                result += "\\right. "
                            }
                        } else {
                            result += "{\(mathListToString(innerAtom.innerList!))}"
                        }
                    }
                } else if atom.type == .table {
                    if let table = atom as? MathTable {
                        if !table.environment.isEmpty {
                            result += "\\begin{\(table.environment)}"
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
                                result += mathListToString(cell)
                                if j < row.count - 1 {
                                    result += "&"
                                }
                            }
                            if i < table.numRows - 1 {
                                result += "\\\\ "
                            }
                        }
                        if !table.environment.isEmpty {
                            result += "\\end{\(table.environment)}"
                        }
                    }
                } else if atom.type == .overline {
                    if let overline = atom as? Overline {
                        result += "\\overline"
                        result += "{\(mathListToString(overline.innerList!))}"
                    }
                } else if atom.type == .underline {
                    if let underline = atom as? Underline {
                        result += "\\underline"
                        result += "{\(mathListToString(underline.innerList!))}"
                    }
                } else if atom.type == .overbrace {
                    if let ob = atom as? OverBrace {
                        result += "\\overbrace"
                        result += "{\(mathListToString(ob.innerList!))}"
                    }
                } else if atom.type == .underbrace {
                    if let ub = atom as? UnderBrace {
                        result += "\\underbrace"
                        result += "{\(mathListToString(ub.innerList!))}"
                    }
                } else if atom.type == .accent {
                    if let accent = atom as? Accent {
                        result +=
                            "\\\(MathAtomFactory.accentName(accent)!){\(mathListToString(accent.innerList!))}"
                    }
                } else if atom.type == .largeOperator {
                    if let largeOperator = atom as? LargeOperator,
                       let command = MathAtomFactory.latexSymbolName(for: atom),
                       let originalOp =
                       MathAtomFactory
                           .atom(forLatexSymbol: command) as? LargeOperator
                    {
                        result += "\\\(command) "
                        if originalOp.hasLimits != largeOperator.hasLimits {
                            if largeOperator.hasLimits {
                                result += "\\limits "
                            } else {
                                result += "\\nolimits "
                            }
                        }
                    }
                } else if atom.type == .space {
                    if let space = atom as? MathSpace {
                        if let command = Self.spaceToCommands[space.space] {
                            result += "\\\(command) "
                        } else {
                            result += String(format: "\\mkern%.1fmu", space.space)
                        }
                    }
                } else if atom.type == .style {
                    if let style = atom as? MathStyle {
                        if let command = Self.styleToCommands[style.style] {
                            result += "\\\(command) "
                        }
                    }
                } else if atom.nucleus.isEmpty {
                    result += "{}"
                } else if atom.nucleus == "\u{2236}" {
                    // math colon
                    result += ":"
                } else if atom.nucleus == "\u{2212}" {
                    // math minus
                    result += "-"
                } else {
                    if let command = MathAtomFactory.latexSymbolName(for: atom) {
                        result += "\\\(command) "
                    } else {
                        result += "\(atom.nucleus)"
                    }
                }

                if atom.superScript != nil {
                    result += "^{\(mathListToString(atom.superScript!))}"
                }

                if atom.subScript != nil {
                    result += "_{\(mathListToString(atom.subScript!))}"
                }
            }
        }
        if currentfontStyle != .defaultStyle {
            result += "}"
        }
        return result
    }

    public static func delimiterString(_ delimiter: MathAtom) -> String {
        if let command = MathAtomFactory.delimiterName(of: delimiter) {
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
            let fraction = Fraction()
            fraction.numerator = buildInternal(true)
            fraction.denominator = buildInternal(true)
            return fraction
        } else if command == "cfrac" {
            // A continued fraction command with optional alignment and 2 arguments
            let fraction = Fraction()
            fraction.isContinuedFraction = true

            // Parse optional alignment parameter [l], [r], [c]
            skipSpaces()
            if hasCharacters, string[currentCharIndex] == "[" {
                _ = nextCharacter() // consume '['
                if hasCharacters {
                    let alignmentChar = nextCharacter()
                    if alignmentChar == "l" || alignmentChar == "r" || alignmentChar == "c" {
                        fraction.alignment = String(alignmentChar)
                    }
                }
                // Consume closing ']'
                if hasCharacters, string[currentCharIndex] == "]" {
                    _ = nextCharacter()
                }
            }

            fraction.numerator = buildInternal(true)
            fraction.denominator = buildInternal(true)
            return fraction
        } else if command == "dfrac" {
            // Display-style fraction command has 2 arguments
            let fraction = Fraction()
            let numerator = buildInternal(true)
            let denominator = buildInternal(true)

            // Prepend \displaystyle to force display mode rendering
            let displayStyle = MathStyle(style: .display)
            numerator?.insert(displayStyle, at: 0)
            denominator?.insert(displayStyle, at: 0)

            fraction.numerator = numerator
            fraction.denominator = denominator
            return fraction
        } else if command == "tfrac" {
            // Text-style fraction command has 2 arguments
            let fraction = Fraction()
            let numerator = buildInternal(true)
            let denominator = buildInternal(true)

            // Prepend \textstyle to force text mode rendering
            let textStyle = MathStyle(style: .text)
            numerator?.insert(textStyle, at: 0)
            denominator?.insert(textStyle, at: 0)

            fraction.numerator = numerator
            fraction.denominator = denominator
            return fraction
        } else if command == "binom" {
            // A binom command has 2 arguments
            let fraction = Fraction(hasRule: false)
            fraction.numerator = buildInternal(true)
            fraction.denominator = buildInternal(true)
            fraction.leftDelimiter = "("
            fraction.rightDelimiter = ")"
            return fraction
        } else if command == "bra" {
            // Dirac bra notation: \bra{psi} -> ⟨psi|
            let innerAtom = Inner()
            innerAtom.leftBoundary = MathAtomFactory.boundary(forDelimiter: "langle")
            innerAtom.rightBoundary = MathAtomFactory.boundary(forDelimiter: "|")
            innerAtom.innerList = buildInternal(true)
            return innerAtom
        } else if command == "ket" {
            // Dirac ket notation: \ket{psi} -> |psi⟩
            let innerAtom = Inner()
            innerAtom.leftBoundary = MathAtomFactory.boundary(forDelimiter: "|")
            innerAtom.rightBoundary = MathAtomFactory.boundary(forDelimiter: "rangle")
            innerAtom.innerList = buildInternal(true)
            return innerAtom
        } else if command == "braket" {
            // Dirac braket notation: \braket{phi}{psi} -> ⟨phi|psi⟩
            let innerAtom = Inner()
            innerAtom.leftBoundary = MathAtomFactory.boundary(forDelimiter: "langle")
            innerAtom.rightBoundary = MathAtomFactory.boundary(forDelimiter: "rangle")
            // Build the inner content: firstArgument | secondArgument
            let firstArgument = buildInternal(true)
            let secondArgument = buildInternal(true)
            let content = MathList()
            if let firstList = firstArgument {
                for atom in firstList.atoms {
                    content.add(atom)
                }
            }
            // Add the | separator
            content.add(MathAtom(type: .ordinary, value: "|"))
            if let secondList = secondArgument {
                for atom in secondList.atoms {
                    content.add(atom)
                }
            }
            innerAtom.innerList = content
            return innerAtom
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
            let radical = Radical()
            guard hasCharacters else {
                radical.radicand = buildInternal(true)
                return radical
            }
            let character = nextCharacter()
            if character == "[" {
                // special handling for sqrt[degree]{radicand}
                radical.degree = buildInternal(false, stopChar: "]")
                radical.radicand = buildInternal(true)
            } else {
                unlookCharacter()
                radical.radicand = buildInternal(true)
            }
            return radical
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
            let overlineAtom = Overline()
            overlineAtom.innerList = buildInternal(true)
            return overlineAtom
        } else if command == "underline" {
            // The underline command has 1 arguments
            let underlineAtom = Underline()
            underlineAtom.innerList = buildInternal(true)
            return underlineAtom
        } else if command == "overbrace" {
            let atom = OverBrace()
            atom.innerList = buildInternal(true)
            return atom
        } else if command == "underbrace" {
            let atom = UnderBrace()
            atom.innerList = buildInternal(true)
            return atom
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
            let environment = readEnvironment()
            if environment == nil {
                return nil
            }
            return buildTable(env: environment, firstList: nil, isRow: false)
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
            let innerAtom = Inner()
            innerAtom.leftBoundary = MathAtomFactory.boundary(forDelimiter: "(")
            innerAtom.rightBoundary = MathAtomFactory.boundary(forDelimiter: ")")

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

            innerAtom.innerList = innerList
            return innerAtom
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
            let delimiter = readDelimiter()
            if delimiter == nil {
                let errorMessage = "Missing delimiter for \\\(command)"
                setError(.missingDelimiter(errorMessage))
                return nil
            }
            let boundary = MathAtomFactory.boundary(forDelimiter: delimiter!)
            if boundary == nil {
                let errorMessage = "Invalid delimiter for \\\(command): \(delimiter!)"
                setError(.invalidDelimiter(errorMessage))
                return nil
            }

            // Create Inner with explicit delimiter height
            let innerAtom = Inner()

            // Determine if this is a left, right, or middle delimiter based on command suffix
            let isLeft = command.hasSuffix("l")
            let isRight = command.hasSuffix("r")
            // let isMiddle = command.hasSuffix("m")  // For future use

            if isLeft {
                innerAtom.leftBoundary = boundary
                innerAtom.rightBoundary = MathAtomFactory.boundary(forDelimiter: ".")
            } else if isRight {
                innerAtom.leftBoundary = MathAtomFactory.boundary(forDelimiter: ".")
                innerAtom.rightBoundary = boundary
            } else {
                // For \big, \Big, \bigg, \Bigg and \bigm variants, use the delimiter on both sides
                // but with empty inner content - it's just a sized delimiter
                innerAtom.leftBoundary = boundary
                innerAtom.rightBoundary = MathAtomFactory.boundary(forDelimiter: ".")
            }

            innerAtom.innerList = MathList()
            innerAtom
                .delimiterHeight =
                sizeMultiplier // Store multiplier, typesetter will compute actual height

            return innerAtom
        } else if command == "mkern" {
            // \mkern<dimen>mu — parse a numeric kern value with mu unit
            let value = readMuDimension()
            if let value {
                return MathSpace(space: value)
            } else {
                setError(.invalidCommand("Invalid \\mkern dimension"))
                return nil
            }
        } else {
            let errorMessage = "Invalid command \\\(command)"
            setError(.invalidCommand(errorMessage))
            return nil
        }
    }

    /// Reads a dimension value followed by `mu` (e.g., `6.0mu`, `-3mu`).
    /// Skips leading whitespace, accepts optional sign, integer/decimal digits, and a trailing `mu` suffix.
    mutating func readMuDimension() -> CGFloat? {
        skipSpaces()
        var digits = ""
        while hasCharacters {
            let character = nextCharacter()
            if character == "-" || character == "+" || character == "."
                || (character >= "0" && character <= "9")
            {
                digits.append(character)
            } else {
                unlookCharacter()
                break
            }
        }
        guard let value = Double(digits) else { return nil }
        // Consume optional "mu" suffix
        if hasCharacters {
            let savedIndex = currentCharIndex
            let c1 = nextCharacter()
            if c1 == "m", hasCharacters {
                let c2 = nextCharacter()
                if c2 != "u" {
                    unlookCharacter() // not "mu", put back
                    currentCharIndex = savedIndex
                }
            } else {
                currentCharIndex = savedIndex
            }
        }
        return CGFloat(value)
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
        var colorValue = ""
        while hasCharacters {
            let character = nextCharacter()
            if character == "#" || (character >= "A" && character <= "Z")
                || (character >= "a" && character <= "z")
                || (character >= "0" && character <= "9")
            {
                colorValue.append(character)
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
        return colorValue
    }

    mutating func skipSpaces() {
        while hasCharacters {
            let character = nextCharacter().utf32Char
            if character < 0x21 || character > 0x7E {
                // skip non ascii characters and spaces
                continue
            } else {
                unlookCharacter()
                return
            }
        }
    }
}
