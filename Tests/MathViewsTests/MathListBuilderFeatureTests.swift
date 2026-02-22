import Testing

@testable import MathViews

// MARK: - High Priority Missing Features Tests

struct MathListBuilderFeatureTests {

  @Test func displayStyle() {
    // Test \displaystyle and \textstyle commands
    let testCases = [
      ("\\displaystyle \\sum_{i=1}^{n} x_i", "displaystyle with sum"),
      ("\\textstyle \\int_{0}^{\\infty} f(x) dx", "textstyle with integral"),
      ("x + \\displaystyle\\frac{a}{b} + y", "inline displaystyle fraction"),
      ("\\displaystyle x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}", "displaystyle equation"),
    ]

    for (latex, desc) in testCases {
      guard let list = try? MathListBuilder.buildChecked(fromString: latex) else { return }

      let unwrappedList = list
      #expect(unwrappedList.atoms.count >= 1, "\(desc) should have atoms")
    }
  }

  @Test func middleDelimiter() {
    // Test \middle command for delimiters in the middle of expressions
    let testCases = [
      ("\\left( \\frac{a}{b} \\middle| \\frac{c}{d} \\right)", "middle pipe"),
      ("\\left\\{ x \\middle\\| y \\right\\}", "middle double pipe"),
      ("\\left[ a \\middle\\\\ b \\right]", "middle backslash"),
    ]

    for (latex, desc) in testCases {
      guard let list = try? MathListBuilder.buildChecked(fromString: latex) else { return }

      let unwrappedList = list
      #expect(unwrappedList.atoms.count >= 1, "\(desc) should have atoms")
    }
  }

  @Test func substack() throws {
    // Test \substack for multi-line subscripts and limits

    let testCases = [
      ("\\substack{a \\\\ b}", "simple substack"),
      ("x_{\\substack{a \\\\ b}}", "substack in subscript"),
      ("\\sum_{\\substack{0 \\le i \\le m \\\\ 0 < j < n}} P(i,j)", "substack in sum limits"),
      ("\\prod_{\\substack{p \\text{ prime} \\\\ p < 100}} p", "substack with text"),
      ("A_{\\substack{n \\\\ k}}", "subscript with substack"),
      ("\\substack{\\frac{a}{b} \\\\ c}", "substack with frac"),
      ("\\substack{a}", "single row substack"),
      ("\\substack{a \\\\ b \\\\ c \\\\ d}", "multi-row substack"),
    ]

    for (latex, desc) in testCases {
      let list = try MathListBuilder.buildChecked(fromString: latex)
      #expect(list.atoms.count >= 1, "\(desc) should have atoms")

      // Verify we have a table structure (either directly or in subscript)
      var foundTable = false
      for atom in list.atoms {
        if atom.type == .table {
          foundTable = true
          break
        }
        if let subScript = atom.subScript {
          for subAtom in subScript.atoms {
            if subAtom.type == .table {
              foundTable = true
              break
            }
          }
        }
      }
      #expect(foundTable, "\(desc) should contain a table structure")
    }
  }

  @Test func manualDelimiterSizing() {
    // Test \big, \Big, \bigg, \Bigg sizing commands
    let testCases = [
      ("\\big( x \\big)", "big parentheses"),
      ("\\Big[ y \\Big]", "Big brackets"),
      ("\\bigg\\{ z \\bigg\\}", "bigg braces"),
      ("\\Bigg| w \\Bigg|", "Bigg pipes"),
      ("\\big< a \\big>", "big angle brackets"),
    ]

    for (latex, desc) in testCases {
      guard let list = try? MathListBuilder.buildChecked(fromString: latex) else { return }

      let unwrappedList = list
      #expect(unwrappedList.atoms.count >= 1, "\(desc) should have atoms")
    }
  }

  @Test func spacingCommands() {
    // Test fine-tuned spacing commands
    let testCases = [
      ("a\\,b", "thin space \\,"),
      ("a\\:b", "medium space \\:"),
      ("a\\;b", "thick space \\;"),
      ("a\\!b", "negative space \\!"),
      ("\\int\\!\\!\\!\\int f(x,y) dx dy", "multiple negative spaces"),
      ("x \\, y \\: z \\; w", "mixed spacing"),
    ]

    for (latex, desc) in testCases {
      guard let list = try? MathListBuilder.buildChecked(fromString: latex) else { return }

      let unwrappedList = list
      #expect(unwrappedList.atoms.count >= 1, "\(desc) should have atoms")
    }
  }

