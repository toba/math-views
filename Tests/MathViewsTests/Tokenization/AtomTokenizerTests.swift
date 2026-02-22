import CoreGraphics
import Testing

@testable import MathViews

struct AtomTokenizerTests {

  let font: FontInstance
  let tokenizer: AtomTokenizer

  init() {
    font = FontInstance(fontWithName: "latinmodern-math", size: 20)
    tokenizer = AtomTokenizer(font: font, style: .display, cramped: false)
  }

  // MARK: - Basic Tokenization Tests

  @Test func tokenizeEmptyList() {
    let elements = tokenizer.tokenize([])
    #expect(elements.isEmpty)
  }

  @Test func tokenizeSingleOrdinaryAtom() {
    let atom = MathAtom(type: .ordinary, value: "x")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    #expect(elements[0].isBreakBefore)
    #expect(elements[0].isBreakAfter)
    #expect(!elements[0].indivisible)
  }

  @Test func tokenizeVariable() {
    let atom = MathAtom(type: .variable, value: "y")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    if case .text(let text) = elements[0].content {
      #expect(text == "y")
    } else {
      Issue.record("Expected text content")
    }
  }

  @Test func tokenizeNumber() {
    let atom = MathAtom(type: .number, value: "42")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    #expect(elements[0].width > 0)
  }

  // MARK: - Operator Tokenization Tests

  @Test func tokenizeBinaryOperator() {
    let atom = MathAtom(type: .binaryOperator, value: "+")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    #expect(elements[0].penaltyBefore == BreakPenalty.best)
    #expect(elements[0].penaltyAfter == BreakPenalty.best)

    if case .operator(let op, let type) = elements[0].content {
      #expect(op == "+")
      #expect(type == .binaryOperator)
    } else {
      Issue.record("Expected operator content")
    }
  }

  @Test func tokenizeRelationOperator() {
    let atom = MathAtom(type: .relation, value: "=")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    #expect(elements[0].penaltyBefore == BreakPenalty.best)
  }

  @Test func tokenizeMultipleOperators() {
    let atoms = [
      MathAtom(type: .variable, value: "x"),
      MathAtom(type: .binaryOperator, value: "+"),
      MathAtom(type: .variable, value: "y"),
    ]
    let elements = tokenizer.tokenize(atoms)

    #expect(elements.count == 3)
  }

  // MARK: - Delimiter Tokenization Tests

  @Test func tokenizeOpenDelimiter() {
    let atom = MathAtom(type: .open, value: "(")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    #expect(elements[0].isBreakBefore)
    #expect(!elements[0].isBreakAfter, "Should NOT break after open delimiter")
  }

  @Test func tokenizeCloseDelimiter() {
    let atom = MathAtom(type: .close, value: ")")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    #expect(!elements[0].isBreakBefore, "Should NOT break before close delimiter")
    #expect(elements[0].isBreakAfter)
  }

  // MARK: - Punctuation Tokenization Tests

  @Test func tokenizePunctuation() {
    let atom = MathAtom(type: .punctuation, value: ",")
    let elements = tokenizer.tokenize([atom])

    #expect(elements.count == 1)
    #expect(!elements[0].isBreakBefore, "Should NOT break before punctuation")
    #expect(elements[0].isBreakAfter)
  }

  // MARK: - Script Tokenization Tests

  @Test func tokenizeAtomWithSuperscript() {
    let atom = MathAtom(type: .variable, value: "x")
    let superScript = MathList()
    superScript.add(MathAtom(type: .number, value: "2"))
    atom.superScript = superScript

    let elements = tokenizer.tokenize([atom])

    // Should have base + superscript = 2 elements
    #expect(elements.count >= 2)

    // All elements should share same groupId
    if elements.count >= 2 {
      #expect(elements[0].groupId != nil)
      #expect(elements[0].groupId == elements[1].groupId)

      // Base cannot break after
      #expect(!elements[0].isBreakAfter)

      // Superscript cannot break before
      #expect(!elements[1].isBreakBefore)
    }
  }

