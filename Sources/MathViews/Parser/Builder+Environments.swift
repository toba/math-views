import Foundation

// MARK: - Environment and fraction command handling

extension MathListBuilder {
  /// Maps fraction-like commands to their optional left/right delimiter characters.
  /// Empty arrays mean no delimiters (plain `\over`, `\atop`).
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
    } else if let delimiters = Self.fractionCommands[command] {
      var fraction: Fraction! = nil
      if command == "over" {
        fraction = Fraction()
      } else {
        fraction = Fraction(hasRule: false)
      }
      if delimiters.count == 2 {
        fraction.leftDelimiter = String(delimiters[0])
        fraction.rightDelimiter = String(delimiters[1])
      }
      fraction.numerator = list
      fraction.denominator = buildInternal(false, stopChar: stopChar)
      if error != nil {
        return nil
      }
      let fracList = MathList()
      fracList.add(fraction)
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
      let environment = readEnvironment()
      if environment == nil {
        return nil
      }
      if environment! != currentEnv!.envName {
        let errorMessage =
          "Begin environment name \(currentEnv!.envName ?? "(none)") does not match end name: \(environment!)"
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
      if let largeOperator = atom as? LargeOperator {
        largeOperator.hasLimits = true
      } else {
        setError(.invalidLimits("Limits can only be applied to an operator."))
      }
      return true
    } else if modifier == "nolimits" {
      if let largeOperator = atom as? LargeOperator {
        largeOperator.hasLimits = false
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
      let fraction = Fraction()
      fraction.numerator = buildInternal(true)
      fraction.denominator = buildInternal(true)
      return fraction
    } else if command == "cfrac" {
      let fraction = Fraction()
      fraction.isContinuedFraction = true

      // Parse optional alignment parameter [l], [r], [c]
      skipSpaces()
      if hasCharacters, string[currentCharIndex] == "[" {
        _ = nextCharacter()  // consume '['
        if hasCharacters {
          let alignmentCharacter = nextCharacter()
          if alignmentCharacter == "l" || alignmentCharacter == "r" || alignmentCharacter == "c" {
            fraction.alignment = String(alignmentCharacter)
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
      let firstArgument = buildInternal(true)
      let secondArgument = buildInternal(true)
      let content = MathList()
      if let firstList = firstArgument {
        for atom in firstList.atoms {
          content.add(atom)
        }
      }
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
      let radical = Radical()
      guard hasCharacters else {
        radical.radicand = buildInternal(true)
        return radical
      }
      let character = nextCharacter()
      if character == "[" {
        radical.degree = buildInternal(false, stopChar: "]")
        radical.radicand = buildInternal(true)
      } else {
        unlookCharacter()
        radical.radicand = buildInternal(true)
      }
      return radical
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
      let overlineAtom = Overline()
      overlineAtom.innerList = buildInternal(true)

      return overlineAtom
    } else if command == "underline" {
      let underlineAtom = Underline()
      underlineAtom.innerList = buildInternal(true)

      return underlineAtom
    } else if command == "begin" {
      if let environment = readEnvironment() {
        // Check if this is a starred matrix environment and read optional alignment
        var alignment: ColumnAlignment?
        if environment.hasSuffix("*") {
          alignment = readOptionalAlignment()
          if self.error != nil {
            return nil
          }
        }

        return buildTable(env: environment, alignment: alignment, firstList: nil, isRow: false)
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
    let environment = readString()

    if !expectCharacter("}") {
      // We didn"t find an closing brace, so invalid format.
      setError(.characterNotFound("Missing }"))
      return nil
    }
    return environment
  }

  /// Reads optional alignment parameter for starred matrix environments: [r], [l], or [c]
  mutating func readOptionalAlignment() -> ColumnAlignment? {
    skipSpaces()

    // Check if there's an opening bracket
    guard hasCharacters, string[currentCharIndex] == "[" else {
      return nil
    }

    _ = nextCharacter()  // consume '['
    skipSpaces()

    guard hasCharacters else {
      setError(.characterNotFound("Missing alignment specifier after ["))
      return nil
    }

    let alignmentCharacter = nextCharacter()
    let alignment: ColumnAlignment?

    switch alignmentCharacter {
    case "l":
      alignment = .left
    case "c":
      alignment = .center
    case "r":
      alignment = .right
    default:
      setError(
        .invalidEnv("Invalid alignment specifier: \(alignmentCharacter). Must be l, c, or r"),
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

  func assertNotSpace(_ character: Character) {
    assert(
      character >= "\u{21}" && character <= "\u{7E}", "Expected non-space character \(character)")
  }

  mutating func buildTable(
    env: String?, alignment: ColumnAlignment? = nil, firstList: MathList?, isRow: Bool,
  ) -> MathAtom? {
    // Save the current env till an new one gets built.
    let previousEnvironment = currentEnv

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
      currentEnv = previousEnvironment
      return table
    } catch {
      if self.error == nil {
        self.error = error
      }
      return nil
    }
  }

  mutating func boundaryAtom(for delimiterType: String) -> MathAtom? {
    let delimiter = readDelimiter()
    if delimiter == nil {
      let errorMessage = "Missing delimiter for \\\(delimiterType)"
      setError(.missingDelimiter(errorMessage))
      return nil
    }
    let boundary = MathAtomFactory.boundary(forDelimiter: delimiter!)
    if boundary == nil {
      let errorMessage = "Invalid delimiter for \(delimiterType): \(delimiter!)"
      setError(.invalidDelimiter(errorMessage))
      return nil
    }
    return boundary
  }

  mutating func readDelimiter() -> String? {
    skipSpaces()
    while hasCharacters {
      let character = nextCharacter()
      assertNotSpace(character)
      if character == "\\" {
        let command = readCommand()
        if command == "|" {
          return "||"
        }
        return command
      } else {
        return String(character)
      }
    }
    return nil
  }

  mutating func readCommand() -> String {
    let singleChars = "{}$#%_| ,>:;!\\"
    if hasCharacters {
      let character = nextCharacter()
      if singleChars.contains(character) {
        return String(character)
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
      let character = nextCharacter()
      if character.isLowercase || character.isUppercase || character == "*" {
        output.append(character)
      } else {
        unlookCharacter()
        break
      }
    }
    return output
  }
}