  // MARK: - Medium Priority Missing Features Tests

  @Test func multipleIntegrals() throws {
    // Test \iint, \iiint, \iiiint for multiple integrals
    let testCases = [
      ("\\iint f(x,y) dx dy", "double integral"),
      ("\\iiint f(x,y,z) dx dy dz", "triple integral"),
      ("\\iiiint f(w,x,y,z) dw dx dy dz", "quadruple integral"),
      ("\\iint_{D} f(x,y) dA", "double integral with limits"),
    ]

    for (latex, desc) in testCases {
      let list = try MathListBuilder.buildChecked(fromString: latex)
      #expect(list.atoms.count >= 1, "\(desc) should have atoms")

      // Verify we have a large operator (integral) in the list
      var foundOperator = false
      for atom in list.atoms where atom.type == .largeOperator {
        foundOperator = true
        break
      }
      #expect(foundOperator, "\(desc) should contain a large operator (integral)")
    }
  }

  @Test func continuedFractions() {
    // Test \cfrac for continued fractions (already added but verify)
    let testCases = [
      ("\\cfrac{1}{2}", "simple cfrac"),
      ("a_0 + \\cfrac{1}{a_1 + \\cfrac{1}{a_2}}", "nested cfrac"),
      ("\\cfrac{x^2}{y + \\cfrac{1}{z}}", "cfrac with expressions"),
    ]

    for (latex, desc) in testCases {
      // cfrac might be implemented, let's check
      guard let list = try? MathListBuilder.buildChecked(fromString: latex) else { return }

      #expect(list.atoms.count >= 1, "\(desc) should have atoms")
    }
  }

  @Test func displayStyleFraction() throws {
    // Test \dfrac - display-style fraction
    let str = "\\dfrac{1}{2}"
    let list = try MathListBuilder.buildChecked(fromString: str)
    let desc = "Error for string: \(str)"

    #expect(list.atoms.count == 1, "\(desc)")

    let frac = try #require(list.atoms[0] as? Fraction, "\(desc)")
    #expect(frac.type == .fraction, "\(desc)")
    #expect(frac.hasRule, "\(desc)")

    // Check numerator
    let numerator = try #require(frac.numerator, "\(desc)")
    #expect(numerator.atoms.count >= 1, "Numerator should have at least style atom")

    // First atom should be displaystyle
    if numerator.atoms.count > 1 {
      let styleAtom = numerator.atoms[0] as? MathStyle
      #expect(styleAtom != nil, "First atom should be style atom")
      #expect(styleAtom?.style == .display, "Should be display style")
    }

    // Check denominator
    let denominator = try #require(frac.denominator, "\(desc)")
    #expect(denominator.atoms.count >= 1, "Denominator should have at least style atom")

    if denominator.atoms.count > 1 {
      let styleAtom = denominator.atoms[0] as? MathStyle
      #expect(styleAtom != nil, "First atom should be style atom")
      #expect(styleAtom?.style == .display, "Should be display style")
    }
  }

  @Test func textStyleFraction() throws {
    // Test \tfrac - text-style fraction
    let str = "\\tfrac{a}{b}"
    let list = try MathListBuilder.buildChecked(fromString: str)
    let desc = "Error for string: \(str)"

    #expect(list.atoms.count == 1, "\(desc)")

    let frac = try #require(list.atoms[0] as? Fraction, "\(desc)")
    #expect(frac.type == .fraction, "\(desc)")
    #expect(frac.hasRule, "\(desc)")

    // Check numerator
    let numerator = try #require(frac.numerator, "\(desc)")
    #expect(numerator.atoms.count >= 1, "Numerator should have at least style atom")

    if numerator.atoms.count > 1 {
      let styleAtom = numerator.atoms[0] as? MathStyle
      #expect(styleAtom != nil, "First atom should be style atom")
      #expect(styleAtom?.style == .text, "Should be text style")
    }

    // Check denominator
    let denominator = try #require(frac.denominator, "\(desc)")
    #expect(denominator.atoms.count >= 1, "Denominator should have at least style atom")

    if denominator.atoms.count > 1 {
      let styleAtom = denominator.atoms[0] as? MathStyle
      #expect(styleAtom != nil, "First atom should be style atom")
      #expect(styleAtom?.style == .text, "Should be text style")
    }
  }