  @Test func tokenizeAtomWithSubscript() {
    let atom = MathAtom(type: .variable, value: "x")
    let subScript = MathList()
    subScript.add(MathAtom(type: .variable, value: "i"))
    atom.subScript = subScript

    let elements = tokenizer.tokenize([atom])

    #expect(elements.count >= 2)

    if elements.count >= 2 {
      // Should be grouped
      #expect(elements[0].groupId != nil)
      #expect(elements[0].groupId == elements[1].groupId)
    }
  }

  @Test func tokenizeAtomWithBothScripts() {
    let atom = MathAtom(type: .variable, value: "x")

    let subScript = MathList()
    subScript.add(MathAtom(type: .variable, value: "i"))
    atom.subScript = subScript

    let superScript = MathList()
    superScript.add(MathAtom(type: .number, value: "2"))
    atom.superScript = superScript

    let elements = tokenizer.tokenize([atom])

    // Should have base + subscript + superscript = 3 elements
    #expect(elements.count >= 3)

    if elements.count >= 3 {
      // All should share groupId
      let groupId = elements[0].groupId
      #expect(groupId != nil)
      #expect(elements[1].groupId == groupId)
      #expect(elements[2].groupId == groupId)
    }
  }

  // MARK: - Complex Structure Tests

  @Test func tokenizeFraction() {
    let fraction = Fraction()
    fraction.numerator = MathList()
    fraction.numerator?.add(MathAtom(type: .variable, value: "a"))
    fraction.denominator = MathList()
    fraction.denominator?.add(MathAtom(type: .variable, value: "b"))

    let elements = tokenizer.tokenize([fraction])

    #expect(elements.count == 1, "Fraction should be single atomic element")
    #expect(elements[0].indivisible, "Fraction must be indivisible")

    if case .display(let display) = elements[0].content {
      #expect(display is FractionDisplay)
    } else {
      Issue.record("Expected display content for fraction")
    }
  }

  @Test func tokenizeRadical() {
    let radical = Radical()
    radical.radicand = MathList()
    radical.radicand?.add(MathAtom(type: .variable, value: "x"))

    let elements = tokenizer.tokenize([radical])

    #expect(elements.count == 1, "Radical should be single atomic element")
    #expect(elements[0].indivisible, "Radical must be indivisible")
  }

  // MARK: - Integration Tests

  @Test func tokenizeSimpleEquation() {
    // x + y = z
    let atoms = [
      MathAtom(type: .variable, value: "x"),
      MathAtom(type: .binaryOperator, value: "+"),
      MathAtom(type: .variable, value: "y"),
      MathAtom(type: .relation, value: "="),
      MathAtom(type: .variable, value: "z"),
    ]

    let elements = tokenizer.tokenize(atoms)

    #expect(elements.count == 5)

    // Verify break points: should be able to break before/after operators
    #expect(elements[1].isBreakBefore)  // + operator
    #expect(elements[1].isBreakAfter)
    #expect(elements[3].isBreakBefore)  // = operator
    #expect(elements[3].isBreakAfter)
  }

  @Test func tokenizeParenthesizedExpression() {
    // (x + y)
    let atoms = [
      MathAtom(type: .open, value: "("),
      MathAtom(type: .variable, value: "x"),
      MathAtom(type: .binaryOperator, value: "+"),
      MathAtom(type: .variable, value: "y"),
      MathAtom(type: .close, value: ")"),
    ]

    let elements = tokenizer.tokenize(atoms)

    #expect(elements.count == 5)

    // Cannot break after open paren
    #expect(!elements[0].isBreakAfter)

    // Cannot break before close paren
    #expect(!elements[4].isBreakBefore)
  }

  @Test func tokenizeComplexExpression() {
    // x^2 + y
    let x = MathAtom(type: .variable, value: "x")
    let superScript = MathList()
    superScript.add(MathAtom(type: .number, value: "2"))
    x.superScript = superScript

    let atoms: [MathAtom] = [
      x,
      MathAtom(type: .binaryOperator, value: "+"),
      MathAtom(type: .variable, value: "y"),
    ]

    let elements = tokenizer.tokenize(atoms)

    // x^2 produces 2 elements (base + script), + is 1, y is 1 = 4 total
    #expect(elements.count >= 4)
  }

