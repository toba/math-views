import Testing
import Foundation
@testable import MathViews

// MARK: - Comprehensive Command Coverage Tests

struct MathListBuilderCommandTests {

    @Test func greekLettersLowercase() throws {
        let commands = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta",
                        "iota", "kappa", "lambda", "mu", "nu", "xi", "omicron", "pi",
                        "rho", "sigma", "tau", "upsilon", "phi", "chi", "psi", "omega"]

        for cmd in commands {
            var error: NSError? = nil
            let str = "$\\\(cmd)$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(cmd)")
            #expect(error == nil, "Should not error on \\\(cmd): \(error?.localizedDescription ?? "none")")
            #expect(unwrappedList.atoms.count >= 1, "\\\(cmd) should have at least one atom")
        }
    }

    @Test func greekLettersUppercase() throws {
        let commands = ["Gamma", "Delta", "Theta", "Lambda", "Xi", "Pi", "Sigma", "Upsilon", "Phi", "Psi", "Omega"]

        for cmd in commands {
            var error: NSError? = nil
            let str = "$\\\(cmd)$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(cmd)")
            #expect(error == nil, "Should not error on \\\(cmd): \(error?.localizedDescription ?? "none")")
            #expect(unwrappedList.atoms.count >= 1, "\\\(cmd) should have at least one atom")
        }
    }

    @Test func binaryOperators() throws {
        let operators = ["times", "div", "pm", "mp", "ast", "star", "circ", "bullet",
                         "cdot", "cap", "cup", "uplus", "sqcap", "sqcup",
                         "oplus", "ominus", "otimes", "oslash", "odot", "wedge", "vee"]

        for op in operators {
            var error: NSError? = nil
            let str = "$a \\\(op) b$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(op)")
            #expect(error == nil, "Should not error on \\\(op): \(error?.localizedDescription ?? "none")")

            // Should find the operator
            var foundOp = false
            for atom in unwrappedList.atoms {
                if atom.type == .binaryOperator {
                    foundOp = true
                    break
                }
            }
            #expect(foundOp, "Should find binary operator for \\\(op)")
        }
    }

    @Test func relations() throws {
        let relations = ["leq", "geq", "neq", "equiv", "approx", "sim", "simeq", "cong",
                         "prec", "succ", "subset", "supset", "subseteq", "supseteq",
                         "in", "notin", "ni", "propto", "perp", "parallel"]

        for rel in relations {
            var error: NSError? = nil
            let str = "$a \\\(rel) b$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(rel)")
            #expect(error == nil, "Should not error on \\\(rel): \(error?.localizedDescription ?? "none")")

            // Should find the relation
            var foundRel = false
            for atom in unwrappedList.atoms {
                if atom.type == .relation {
                    foundRel = true
                    break
                }
            }
            #expect(foundRel, "Should find relation for \\\(rel)")
        }
    }

    @Test func allAccents() throws {
        let accents = ["hat", "tilde", "bar", "dot", "ddot", "check", "grave", "acute", "breve", "vec"]

        for acc in accents {
            var error: NSError? = nil
            let str = "$\\\(acc){x}$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(acc)")
            #expect(error == nil, "Should not error on \\\(acc): \(error?.localizedDescription ?? "none")")

            // Should find the accent
            var foundAccent = false
            for atom in unwrappedList.atoms {
                if atom.type == .accent {
                    foundAccent = true
                    break
                }
            }
            #expect(foundAccent, "Should find accent for \\\(acc)")
        }
    }

    // MARK: - Vector Arrow Command Tests

    @Test func vectorArrowCommands() throws {
        let commands = ["vec", "overleftarrow", "overrightarrow", "overleftrightarrow"]

        for cmd in commands {
            let str = "\\\(cmd){x}"
            var error: NSError? = nil
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(cmd)")
            #expect(error == nil, "Should not error on \\\(cmd): \(error?.localizedDescription ?? "none")")

            // Should create accent atom
            #expect(unwrappedList.atoms.count == 1, "For \\\(cmd)")
            let accent = try #require(unwrappedList.atoms[0] as? Accent, "For \\\(cmd)")
            #expect(accent.type == .accent)

            // Should have innerList with variable 'x'
            let innerList = try #require(accent.innerList)
            #expect(innerList.atoms.count == 1)
            let innerAtom = innerList.atoms[0]
            #expect(innerAtom.type == .variable)
            #expect(innerAtom.nucleus == "x")
        }
    }

    @Test func vectorArrowUnicodeValues() throws {
        let expectedUnicode: [String: String] = [
            "vec": "\u{20D7}",
            "overleftarrow": "\u{20D6}",
            "overrightarrow": "\u{20D7}",
            "overleftrightarrow": "\u{20E1}"
        ]

        for (cmd, expectedValue) in expectedUnicode {
            let str = "\\\(cmd){a}"
            let list = try #require(MathListBuilder.build(fromString: str))
            let accent = try #require(list.atoms[0] as? Accent)

            #expect(accent.nucleus == expectedValue, "\\\(cmd) should map to Unicode \(expectedValue)")
        }
    }

    @Test func vectorArrowMultiCharacter() throws {
        let testCases = [
            ("vec", "AB"),
            ("overleftarrow", "xyz"),
            ("overrightarrow", "ABC"),
            ("overleftrightarrow", "velocity")
        ]

        for (cmd, content) in testCases {
            let str = "\\\(cmd){\(content)}"
            var error: NSError? = nil
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(cmd){\(content)}")
            #expect(error == nil, "Should not error: \(error?.localizedDescription ?? "none")")

            let accent = try #require(unwrappedList.atoms[0] as? Accent)
            let innerList = try #require(accent.innerList)
            #expect(innerList.atoms.count == content.count, "Should parse all \(content.count) characters")
        }
    }

    @Test func vectorArrowLatexRoundTrip() throws {
        let testCases = [
            ("\\vec{x}", "\\vec{x}"),
            ("\\overleftarrow{AB}", "\\overleftarrow{AB}"),
            // Note: \overrightarrow maps to same Unicode as \vec, so it converts to \vec
            ("\\overrightarrow{v}", "\\vec{v}"),
            ("\\overleftrightarrow{AC}", "\\overleftrightarrow{AC}")
        ]

        for (input, expected) in testCases {
            let list = try #require(MathListBuilder.build(fromString: input))
            let output = MathListBuilder.mathListToString(list)
            #expect(output == expected, "LaTeX round-trip failed for \(input)")
        }
    }

    @Test func vectorArrowWithScripts() throws {
        let testCases = [
            "\\vec{v}_0",
            "\\overrightarrow{AB}^2",
            "\\overleftarrow{F}_x^y",
            "\\overleftrightarrow{PQ}_{parallel}"
        ]

        for input in testCases {
            var error: NSError? = nil
            let list = MathListBuilder.build(fromString: input, error: &error)

            let unwrappedList = try #require(list, "Should parse \(input)")
            #expect(error == nil, "Should not error: \(error?.localizedDescription ?? "none")")

            let accent = try #require(unwrappedList.atoms[0] as? Accent)

            // Check for scripts
            let hasSubscript = accent.subScript != nil
            let hasSuperscript = accent.superScript != nil
            #expect(hasSubscript || hasSuperscript, "Should have at least one script for \(input)")
        }
    }

    @Test func vectorArrowInExpressions() throws {
        let testCases = [
            "$\\vec{a} \\cdot \\vec{b}$",  // Dot product
            "$\\overrightarrow{AB} + \\overrightarrow{BC}$",  // Vector addition
            "$\\overleftarrow{F} = m\\vec{a}$",  // Newton's law
            "$\\overleftrightarrow{AC} \\parallel \\overleftrightarrow{BD}$"  // Parallel lines
        ]

        for input in testCases {
            var error: NSError? = nil
            let list = MathListBuilder.build(fromString: input, error: &error)

            #expect(list != nil, "Should parse: \(input)")
            #expect(error == nil, "Should not error: \(error?.localizedDescription ?? "none")")

            // Verify at least one accent exists
            var foundAccent = false
            for atom in list!.atoms {
                if atom.type == .accent {
                    foundAccent = true
                    break
                }
            }
            #expect(foundAccent, "Should have accent in: \(input)")
        }
    }

    @Test func multiCharacterArrowAccentParsing() throws {
        // Test the reported bug: \overrightarrow{DA} should parse correctly
        let testCases = [
            ("\\overrightarrow{DA}", "DA", "\u{20D7}"),
            ("\\overleftarrow{AB}", "AB", "\u{20D6}"),
            ("\\overleftrightarrow{XY}", "XY", "\u{20E1}"),
            ("\\vec{AB}", "AB", "\u{20D7}")
        ]

        for (latex, expectedContent, expectedUnicode) in testCases {
            var error: NSError? = nil
            let list = MathListBuilder.build(fromString: latex, error: &error)

            let unwrappedList = try #require(list, "Should parse \(latex)")
            #expect(error == nil, "Should not error: \(error?.localizedDescription ?? "none")")

            // Should create single accent atom
            #expect(unwrappedList.atoms.count == 1, "Should have 1 atom for \(latex)")
            let accent = try #require(unwrappedList.atoms[0] as? Accent, "Should be Accent for \(latex)")

            // Check accent unicode value
            #expect(accent.nucleus == expectedUnicode, "\(latex) should have correct Unicode")

            // Check innerList contains all characters
            let innerList = try #require(accent.innerList, "\(latex) should have innerList")
            #expect(innerList.atoms.count == expectedContent.count, "\(latex) should have \(expectedContent.count) characters in innerList")

            // Verify each character
            for (i, expectedChar) in expectedContent.enumerated() {
                let atom = innerList.atoms[i]
                #expect(atom.nucleus == String(expectedChar), "\(latex) character \(i) should be \(expectedChar)")
            }
        }
    }

    @Test func delimiterPairs() throws {
        let delimiterPairs = [
            ("langle", "rangle"),
            ("lfloor", "rfloor"),
            ("lceil", "rceil"),
            ("lgroup", "rgroup"),
            ("{", "}")
        ]

        for (left, right) in delimiterPairs {
            var error: NSError? = nil
            let str = "$\\left\\\(left) x \\right\\\(right)$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\left\\\(left) ... \\right\\\(right)")
            #expect(error == nil, "Should not error on delimiters \\\(left)/\\\(right): \(error?.localizedDescription ?? "none")")

            // Should have an inner atom
            var foundInner = false
            for atom in unwrappedList.atoms {
                if atom.type == .inner {
                    foundInner = true
                    break
                }
            }
            #expect(foundInner, "Should create inner atom for \\left\\\(left)...\\right\\\(right)")
        }
    }

    @Test func largeOperators() throws {
        let operators = ["sum", "prod", "coprod", "int", "iint", "iiint", "oint",
                         "bigcap", "bigcup", "bigvee", "bigwedge", "bigodot", "bigoplus", "bigotimes"]

        for op in operators {
            var error: NSError? = nil
            let str = "$\\\(op)_{i=1}^{n} x_i$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(op)")
            #expect(error == nil, "Should not error on \\\(op): \(error?.localizedDescription ?? "none")")

            // Should find large operator
            var foundOp = false
            for atom in unwrappedList.atoms {
                if atom.type == .largeOperator {
                    foundOp = true
                    break
                }
            }
            #expect(foundOp, "Should find large operator for \\\(op)")
        }
    }

    @Test func arrows() throws {
        let arrows = ["leftarrow", "rightarrow", "uparrow", "downarrow", "leftrightarrow",
                      "Leftarrow", "Rightarrow", "Uparrow", "Downarrow", "Leftrightarrow",
                      "longleftarrow", "longrightarrow", "Longleftarrow", "Longrightarrow",
                      "mapsto", "nearrow", "searrow", "swarrow", "nwarrow"]

        for arrow in arrows {
            var error: NSError? = nil
            let str = "$a \\\(arrow) b$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(arrow)")
            #expect(error == nil, "Should not error on \\\(arrow): \(error?.localizedDescription ?? "none")")

            // Arrows are typically relations
            var foundArrow = false
            for atom in unwrappedList.atoms {
                if atom.type == .relation {
                    foundArrow = true
                    break
                }
            }
            #expect(foundArrow, "Should find arrow relation for \\\(arrow)")
        }
    }

    @Test func trigonometricFunctions() throws {
        let functions = ["sin", "cos", "tan", "cot", "sec", "csc",
                         "arcsin", "arccos", "arctan", "sinh", "cosh", "tanh", "coth"]

        for funcName in functions {
            var error: NSError? = nil
            let str = "$\\\(funcName) x$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(funcName)")
            #expect(error == nil, "Should not error on \\\(funcName): \(error?.localizedDescription ?? "none")")

            // Should find the function operator
            var foundFunc = false
            for atom in unwrappedList.atoms {
                if atom.type == .largeOperator {
                    foundFunc = true
                    break
                }
            }
            #expect(foundFunc, "Should find function operator for \\\(funcName)")
        }
    }

    @Test func limitOperators() throws {
        let operators = ["lim", "limsup", "liminf", "max", "min", "sup", "inf", "det", "gcd"]

        for op in operators {
            var error: NSError? = nil
            let str = "$\\\(op)_{x \\to 0} f(x)$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(op)")
            #expect(error == nil, "Should not error on \\\(op): \(error?.localizedDescription ?? "none")")

            // Should find the operator
            var foundOp = false
            for atom in unwrappedList.atoms {
                if atom.type == .largeOperator {
                    foundOp = true
                    break
                }
            }
            #expect(foundOp, "Should find limit operator for \\\(op)")
        }
    }

    @Test func specialSymbols() throws {
        let symbols = ["infty", "partial", "nabla", "prime", "hbar", "ell", "wp",
                       "Re", "Im", "top", "bot", "emptyset", "exists", "forall",
                       "neg", "angle", "triangle", "ldots", "cdots", "vdots", "ddots"]

        for sym in symbols {
            var error: NSError? = nil
            let str = "$\\\(sym)$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            let unwrappedList = try #require(list, "Should parse \\\(sym)")
            #expect(error == nil, "Should not error on \\\(sym): \(error?.localizedDescription ?? "none")")
            #expect(unwrappedList.atoms.count >= 1, "\\\(sym) should have at least one atom")
        }
    }

    @Test func logFunctions() throws {
        let logFuncs = ["log", "ln", "lg"]

        for funcName in logFuncs {
            var error: NSError? = nil
            let str = "$\\\(funcName) x$"
            let list = MathListBuilder.build(fromString: str, error: &error)

            #expect(list != nil, "Should parse \\\(funcName)")
            #expect(error == nil, "Should not error on \\\(funcName): \(error?.localizedDescription ?? "none")")
        }
    }
}
