import Testing

@testable import MathViews

// MARK: - Inline and Display Math Delimiter Tests

struct MathListBuilderDelimiterTests {
  @Test func inlineMathDollar() throws {
    let str = "$x^2$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Should have textstyle at start, then variable with superscript
    #expect(list.atoms.count >= 1, "Should have at least one atom")

    // Find the variable atom (skip style atoms)
    var foundVariable = false
    for atom in list.atoms {
      if atom.type == .variable, atom.nucleus == "x" {
        foundVariable = true
        #expect(atom.superScript != nil, "Should have superscript")
        break
      }
    }
    #expect(foundVariable, "Should find variable x")
  }

  @Test func inlineMathParens() throws {
    let str = "\\(E=mc^2\\)"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 3, "Should have E, =, m, c atoms")

    // Check for equals sign
    var foundEquals = false
    for atom in list.atoms {
      if atom.type == .relation, atom.nucleus == "=" {
        foundEquals = true
        break
      }
    }
    #expect(foundEquals, "Should find equals sign")
  }

  @Test func inlineMathWithCases() throws {
    let str = "\\(\\begin{cases} x + y = 5 \\\\ 2x - y = 1 \\end{cases}\\)"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // cases environment returns an Inner atom with table inside
    var foundInner = false
    for atom in list.atoms where atom.type == .inner {
      let inner = try #require(atom as? Inner)
      // Look for table inside the inner list
      if let innerList = inner.innerList {
        for innerAtom in innerList.atoms where innerAtom.type == .table {
          let table = try #require(innerAtom as? MathTable)
          #expect(table.environment == "cases", "Should be cases environment")
          #expect(table.numRows == 2, "Should have 2 rows")
          foundInner = true
          break
        }
      }
      if foundInner { break }
    }
    #expect(foundInner, "Should find cases table inside inner atom")
  }

  @Test func inlineMathVectorDot() throws {
    let str = "$\\vec{a} \\cdot \\vec{b}$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Should contain accents (for vec) and cdot operator
    var hasAccent = false
    var hasCdot = false

    for atom in list.atoms {
      if atom.type == .accent {
        hasAccent = true
      }
      if atom.type == .binaryOperator, atom.nucleus.contains("\u{22C5}") {
        hasCdot = true
      }
    }

    #expect(hasAccent, "Should have accent for \\vec")
    #expect(hasCdot, "Should have \\cdot operator")
  }

  @Test func displayMathDoubleDollar() throws {
    let str = "$$x^2 + y^2 = z^2$$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 5, "Should have multiple atoms for expression")

    // Should NOT have textstyle at start (display mode)
    let firstAtom = list.atoms.first
    #expect(firstAtom?.type != .style, "Display mode should not force textstyle")
  }

  @Test func displayMathBrackets() throws {
    let str = "\\[\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}\\]"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Find sum operator
    var foundSum = false
    for atom in list.atoms {
      if atom.type == .largeOperator, atom.nucleus.contains("\u{2211}") {
        foundSum = true
        #expect(atom.subScript != nil, "Sum should have subscript")
        #expect(atom.superScript != nil, "Sum should have superscript")
        break
      }
    }
    #expect(foundSum, "Should find sum operator")
  }

  @Test func displayMathCasesWithoutDelimiters() throws {
    // This should work as before (backward compatibility)
    let str = "\\begin{cases} x + y = 5 \\\\ 2x - y = 1 \\end{cases}"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 1, "Should have at least one atom")

    // cases environment returns an Inner atom with table inside
    var foundTable = false
    for atom in list.atoms where atom.type == .inner {
      let inner = try #require(atom as? Inner)
      if let innerList = inner.innerList {
        for innerAtom in innerList.atoms where innerAtom.type == .table {
          let table = try #require(innerAtom as? MathTable)
          #expect(table.environment == "cases", "Should be cases environment")
          #expect(table.numRows == 2, "Should have 2 rows")
          foundTable = true
          break
        }
      }
      if foundTable { break }
    }

    #expect(foundTable, "Should find cases table inside inner atom")
  }

  @Test func backwardCompatibilityNoDelimiters() throws {
    // Test that expressions without delimiters still work
    let str = "x^2 + y^2 = z^2"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 5, "Should have multiple atoms")
  }

  @Test func emptyInlineMath() throws {
    let str = "$$$"  // This is $$$ which should be treated as $$ + $
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Should handle gracefully
    _ = list
  }

  @Test func emptyDisplayMath() {
    let str = "\\[\\]"
    let list = MathListBuilder.build(fromString: str)

    // Empty content may return nil or an empty list, both are acceptable
    if let list {
      #expect(list.atoms.isEmpty, "Should have empty or minimal atoms")
    }
  }

  @Test func dollarInMath() throws {
    // Test that delimiters are properly stripped
    let str = "$a + b$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Should not contain $ in the parsed atoms
    for atom in list.atoms {
      #expect(!(atom.nucleus.contains("$")), "Should not have $ in nucleus")
    }
  }

  @Test func complexInlineExpression() throws {
    let str = "$\\frac{1}{2} + \\sqrt{3}$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Should have fraction and radical
    var hasFraction = false
    var hasRadical = false

    for atom in list.atoms {
      if atom.type == .fraction {
        hasFraction = true
      }
      if atom.type == .radical {
        hasRadical = true
      }
    }

    #expect(hasFraction, "Should have fraction")
    #expect(hasRadical, "Should have radical")
  }

  @Test func inlineMathStyleForcing() throws {
    // Inline math should have textstyle prepended
    let str = "$\\sum_{i=1}^{n} i$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // First atom should be style atom with text style
    if let firstAtom = list.atoms.first, firstAtom.type == .style {
      let styleAtom = try #require(firstAtom as? MathStyle)
      #expect(styleAtom.style == .text, "Inline mode should force text style")
    }
  }

  // MARK: - Tests for throwing API with delimiters

  @Test func inlineMathDollarChecked() throws {
    let str = "$x^2$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Find the variable atom (skip style atoms)
    var foundVariable = false
    for atom in list.atoms {
      if atom.type == .variable, atom.nucleus == "x" {
        foundVariable = true
        #expect(atom.superScript != nil, "Should have superscript")
        break
      }
    }
    #expect(foundVariable, "Should find variable x")
  }

  @Test func inlineMathParensChecked() throws {
    let str = "\\(E=mc^2\\)"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 3, "Should have E, =, m, c atoms")

    // Check for equals sign
    var foundEquals = false
    for atom in list.atoms {
      if atom.type == .relation, atom.nucleus == "=" {
        foundEquals = true
        break
      }
    }
    #expect(foundEquals, "Should find equals sign")
  }

  @Test func inlineMathWithCasesChecked() throws {
    let str = "\\(\\begin{cases} x + y = 5 \\\\ 2x - y = 1 \\end{cases}\\)"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // cases environment returns an Inner atom with table inside
    var foundInner = false
    for atom in list.atoms where atom.type == .inner {
      let inner = try #require(atom as? Inner)
      if let innerList = inner.innerList {
        for innerAtom in innerList.atoms where innerAtom.type == .table {
          let table = try #require(innerAtom as? MathTable)
          #expect(table.environment == "cases", "Should be cases environment")
          #expect(table.numRows == 2, "Should have 2 rows")
          foundInner = true
          break
        }
      }
      if foundInner { break }
    }
    #expect(foundInner, "Should find cases table inside inner atom")
  }

  @Test func displayMathDoubleDollarChecked() throws {
    let str = "$$x^2 + y^2 = z^2$$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 5, "Should have multiple atoms for expression")
  }

  @Test func displayMathBracketsChecked() throws {
    let str = "\\[\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}\\]"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Find sum operator
    var foundSum = false
    for atom in list.atoms {
      if atom.type == .largeOperator, atom.nucleus.contains("\u{2211}") {
        foundSum = true
        #expect(atom.subScript != nil, "Sum should have subscript")
        #expect(atom.superScript != nil, "Sum should have superscript")
        break
      }
    }
    #expect(foundSum, "Should find sum operator")
  }

  @Test func displayMathCasesWithoutDelimitersChecked() throws {
    let str = "\\begin{cases} x + y = 5 \\\\ 2x - y = 1 \\end{cases}"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 1, "Should have at least one atom")

    // cases environment returns an Inner atom with table inside
    var foundTable = false
    for atom in list.atoms where atom.type == .inner {
      let inner = try #require(atom as? Inner)
      if let innerList = inner.innerList {
        for innerAtom in innerList.atoms where innerAtom.type == .table {
          let table = try #require(innerAtom as? MathTable)
          #expect(table.environment == "cases", "Should be cases environment")
          #expect(table.numRows == 2, "Should have 2 rows")
          foundTable = true
          break
        }
      }
      if foundTable { break }
    }

    #expect(foundTable, "Should find cases table inside inner atom")
  }

  @Test func backwardCompatibilityNoDelimitersChecked() throws {
    let str = "x^2 + y^2 = z^2"
    let list = try MathListBuilder.buildChecked(fromString: str)

    #expect(list.atoms.count >= 5, "Should have multiple atoms")
  }

  @Test func invalidLatexWithError() throws {
    let str = "$\\notacommand$"
    let error = #expect(throws: ParseError.self) {
      try MathListBuilder.buildChecked(fromString: str)
    }
    if let error {
      #expect(ParseErrorCase.invalidCommand.matches(error), "Should be invalid command error")
    }
  }

  @Test func mismatchedBracesWithError() throws {
    let str = "${x+2$"
    let error = #expect(throws: ParseError.self) {
      try MathListBuilder.buildChecked(fromString: str)
    }
    if let error {
      #expect(
        ParseErrorCase.mismatchBraces.matches(error),
        "Should be mismatched braces error",
      )
    }
  }

  @Test func complexInlineExpressionChecked() throws {
    let str = "$\\frac{1}{2} + \\sqrt{3}$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Should have fraction and radical
    var hasFraction = false
    var hasRadical = false

    for atom in list.atoms {
      if atom.type == .fraction {
        hasFraction = true
      }
      if atom.type == .radical {
        hasRadical = true
      }
    }

    #expect(hasFraction, "Should have fraction")
    #expect(hasRadical, "Should have radical")
  }

  @Test func inlineMathVectorDotChecked() throws {
    let str = "$\\vec{a} \\cdot \\vec{b}$"
    let list = try MathListBuilder.buildChecked(fromString: str)

    // Should contain accents (for vec) and cdot operator
    var hasAccent = false
    var hasCdot = false

    for atom in list.atoms {
      if atom.type == .accent {
        hasAccent = true
      }
      if atom.type == .binaryOperator, atom.nucleus.contains("\u{22C5}") {
        hasCdot = true
      }
    }

    #expect(hasAccent, "Should have accent for \\vec")
    #expect(hasCdot, "Should have \\cdot operator")
  }
}