  // MARK: - Width Tests

  @Test func elementWidthsArePositive() {
    let atoms = [
      MathAtom(type: .variable, value: "x"),
      MathAtom(type: .binaryOperator, value: "+"),
      MathAtom(type: .number, value: "1"),
    ]

    let elements = tokenizer.tokenize(atoms)

    for element in elements {
      #expect(element.width > 0, "All elements should have positive width")
    }
  }

  // MARK: - Text Mode Accent Word Boundary Tests

  /// Test that accented characters in text mode don't break words
  /// Issue: "bacteries" was being split as "bacte" + "ries" because the accent
  /// was treated as a separate breakable element
  @Test func accentedCharacterInTextModeWordBoundary() {
    // Parse LaTeX to get atoms for "bacteries" - the e becomes an accent atom
    let latex = "\\text{bactéries}"
    guard let mathList = MathListBuilder.build(fromString: latex) else {
      Issue.record("Failed to parse LaTeX")
      return
    }

    let elements = tokenizer.tokenize(mathList.atoms)

    // Find elements that represent the accent "e" and adjacent characters
    // The word should not be breakable in the middle
    var foundAccent = false
    for (index, element) in elements.enumerated() {
      if case .display = element.content,
        element.originalAtom.type == .accent
      {
        foundAccent = true

        // Check that we can't break BEFORE the accent (after "t")
        #expect(
          !element.isBreakBefore,
          "Should NOT be able to break before accented character in the middle of a word")

        // Check that we can't break AFTER the accent (before "r")
        #expect(
          !element.isBreakAfter,
          "Should NOT be able to break after accented character in the middle of a word")

        // Also check that the preceding element (if any) can't break after
        if index > 0 {
          let prevElement = elements[index - 1]
          #expect(
            !prevElement.isBreakAfter,
            "Previous character should NOT allow break after when followed by accent in word")
        }

        // And the following element (if any) can't break before
        if index + 1 < elements.count {
          let nextElement = elements[index + 1]
          #expect(
            !nextElement.isBreakBefore,
            "Next character should NOT allow break before when preceded by accent in word")
        }
      }
    }

    #expect(foundAccent, "Should have found an accent element for 'e'")
  }

  /// Test that multiple accented characters in a word are handled correctly
  @Test func multipleAccentedCharactersInTextMode() {
    // "apres" has an accent
    let latex = "\\text{après}"
    guard let mathList = MathListBuilder.build(fromString: latex) else {
      Issue.record("Failed to parse LaTeX")
      return
    }

    let elements = tokenizer.tokenize(mathList.atoms)

    // Count accents and verify none allow word-internal breaks
    var accentCount = 0
    for element in elements {
      if case .display = element.content,
        element.originalAtom.type == .accent
      {
        accentCount += 1

        // This is the "e" - check it doesn't allow breaks in word
        #expect(
          !element.isBreakBefore,
          "Accent in word should not allow break before")
        #expect(
          !element.isBreakAfter,
          "Accent in word should not allow break after")
      }
    }

    #expect(accentCount > 0, "Should have found accent(s)")
  }

  /// Test that accents at word boundaries DO allow breaks
  @Test func accentAtWordBoundaryAllowsBreak() {
    // "cafe noir" - the e is at the end of "cafe", should allow break after it
    let latex = "\\text{café noir}"
    guard let mathList = MathListBuilder.build(fromString: latex) else {
      Issue.record("Failed to parse LaTeX")
      return
    }

    let elements = tokenizer.tokenize(mathList.atoms)

    // Find the accent for "e" in "cafe"
    for (index, element) in elements.enumerated() {
      if case .display = element.content,
        element.originalAtom.type == .accent
      {
        // The e is followed by a space, so it SHOULD allow break after
        // Check the next element - if it's a space, the accent can break after
        if index + 1 < elements.count {
          let nextElement = elements[index + 1]
          if case .text(let text) = nextElement.content, text == " " {
            #expect(
              element.isBreakAfter,
              "Accent at end of word (before space) should allow break after")
          }
        }
      }
    }
  }
}