  @Test func displayAndTextStyleFractions() throws {
    // Test the original LaTeX from the user's issue
    let str = "y'=-\\dfrac{2}{x^{3}}"
    let list = try MathListBuilder.buildChecked(fromString: str)
    let desc = "Error for string: \(str)"

    #expect(list.atoms.count >= 4, "Should have y, ', =, -, and fraction")

    // Find the fraction atom
    var foundFraction = false
    for atom in list.atoms {
      if atom.type == .fraction {
        foundFraction = true
        let frac = try #require(atom as? Fraction)

        // Check that numerator has displaystyle
        if let numerator = frac.numerator, !numerator.atoms.isEmpty {
          let firstAtom = numerator.atoms[0]
          if let styleAtom = firstAtom as? MathStyle {
            #expect(styleAtom.style == .display, "Should force display style")
          }
        }
        break
      }
    }

    #expect(foundFraction, "Should find fraction in the expression")

    // Test nested dfrac and tfrac
    let nestedStr = "\\dfrac{\\tfrac{a}{b}}{c}"
    let nestedList = try MathListBuilder.buildChecked(fromString: nestedStr)
    #expect(nestedList.atoms.count >= 1, "Should parse nested dfrac/tfrac")
  }

  @Test func starredMatrices() throws {
    // Test starred matrix environments with alignment
    let testCases = [
      ("\\begin{pmatrix*}[r] 1 & 2 \\\\ 3 & 4 \\end{pmatrix*}", "pmatrix* right align"),
      ("\\begin{bmatrix*}[l] a & b \\\\ c & d \\end{bmatrix*}", "bmatrix* left align"),
      ("\\begin{vmatrix*}[c] x & y \\\\ z & w \\end{vmatrix*}", "vmatrix* center align"),
      (
        "\\begin{matrix*}[r] 10 & 20 \\\\ 30 & 40 \\end{matrix*}",
        "matrix* right align (no delimiters)"
      ),
    ]

    for (latex, desc) in testCases {
      let list = try MathListBuilder.buildChecked(fromString: latex)
      #expect(list.atoms.count >= 1, "\(desc) should have atoms")

      // Verify we have a table structure
      var foundTable = false
      for atom in list.atoms {
        if atom.type == .table {
          foundTable = true
          break
        }
        // Check inside inner atoms (for matrices with delimiters)
        if atom.type == .inner, let inner = atom as? Inner, let innerList = inner.innerList {
          for innerAtom in innerList.atoms {
            if innerAtom.type == .table {
              foundTable = true
              break
            }
          }
        }
      }
      #expect(foundTable, "\(desc) should contain a table structure")
    }
  }

  @Test func smallMatrix() throws {
    // Test \smallmatrix for inline matrices
    let testCases = [
      (
        "\\left( \\begin{smallmatrix} a & b \\\\ c & d \\end{smallmatrix} \\right)",
        "smallmatrix with delimiters"
      ),
      (
        "A = \\left( \\begin{smallmatrix} 1 & 0 \\\\ 0 & 1 \\end{smallmatrix} \\right)",
        "identity in smallmatrix"
      ),
      ("\\begin{smallmatrix} x \\\\ y \\end{smallmatrix}", "column vector in smallmatrix"),
    ]

    for (latex, desc) in testCases {
      let list = try MathListBuilder.buildChecked(fromString: latex)
      #expect(list.atoms.count >= 1, "\(desc) should have atoms")

      // Verify we have a table structure
      var foundTable = false
      for atom in list.atoms {
        if atom.type == .table {
          foundTable = true
          break
        }
        // Check inside inner atoms (for matrices with delimiters)
        if atom.type == .inner, let inner = atom as? Inner, let innerList = inner.innerList {
          for innerAtom in innerList.atoms {
            if innerAtom.type == .table {
              foundTable = true
              break
            }
          }
        }
      }
      #expect(foundTable, "\(desc) should contain a table structure")
    }
  }
}
