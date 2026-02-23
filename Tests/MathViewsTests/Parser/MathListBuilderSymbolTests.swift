import Testing
@testable import MathViews
import CoreGraphics

// MARK: - Priority 1 Symbol Tests

struct MathListBuilderSymbolTests {
    @Test func greekVariants() throws {
        let variants = [
            "digamma",
            "varkappa",
            "varepsilon",
            "vartheta",
            "varpi",
            "varrho",
            "varsigma",
            "varphi",
        ]

        for variant in variants {
            let str = "$\\\(variant)$"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count >= 1, "\\\(variant) should have at least one atom")
        }
    }

    @Test func varsigmaCorrectUnicode() throws {
        let str = "\\varsigma"
        let list = try MathListBuilder.buildChecked(fromString: str)

        #expect(list.atoms.count == 1)

        // Verify it's the correct Unicode character (U+03C2, final sigma ...)
        let atom = list.atoms[0]
        #expect(
            atom.nucleus == "\u{03C2}",
            "varsigma should map to U+03C2 (final sigma \u{03C2}), not U+03C1 (rho \u{03C1})",
        )
    }

    @Test func newArrows() throws {
        let arrows = ["longmapsto", "hookrightarrow", "hookleftarrow"]

        for arrow in arrows {
            let str = "$a \\\(arrow) b$"
            let list = try MathListBuilder.buildChecked(fromString: str)

            var foundArrow = false
            for atom in list.atoms where atom.type == .relation {
                foundArrow = true
                break
            }
            #expect(foundArrow, "Should find arrow relation for \\\(arrow)")
        }
    }

    @Test func slantedInequalities() throws {
        let inequalities = ["leqslant", "geqslant"]

        for ineq in inequalities {
            let str = "$a \\\(ineq) b$"
            let list = try MathListBuilder.buildChecked(fromString: str)

            var foundRel = false
            for atom in list.atoms where atom.type == .relation {
                foundRel = true
                break
            }
            #expect(foundRel, "Should find relation for \\\(ineq)")
        }
    }

    @Test func precedenceRelations() throws {
        let relations = ["preceq", "succeq", "prec", "succ"]

        for rel in relations {
            let str = "$a \\\(rel) b$"
            let list = try MathListBuilder.buildChecked(fromString: str)

            var foundRel = false
            for atom in list.atoms where atom.type == .relation {
                foundRel = true
                break
            }
            #expect(foundRel, "Should find relation for \\\(rel)")
        }
    }

    @Test func turnstileRelations() throws {
        let relations = ["vdash", "dashv", "bowtie", "models"]

        for rel in relations {
            let str = "$a \\\(rel) b$"
            let list = try MathListBuilder.buildChecked(fromString: str)

            var foundRel = false
            for atom in list.atoms where atom.type == .relation {
                foundRel = true
                break
            }
            #expect(foundRel, "Should find relation for \\\(rel)")
        }
    }

    @Test func diamondOperator() throws {
        let str = "$a \\diamond b$"
        let list = try MathListBuilder.buildChecked(fromString: str)

        var foundOp = false
        for atom in list.atoms where atom.type == .binaryOperator {
            foundOp = true
            break
        }
        #expect(foundOp, "Should find binary operator for \\diamond")
    }

    @Test func hebrewLetters() throws {
        let letters = ["aleph", "beth", "gimel", "daleth"]

        for letter in letters {
            let str = "\\\(letter)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1, "\\\(letter) should have exactly one atom")

            let atom = list.atoms[0]
            #expect(atom.type == .ordinary, "\\\(letter) should be ordinary type")
        }
    }

    @Test func miscSymbols() throws {
        let symbols = ["varnothing", "emptyset", "Box", "measuredangle", "angle", "triangle"]

        for symbol in symbols {
            let str = "$\\\(symbol)$"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count >= 1, "\\\(symbol) should have at least one atom")
        }
    }

    @Test func mathbbCommand() throws {
        // Test that \mathbb{} command works for common letters
        let letters = ["N", "Z", "Q", "R", "C", "H", "P"]

        for letter in letters {
            let str = "\\mathbb{\(letter)}"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1, "\\mathbb{\(letter)} should have one atom")

            let atom = list.atoms[0]
            #expect(atom.nucleus == letter, "Nucleus should be \(letter)")
            #expect(atom.fontStyle == .blackboard, "Font style should be blackboard")
        }

        // Test round-trip conversion
        let str = "\\mathbb{R}"
        let list = try MathListBuilder.buildChecked(fromString: str)
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\mathbb{R}", "Should round-trip correctly")
    }

    // MARK: - Delimiter Sizing Commands Tests

    @Test func bigDelimiterCommands() throws {
        // Test \big, \Big, \bigg, \Bigg commands
        // Multipliers based on standard TeX sizing
        let sizeCommands = [
            ("big", CGFloat(1.0)),
            ("Big", CGFloat(1.4)),
            ("bigg", CGFloat(1.8)),
            ("Bigg", CGFloat(2.2)),
        ]

        for (command, expectedMultiplier) in sizeCommands {
            let str = "\\\(command)("
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1, "\\\(command)( should have one atom")

            let atom = list.atoms[0]
            #expect(atom.type == .inner, "\\\(command)( should create an inner atom")

            let inner = try #require(atom as? Inner)
            #expect(inner.leftBoundary != nil, "Should have left boundary")
            #expect(inner.leftBoundary?.nucleus == "(", "Left boundary should be (")
            #expect(inner.delimiterHeight != nil, "Should have explicit delimiter height")
            #expect(
                inner.delimiterHeight == expectedMultiplier,
                "Delimiter multiplier for \\\(command) should be \(expectedMultiplier)",
            )
        }
    }

    @Test func bigDelimiterLeftRightVariants() throws {
        // Test \bigl, \bigr, \Bigl, \Bigr, etc.
        let variants = [
            ("bigl", "(", CGFloat(1.0)),
            ("bigr", ")", CGFloat(1.0)),
            ("Bigl", "[", CGFloat(1.4)),
            ("Bigr", "]", CGFloat(1.4)),
            ("biggl", "\\{", CGFloat(1.8)),
            ("biggr", "\\}", CGFloat(1.8)),
            ("Biggl", "|", CGFloat(2.2)),
            ("Biggr", "|", CGFloat(2.2)),
        ]

        for (command, delim, expectedMultiplier) in variants {
            let str = "\\\(command)\(delim)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1, "\\\(command)\(delim) should have one atom")

            let atom = list.atoms[0]
            #expect(atom.type == .inner, "\\\(command)\(delim) should create an inner atom")

            let inner = try #require(atom as? Inner)
            #expect(inner.leftBoundary != nil, "Should have left boundary")
            #expect(inner.delimiterHeight != nil, "Should have explicit delimiter height")
            #expect(
                inner.delimiterHeight == expectedMultiplier,
                "Delimiter multiplier should be \(expectedMultiplier)",
            )
        }
    }

    @Test func bigDelimiterMiddleVariants() throws {
        // Test \bigm, \Bigm, etc. for middle delimiters like |
        let variants = [
            ("bigm", "|", CGFloat(1.0)),
            ("Bigm", "|", CGFloat(1.4)),
            ("biggm", "|", CGFloat(1.8)),
            ("Biggm", "|", CGFloat(2.2)),
        ]

        for (command, delim, expectedMultiplier) in variants {
            let str = "\\\(command)\(delim)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            let inner = try #require(list.atoms[0] as? Inner)
            #expect(
                inner.delimiterHeight == expectedMultiplier,
                "Middle delimiter multiplier should be \(expectedMultiplier)",
            )
        }
    }

    @Test func bigDelimiterMissingDelimiter() throws {
        let str = "\\big" // No delimiter following
        let error = #expect(throws: ParseError.self) {
            try MathListBuilder.buildChecked(fromString: str)
        }
        if let error {
            #expect(
                ParseErrorCase.missingDelimiter.matches(error),
                "Error should be missingDelimiter",
            )
        }
    }

    @Test func bigDelimiterInvalidDelimiter() throws {
        let str = "\\big x" // 'x' is not a valid delimiter
        let error = #expect(throws: ParseError.self) {
            try MathListBuilder.buildChecked(fromString: str)
        }
        if let error {
            #expect(
                ParseErrorCase.invalidDelimiter.matches(error),
                "Error should be invalidDelimiter",
            )
        }
    }

    @Test func bigDelimiterInExpression() throws {
        // Test \big in a larger expression: \big( x + y \big)
        let str = "\\big( x + y \\big)"
        let list = try MathListBuilder.buildChecked(fromString: str)

        // Should have: inner (big(), x, +, y, inner big)
        #expect(list.atoms.count == 5, "Should have 5 atoms")

        // First atom should be inner with big(
        let firstInner = try #require(list.atoms[0] as? Inner)
        #expect(firstInner.leftBoundary?.nucleus == "(")
        #expect(firstInner.delimiterHeight == 1.0)

        // Last atom should be inner with big)
        let lastInner = try #require(list.atoms[4] as? Inner)
        #expect(lastInner.leftBoundary?.nucleus == ")")
        #expect(lastInner.delimiterHeight == 1.0)
    }

    // MARK: - Negated Relations Tests

    @Test func negatedInequalityRelations() throws {
        let symbols: [(command: String, unicode: String)] = [
            ("nless", "\u{226E}"), // ...
            ("ngtr", "\u{226F}"), // ...
            ("nleq", "\u{2270}"), // ...
            ("ngeq", "\u{2271}"), // ...
            ("nleqslant", "\u{2A87}"), // ...
            ("ngeqslant", "\u{2A88}"), // ...
            ("lneq", "\u{2A87}"), // ...
            ("gneq", "\u{2A88}"), // ...
            ("lneqq", "\u{2268}"), // ...
            ("gneqq", "\u{2269}"), // ...
            ("lnsim", "\u{22E6}"), // ...
            ("gnsim", "\u{22E7}"), // ...
            ("lnapprox", "\u{2A89}"), // ...
            ("gnapprox", "\u{2A8A}"), // ...
        ]

        for (command, unicode) in symbols {
            let str = "\\\(command)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1)
            #expect(list.atoms[0].type == .relation)
            #expect(
                list.atoms[0].nucleus == unicode, "\\\(command) should have unicode \(unicode)",
            )
        }
    }

    @Test func negatedOrderingRelations() throws {
        let symbols: [(command: String, unicode: String)] = [
            ("nprec", "\u{2280}"), // ...
            ("nsucc", "\u{2281}"), // ...
            ("npreceq", "\u{22E0}"), // ...
            ("nsucceq", "\u{22E1}"), // ...
            ("precneqq", "\u{2AB5}"), // ...
            ("succneqq", "\u{2AB6}"), // ...
            ("precnsim", "\u{22E8}"), // ...
            ("succnsim", "\u{22E9}"), // ...
            ("precnapprox", "\u{2AB9}"), // ...
            ("succnapprox", "\u{2ABA}"), // ...
        ]

        for (command, unicode) in symbols {
            let str = "\\\(command)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1)
            #expect(list.atoms[0].type == .relation)
            #expect(
                list.atoms[0].nucleus == unicode, "\\\(command) should have unicode \(unicode)",
            )
        }
    }

    @Test func negatedSimilarityRelations() throws {
        let symbols: [(command: String, unicode: String)] = [
            ("nsim", "\u{2241}"), // ...
            ("ncong", "\u{2247}"), // ...
            ("nmid", "\u{2224}"), // ...
            ("nshortmid", "\u{2224}"), // ...
            ("nparallel", "\u{2226}"), // ...
            ("nshortparallel", "\u{2226}"), // ...
        ]

        for (command, unicode) in symbols {
            let str = "\\\(command)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1)
            #expect(list.atoms[0].type == .relation)
            #expect(
                list.atoms[0].nucleus == unicode, "\\\(command) should have unicode \(unicode)",
            )
        }
    }

    @Test func negatedSetRelations() throws {
        let symbols: [(command: String, unicode: String)] = [
            ("nsubseteq", "\u{2288}"), // ...
            ("nsupseteq", "\u{2289}"), // ...
            ("subsetneq", "\u{228A}"), // ...
            ("supsetneq", "\u{228B}"), // ...
            ("subsetneqq", "\u{2ACB}"), // ...
            ("supsetneqq", "\u{2ACC}"), // ...
            ("varsubsetneq", "\u{228A}"), // ... (variant)
            ("varsupsetneq", "\u{228B}"), // ... (variant)
            ("varsubsetneqq", "\u{2ACB}"), // ... (variant)
            ("varsupsetneqq", "\u{2ACC}"), // ... (variant)
            ("notni", "\u{220C}"), // ...
            ("nni", "\u{220C}"), // ...
        ]

        for (command, unicode) in symbols {
            let str = "\\\(command)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1)
            #expect(list.atoms[0].type == .relation)
            #expect(
                list.atoms[0].nucleus == unicode, "\\\(command) should have unicode \(unicode)",
            )
        }
    }

    @Test func negatedTriangleRelations() throws {
        let symbols: [(command: String, unicode: String)] = [
            ("ntriangleleft", "\u{22EA}"), // ...
            ("ntriangleright", "\u{22EB}"), // ...
            ("ntrianglelefteq", "\u{22EC}"), // ...
            ("ntrianglerighteq", "\u{22ED}"), // ...
        ]

        for (command, unicode) in symbols {
            let str = "\\\(command)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1)
            #expect(list.atoms[0].type == .relation)
            #expect(
                list.atoms[0].nucleus == unicode, "\\\(command) should have unicode \(unicode)",
            )
        }
    }

    @Test func negatedTurnstileRelations() throws {
        let symbols: [(command: String, unicode: String)] = [
            ("nvdash", "\u{22AC}"), // ...
            ("nvDash", "\u{22AD}"), // ...
            ("nVdash", "\u{22AE}"), // ...
            ("nVDash", "\u{22AF}"), // ...
        ]

        for (command, unicode) in symbols {
            let str = "\\\(command)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1)
            #expect(list.atoms[0].type == .relation)
            #expect(
                list.atoms[0].nucleus == unicode, "\\\(command) should have unicode \(unicode)",
            )
        }
    }

    @Test func negatedSquareSubsetRelations() throws {
        let symbols: [(command: String, unicode: String)] = [
            ("nsqsubseteq", "\u{22E2}"), // ...
            ("nsqsupseteq", "\u{22E3}"), // ...
        ]

        for (command, unicode) in symbols {
            let str = "\\\(command)"
            let list = try MathListBuilder.buildChecked(fromString: str)

            #expect(list.atoms.count == 1)
            #expect(list.atoms[0].type == .relation)
            #expect(
                list.atoms[0].nucleus == unicode, "\\\(command) should have unicode \(unicode)",
            )
        }
    }
}
