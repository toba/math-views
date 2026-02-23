import Testing
@testable import MathViews
import CoreGraphics

/// Discriminator for matching ParseError cases without comparing associated values
enum ParseErrorCase: Sendable {
    case mismatchBraces, invalidCommand, characterNotFound, missingDelimiter
    case invalidDelimiter, missingRight, missingLeft, invalidEnv, missingEnv
    case missingBegin, missingEnd, invalidNumColumns, internalError, invalidLimits

    func matches(_ error: ParseError) -> Bool {
        switch (self, error) {
            case (.mismatchBraces, .mismatchBraces): return true
            case (.invalidCommand, .invalidCommand): return true
            case (.characterNotFound, .characterNotFound): return true
            case (.missingDelimiter, .missingDelimiter): return true
            case (.invalidDelimiter, .invalidDelimiter): return true
            case (.missingRight, .missingRight): return true
            case (.missingLeft, .missingLeft): return true
            case (.invalidEnv, .invalidEnv): return true
            case (.missingEnv, .missingEnv): return true
            case (.missingBegin, .missingBegin): return true
            case (.missingEnd, .missingEnd): return true
            case (.invalidNumColumns, .invalidNumColumns): return true
            case (.internalError, .internalError): return true
            case (.invalidLimits, .invalidLimits): return true
            default: return false
        }
    }
}

//
//  MathRenderSwiftTests.swift
//  MathRenderSwiftTests
//
//  Created by Mike Griebling on 2023-01-02.
//

func checkAtomTypes(_ list: MathList?, types: [MathAtomType], desc: String) {
    if let list {
        #expect(list.atoms.count == types.count, "\(desc)")
        for i in 0 ..< list.atoms.count {
            let atom = list.atoms[i]
            #expect(atom.type == types[i], "\(desc)")
        }
    } else {
        #expect(types.isEmpty, "MathList should have no atoms!")
    }
}

struct TestRecord: Sendable, CustomTestStringConvertible {
    let build: String
    let atomType: [MathAtomType]
    let types: [MathAtomType]
    let extra: [MathAtomType]
    let result: String
    var testDescription: String { build }

    nonisolated init(
        build: String,
        atomType: [MathAtomType],
        types: [MathAtomType],
        extra: [MathAtomType] = [MathAtomType](),
        result: String,
    ) {
        self.build = build
        self.atomType = atomType
        self.types = types
        self.extra = extra
        self.result = result
    }

    nonisolated static let builderCases: [TestRecord] = [
        TestRecord(build: "x", atomType: [.variable], types: [], result: "x"),
        TestRecord(build: "1", atomType: [.number], types: [], result: "1"),
        TestRecord(build: "*", atomType: [.binaryOperator], types: [], result: "*"),
        TestRecord(build: "+", atomType: [.binaryOperator], types: [], result: "+"),
        TestRecord(build: ".", atomType: [.number], types: [], result: "."),
        TestRecord(build: "(", atomType: [.open], types: [], result: "("),
        TestRecord(build: ")", atomType: [.close], types: [], result: ")"),
        TestRecord(build: ",", atomType: [.punctuation], types: [], result: ","),
        TestRecord(build: "!", atomType: [.close], types: [], result: "!"),
        TestRecord(build: "=", atomType: [.relation], types: [], result: "="),
        TestRecord(
            build: "x+2", atomType: [.variable, .binaryOperator, .number], types: [],
            result: "x+2",
        ),
        // spaces are ignored
        TestRecord(
            build: "(2.3 * 8)",
            atomType: [.open, .number, .number, .number, .binaryOperator, .number, .close],
            types: [],
            result: "(2.3*8)",
        ),
        // braces are just for grouping
        TestRecord(
            build: "5{3+4}", atomType: [.number, .number, .binaryOperator, .number], types: [],
            result: "53+4",
        ),
        // commands
        TestRecord(
            build: "\\pi+\\theta\\geq 3",
            atomType: [.variable, .binaryOperator, .variable, .relation, .number], types: [],
            result: "\\pi +\\theta \\geq 3",
        ),
        // aliases
        TestRecord(
            build: "\\pi\\ne 5 \\land 3",
            atomType: [.variable, .relation, .number, .binaryOperator, .number], types: [],
            result: "\\pi \\neq 5\\wedge 3",
        ),
        // control space
        TestRecord(
            build: "x \\ y", atomType: [.variable, .ordinary, .variable], types: [],
            result: "x\\  y",
        ),
        // spacing
        TestRecord(
            build: "x \\quad y \\; z \\! q",
            atomType: [.variable, .space, .variable, .space, .variable, .space, .variable],
            types: [],
            result: "x\\quad y\\; z\\! q",
        ),
    ]

    nonisolated static let superScriptCases: [TestRecord] = [
        TestRecord(build: "x^2", atomType: [.variable], types: [.number], result: "x^{2}"),
        TestRecord(
            build: "x^23",
            atomType: [.variable, .number],
            types: [.number],
            result: "x^{2}3",
        ),
        TestRecord(
            build: "x^{23}", atomType: [.variable], types: [.number, .number], result: "x^{23}",
        ),
        TestRecord(
            build: "x^2^3", atomType: [.variable, .ordinary], types: [.number],
            result: "x^{2}{}^{3}",
        ),
        TestRecord(
            build: "x^{2^3}", atomType: [.variable], types: [.number], extra: [.number],
            result: "x^{2^{3}}",
        ),
        TestRecord(
            build: "x^{^2*}", atomType: [.variable], types: [.ordinary, .binaryOperator],
            extra: [.number], result: "x^{{}^{2}*}",
        ),
        TestRecord(build: "^2", atomType: [.ordinary], types: [.number], result: "{}^{2}"),
        TestRecord(build: "{}^2", atomType: [.ordinary], types: [.number], result: "{}^{2}"),
        TestRecord(
            build: "x^^2",
            atomType: [.variable, .ordinary],
            types: [],
            result: "x^{}{}^{2}",
        ),
        TestRecord(build: "5{x}^2", atomType: [.number, .variable], types: [], result: "5x^{2}"),
    ]

    nonisolated static let subScriptCases: [TestRecord] = [
        TestRecord(build: "x_2", atomType: [.variable], types: [.number], result: "x_{2}"),
        TestRecord(
            build: "x_23",
            atomType: [.variable, .number],
            types: [.number],
            result: "x_{2}3",
        ),
        TestRecord(
            build: "x_{23}", atomType: [.variable], types: [.number, .number], result: "x_{23}",
        ),
        TestRecord(
            build: "x_2_3", atomType: [.variable, .ordinary], types: [.number],
            result: "x_{2}{}_{3}",
        ),
        TestRecord(
            build: "x_{2_3}", atomType: [.variable], types: [.number], extra: [.number],
            result: "x_{2_{3}}",
        ),
        TestRecord(
            build: "x_{_2*}", atomType: [.variable], types: [.ordinary, .binaryOperator],
            extra: [.number], result: "x_{{}_{2}*}",
        ),
        TestRecord(build: "_2", atomType: [.ordinary], types: [.number], result: "{}_{2}"),
        TestRecord(build: "{}_2", atomType: [.ordinary], types: [.number], result: "{}_{2}"),
        TestRecord(
            build: "x__2",
            atomType: [.variable, .ordinary],
            types: [],
            result: "x_{}{}_{2}",
        ),
        TestRecord(build: "5{x}_2", atomType: [.number, .variable], types: [], result: "5x_{2}"),
    ]

    nonisolated static let superSubScriptCases: [TestRecord] = [
        TestRecord(
            build: "x_2^*", atomType: [.variable], types: [.number], extra: [.binaryOperator],
            result: "x^{*}_{2}",
        ),
        TestRecord(
            build: "x^*_2", atomType: [.variable], types: [.number], extra: [.binaryOperator],
            result: "x^{*}_{2}",
        ),
        TestRecord(
            build: "x_^*", atomType: [.variable], types: [], extra: [.binaryOperator],
            result: "x^{*}_{}",
        ),
        TestRecord(build: "x^_2", atomType: [.variable], types: [.number], result: "x^{}_{2}"),
        TestRecord(build: "x_{2^*}", atomType: [.variable], types: [.number], result: "x_{2^{*}}"),
        TestRecord(
            build: "x^{*_2}", atomType: [.variable], types: [], extra: [.binaryOperator],
            result: "x^{*_{2}}",
        ),
        TestRecord(
            build: "_2^*", atomType: [.ordinary], types: [.number], extra: [.binaryOperator],
            result: "{}^{*}_{2}",
        ),
    ]
}

struct TestRecord2: Sendable, CustomTestStringConvertible {
    let build: String
    let type1: [MathAtomType]
    let number: Int
    let type2: [MathAtomType]
    let left: String
    let right: String
    let result: String
    var testDescription: String { build }

    nonisolated static let leftRightCases: [TestRecord2] = [
        TestRecord2(
            build: "\\left( 2 \\right)", type1: [.inner], number: 0, type2: [.number], left: "(",
            right: ")", result: "\\left( 2\\right) ",
        ),
        // spacing
        TestRecord2(
            build: "\\left ( 2 \\right )", type1: [.inner], number: 0, type2: [.number], left: "(",
            right: ")", result: "\\left( 2\\right) ",
        ),
        // commands
        TestRecord2(
            build: "\\left\\{ 2 \\right\\}", type1: [.inner], number: 0, type2: [.number],
            left: "{",
            right: "}", result: "\\left\\{ 2\\right\\} ",
        ),
        // complex commands
        TestRecord2(
            build: "\\left\\langle x \\right\\rangle", type1: [.inner], number: 0,
            type2: [.variable],
            left: "\u{2329}", right: "\u{232A}", result: "\\left< x\\right> ",
        ),
        // bars
        TestRecord2(
            build: "\\left| x \\right\\|", type1: [.inner], number: 0, type2: [.variable],
            left: "|",
            right: "\u{2016}", result: "\\left| x\\right\\| ",
        ),
        // inner in between
        TestRecord2(
            build: "5 + \\left( 2 \\right) - 2",
            type1: [.number, .binaryOperator, .inner, .binaryOperator, .number], number: 2,
            type2: [.number], left: "(", right: ")", result: "5+\\left( 2\\right) -2",
        ),
        // long inner
        TestRecord2(
            build: "\\left( 2 + \\frac12\\right)", type1: [.inner], number: 0,
            type2: [.number, .binaryOperator, .fraction], left: "(", right: ")",
            result: "\\left( 2+\\frac{1}{2}\\right) ",
        ),
        // nested
        TestRecord2(
            build: "\\left[ 2 + \\left|\\frac{-x}{2}\\right| \\right]", type1: [.inner], number: 0,
            type2: [.number, .binaryOperator, .inner], left: "[", right: "]",
            result: "\\left[ 2+\\left| \\frac{-x}{2}\\right| \\right] ",
        ),
        // With scripts
        TestRecord2(
            build: "\\left( 2 \\right)^2", type1: [.inner], number: 0, type2: [.number], left: "(",
            right: ")", result: "\\left( 2\\right) ^{2}",
        ),
        // Scripts on left
        TestRecord2(
            build: "\\left(^2 \\right )", type1: [.inner], number: 0, type2: [.ordinary], left: "(",
            right: ")", result: "\\left( {}^{2}\\right) ",
        ),
        // Dot
        TestRecord2(
            build: "\\left( 2 \\right.", type1: [.inner], number: 0, type2: [.number], left: "(",
            right: "", result: "\\left( 2\\right. ",
        ),
    ]
}

struct ParseErrorRecord: Sendable, CustomTestStringConvertible {
    let input: String
    let expectedError: ParseErrorCase
    var testDescription: String { input }

    nonisolated static let parseErrorCases: [ParseErrorRecord] = [
        ParseErrorRecord(input: "}a", expectedError: .mismatchBraces),
        ParseErrorRecord(input: "\\notacommand", expectedError: .invalidCommand),
        ParseErrorRecord(input: "\\sqrt[5+3", expectedError: .characterNotFound),
        ParseErrorRecord(input: "{5+3", expectedError: .mismatchBraces),
        ParseErrorRecord(input: "5+3}", expectedError: .mismatchBraces),
        ParseErrorRecord(input: "{1+\\frac{3+2", expectedError: .mismatchBraces),
        ParseErrorRecord(input: "1+\\left", expectedError: .missingDelimiter),
        ParseErrorRecord(input: "\\left(\\frac12\\right", expectedError: .missingDelimiter),
        ParseErrorRecord(input: "\\left 5 + 3 \\right)", expectedError: .invalidDelimiter),
        ParseErrorRecord(input: "\\left(\\frac12\\right + 3", expectedError: .invalidDelimiter),
        ParseErrorRecord(
            input: "\\left\\lmoustache 5 + 3 \\right)",
            expectedError: .invalidDelimiter,
        ),
        ParseErrorRecord(
            input: "\\left(\\frac12\\right\\rmoustache + 3", expectedError: .invalidDelimiter,
        ),
        ParseErrorRecord(input: "5 + 3 \\right)", expectedError: .missingLeft),
        ParseErrorRecord(input: "\\left(\\frac12", expectedError: .missingRight),
        ParseErrorRecord(
            input: "\\left(5 + \\left| \\frac12 \\right)",
            expectedError: .missingRight,
        ),
        ParseErrorRecord(input: "5+ \\left|\\frac12\\right| \\right)", expectedError: .missingLeft),
        ParseErrorRecord(input: "\\begin matrix \\end matrix",
                         expectedError: .characterNotFound), // missing {
        ParseErrorRecord(input: "\\begin", expectedError: .characterNotFound), // missing {
        ParseErrorRecord(input: "\\begin{", expectedError: .characterNotFound), // missing }
        ParseErrorRecord(input: "\\begin{matrix parens}",
                         expectedError: .characterNotFound), // missing } (no spaces in env)
        ParseErrorRecord(input: "\\begin{matrix} x", expectedError: .missingEnd),
        ParseErrorRecord(input: "\\begin{matrix} x \\end",
                         expectedError: .characterNotFound), // missing {
        ParseErrorRecord(input: "\\begin{matrix} x \\end + 3",
                         expectedError: .characterNotFound), // missing {
        ParseErrorRecord(input: "\\begin{matrix} x \\end{",
                         expectedError: .characterNotFound), // missing }
        ParseErrorRecord(
            input: "\\begin{matrix} x \\end{matrix + 3",
            expectedError: .characterNotFound,
        ), // missing }
        ParseErrorRecord(input: "\\begin{matrix} x \\end{pmatrix}", expectedError: .invalidEnv),
        ParseErrorRecord(input: "x \\end{matrix}", expectedError: .missingBegin),
        ParseErrorRecord(input: "\\begin{notanenv} x \\end{notanenv}", expectedError: .invalidEnv),
        ParseErrorRecord(
            input: "\\begin{matrix} \\notacommand \\end{matrix}", expectedError: .invalidCommand,
        ),
        ParseErrorRecord(
            input: "\\begin{displaylines} x & y \\end{displaylines}",
            expectedError: .invalidNumColumns,
        ),
        // eqalign/aligned now allow any number of columns (matching KaTeX)
        // Only split is limited to max 2 columns
        ParseErrorRecord(
            input: "\\begin{split} a & b & c \\end{split}", expectedError: .invalidNumColumns,
        ),
        ParseErrorRecord(input: "\\nolimits", expectedError: .invalidLimits),
        ParseErrorRecord(input: "\\frac\\limits{1}{2}", expectedError: .invalidLimits),
        ParseErrorRecord(input: "&\\begin", expectedError: .characterNotFound),
        ParseErrorRecord(input: "x & y \\\\ z & w \\end{matrix}", expectedError: .invalidEnv),
    ]
}

struct MathListBuilderTests {
    @Test(arguments: TestRecord.builderCases)
    func builder(_ testCase: TestRecord) throws {
        let str = testCase.build
        let list = try MathListBuilder.buildChecked(fromString: str)
        let desc = "Error for string:\(str)"
        let atomTypes = testCase.atomType
        checkAtomTypes(list, types: atomTypes, desc: desc)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == testCase.result, "\(desc)")
    }

    @Test(arguments: TestRecord.superScriptCases)
    func superScript(_ testCase: TestRecord) throws {
        let str = testCase.build
        let list = try MathListBuilder.buildChecked(fromString: str)
        let desc = "Error for string:\(str)"
        let atomTypes = testCase.atomType
        checkAtomTypes(list, types: atomTypes, desc: desc)

        // get the first atom
        let first = list.atoms[0]
        // check it's superscript
        let types = testCase.types
        if !types.isEmpty {
            #expect(first.superScript != nil, "\(desc)")
        }
        let superlist = first.superScript
        checkAtomTypes(superlist, types: types, desc: desc)

        if !testCase.extra.isEmpty {
            // one more level
            let superFirst = try #require(superlist?.atoms[0])
            let supersuperList = superFirst.superScript
            checkAtomTypes(supersuperList, types: testCase.extra, desc: desc)
        }

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == testCase.result, "\(desc)")
    }

    @Test(arguments: TestRecord.subScriptCases)
    func subScript(_ testCase: TestRecord) throws {
        let str = testCase.build
        let list = try MathListBuilder.buildChecked(fromString: str)
        let desc = "Error for string:\(str)"
        let atomTypes = testCase.atomType
        checkAtomTypes(list, types: atomTypes, desc: desc)

        // get the first atom
        let first = list.atoms[0]
        // check it's subscript
        let types = testCase.types
        if !types.isEmpty {
            #expect(first.subScript != nil, "\(desc)")
        }
        let sublist = first.subScript
        checkAtomTypes(sublist, types: types, desc: desc)

        if !testCase.extra.isEmpty {
            // one more level
            let subFirst = try #require(sublist?.atoms[0])
            let subsubList = subFirst.subScript
            checkAtomTypes(subsubList, types: testCase.extra, desc: desc)
        }

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == testCase.result, "\(desc)")
    }

    @Test(arguments: TestRecord.superSubScriptCases)
    func superSubScript(_ testCase: TestRecord) throws {
        let str = testCase.build
        let list = try MathListBuilder.buildChecked(fromString: str)
        let desc = "Error for string:\(str)"
        let atomTypes = testCase.atomType
        checkAtomTypes(list, types: atomTypes, desc: desc)

        // get the first atom
        let first = list.atoms[0]
        // check its subscript
        let sub = testCase.types
        if !sub.isEmpty {
            #expect(first.subScript != nil, "\(desc)")
            let sublist = first.subScript
            checkAtomTypes(sublist, types: sub, desc: desc)
        }
        let sup = testCase.extra
        if !sup.isEmpty {
            #expect(first.superScript != nil, "\(desc)")
            let sublist = first.superScript
            checkAtomTypes(sublist, types: sup, desc: desc)
        }

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == testCase.result, "\(desc)")
    }

    @Test func symbols() throws {
        let str = "5\\times3^{2\\div2}"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 3, "desc")
        var atom = list.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "5", "\(desc)")
        atom = list.atoms[1]
        #expect(atom.type == .binaryOperator, "\(desc)")
        #expect(atom.nucleus == "\u{00D7}", "\(desc)")
        atom = list.atoms[2]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "3", "\(desc)")

        // super script
        let superList = try #require(atom.superScript)
        #expect((superList.atoms.count) == 3, "desc")
        atom = superList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "2", "\(desc)")
        atom = superList.atoms[1]
        #expect(atom.type == .binaryOperator, "\(desc)")
        #expect(atom.nucleus == "\u{00F7}", "\(desc)")
        atom = superList.atoms[2]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "2", "\(desc)")
    }

    @Test func amsSymbBinaryOperators() throws {
        // Test additional amssymb binary operators
        // Note: bowtie is a relation, not a binary operator
        let testCases: [(String, String, String)] = [
            ("\\ltimes", "ltimes", "\u{22C9}"),
            ("\\rtimes", "rtimes", "\u{22CA}"),
            ("\\circledast", "circledast", "\u{229B}"),
            ("\\circledcirc", "circledcirc", "\u{229A}"),
            ("\\circleddash", "circleddash", "\u{229D}"),
            ("\\boxdot", "boxdot", "\u{22A1}"),
            ("\\boxminus", "boxminus", "\u{229F}"),
            ("\\boxplus", "boxplus", "\u{229E}"),
            ("\\boxtimes", "boxtimes", "\u{22A0}"),
            ("\\divideontimes", "divideontimes", "\u{22C7}"),
            ("\\dotplus", "dotplus", "\u{2214}"),
            ("\\lhd", "lhd", "\u{22B2}"),
            ("\\rhd", "rhd", "\u{22B3}"),
            ("\\unlhd", "unlhd", "\u{22B4}"),
            ("\\unrhd", "unrhd", "\u{22B5}"),
            ("\\intercal", "intercal", "\u{22BA}"),
            ("\\barwedge", "barwedge", "\u{22BC}"),
            ("\\veebar", "veebar", "\u{22BB}"),
            ("\\curlywedge", "curlywedge", "\u{22CF}"),
            ("\\curlyvee", "curlyvee", "\u{22CE}"),
            ("\\doublebarwedge", "doublebarwedge", "\u{2A5E}"),
            ("\\centerdot", "centerdot", "\u{22C5}"),
        ]

        for (latex, name, expected) in testCases {
            let str = "a\(latex) b" // space after command to terminate it
            let list = try MathListBuilder.buildChecked(fromString: str)
            let desc = "Error for \(name)"
            #expect(list.atoms.count == 3, "\(desc)")

            let atom = list.atoms[1]
            #expect(atom.type == .binaryOperator, "\(desc)")
            #expect(atom.nucleus == expected, "\(desc)")
        }
    }

    @Test func cornerBracketDelimiters() throws {
        // Test corner bracket delimiters (amssymb)
        let testCases: [(String, String, String, String)] = [
            ("\\left\\ulcorner x \\right\\urcorner", "ulcorner-urcorner", "\u{231C}", "\u{231D}"),
            ("\\left\\llcorner x \\right\\lrcorner", "llcorner-lrcorner", "\u{231E}", "\u{231F}"),
            (
                "\\left\\llbracket x \\right\\rrbracket",
                "llbracket-rrbracket",
                "\u{27E6}",
                "\u{27E7}",
            ),
        ]

        for (latex, name, expectedLeft, expectedRight) in testCases {
            let list = try MathListBuilder.buildChecked(fromString: latex)
            let inner = list.atoms[0] as? Inner
            #expect(inner != nil, "Should have Inner for \(name)")

            #expect(inner?.leftBoundary?.nucleus == expectedLeft, "Left delimiter for \(name)")
            #expect(inner?.rightBoundary?.nucleus == expectedRight, "Right delimiter for \(name)")
        }
    }

    @Test func additionalTrigFunctions() throws {
        // Test additional trig/hyperbolic functions
        let functions = [
            "arccot", "arcsec", "arccsc", // inverse trig
            "sech", "csch", // hyperbolic
            "arcsinh", "arccosh", "arctanh", "arccoth", "arcsech", "arccsch", // inverse hyperbolic
        ]

        for func_ in functions {
            let str = "\\\(func_) x"
            let list = try MathListBuilder.buildChecked(fromString: str)
            let desc = "Error for \\\(func_)"

            #expect(list.atoms.count == 2, "\(desc)")
            let op = list.atoms[0] as? LargeOperator
            #expect(op != nil, "Should be LargeOperator for \\\(func_)")
            #expect(op?.nucleus == func_, "Nucleus should be \(func_)")
        }
    }

    @Test func frac() throws {
        let str = "\\frac1c"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(frac.hasRule)
        #expect(frac.rightDelimiter.isEmpty)
        #expect(frac.leftDelimiter.isEmpty)

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "1", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "c", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\frac{1}{c}", "\(desc)")
    }

    @Test func fracInFrac() throws {
        let str = "\\frac1\\frac23"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        var frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(frac.hasRule)

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "1", "\(desc)")

        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        frac = try #require(subList.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")

        subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "2", "\(desc)")

        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "3", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\frac{1}{\\frac{2}{3}}", "\(desc)")
    }

    @Test func sqrt() throws {
        let str = "\\sqrt2"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let rad = try #require(list.atoms[0] as? Radical)
        #expect(rad.type == .radical, "\(desc)")
        #expect(rad.nucleus.isEmpty, "\(desc)")

        let subList = try #require(rad.radicand)
        #expect((subList.atoms.count) == 1, "desc")
        let atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "2", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sqrt{2}", "\(desc)")
    }

    @Test func sqrtInSqrt() throws {
        let str = "\\sqrt\\sqrt2"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        var rad = try #require(list.atoms[0] as? Radical)
        #expect(rad.type == .radical, "\(desc)")
        #expect(rad.nucleus.isEmpty, "\(desc)")

        var subList = try #require(rad.radicand)
        #expect((subList.atoms.count) == 1, "desc")
        rad = try #require(subList.atoms[0] as? Radical)
        #expect(rad.type == .radical, "\(desc)")
        #expect(rad.nucleus.isEmpty, "\(desc)")

        subList = try #require(rad.radicand)
        #expect((subList.atoms.count) == 1, "desc")
        let atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "2", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sqrt{\\sqrt{2}}", "\(desc)")
    }

    @Test func rad() throws {
        let str = "\\sqrt[3]2"
        let list = try #require(MathListBuilder.build(fromString: str))

        #expect((list.atoms.count) == 1)
        let rad = try #require(list.atoms[0] as? Radical)
        #expect(rad.type == .radical)
        #expect(rad.nucleus.isEmpty)

        var subList = try #require(rad.radicand)
        #expect((subList.atoms.count) == 1)
        var atom = subList.atoms[0]
        #expect(atom.type == .number)
        #expect(atom.nucleus == "2")

        subList = try #require(rad.degree)
        #expect((subList.atoms.count) == 1)
        atom = subList.atoms[0]
        #expect(atom.type == .number)
        #expect(atom.nucleus == "3")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sqrt[3]{2}")
    }

    @Test func sqrtWithoutRadicand() throws {
        let str = "\\sqrt"
        let list = try #require(MathListBuilder.build(fromString: str))

        #expect(list.atoms.count == 1)
        let rad = try #require(list.atoms.first as? Radical)
        #expect(rad.type == .radical)
        #expect(rad.nucleus.isEmpty)

        #expect(rad.radicand?.atoms.isEmpty == true)
        #expect(rad.degree == nil)

        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sqrt{}")
    }

    @Test func sqrtWithDegreeWithoutRadicand() throws {
        let str = "\\sqrt[3]"
        let list = try #require(MathListBuilder.build(fromString: str))

        #expect(list.atoms.count == 1)
        let rad = try #require(list.atoms.first as? Radical)
        #expect(rad.type == .radical)
        #expect(rad.nucleus.isEmpty)

        #expect(rad.radicand?.atoms.isEmpty == true)

        let subList = try #require(rad.degree)
        #expect(subList.atoms.count == 1)
        let atom = try #require(subList.atoms.first)
        #expect(atom.type == .number)
        #expect(atom.nucleus == "3")

        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sqrt[3]{}")
    }

    @Test(arguments: TestRecord2.leftRightCases)
    func leftRight(_ testCase: TestRecord2) throws {
        let str = testCase.build

        let list = try MathListBuilder.buildChecked(fromString: str)

        checkAtomTypes(list, types: testCase.type1, desc: "\(str) outer")

        let innerLoc = testCase.number
        let inner = try #require(list.atoms[innerLoc] as? Inner)
        #expect(inner.type == .inner, "\(str)")
        #expect(inner.nucleus.isEmpty, "\(str)")

        let innerList = try #require(inner.innerList)
        checkAtomTypes(innerList, types: testCase.type2, desc: "\(str) inner")

        #expect(inner.leftBoundary != nil, "\(str)")
        #expect(inner.leftBoundary?.type == .boundary, "\(str)")
        #expect(inner.leftBoundary?.nucleus == testCase.left, "\(str)")

        #expect(inner.rightBoundary != nil, "\(str)")
        #expect(inner.rightBoundary?.type == .boundary, "\(str)")
        #expect(inner.rightBoundary?.nucleus == testCase.right, "\(str)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == testCase.result, "\(str)")
    }

    @Test func over() throws {
        let str = "1 \\over c"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(frac.hasRule)
        #expect(frac.rightDelimiter.isEmpty)
        #expect(frac.leftDelimiter.isEmpty)

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "1", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "c", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\frac{1}{c}", "\(desc)")
    }

    @Test func overInParens() throws {
        let str = "5 + {1 \\over c} + 8"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 5, "desc")
        let types = [MathAtomType.number, .binaryOperator, .fraction, .binaryOperator, .number]
        checkAtomTypes(list, types: types, desc: desc)

        let frac = try #require(list.atoms[2] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(frac.hasRule)
        #expect(frac.rightDelimiter.isEmpty)
        #expect(frac.leftDelimiter.isEmpty)

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "1", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "c", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "5+\\frac{1}{c}+8", "\(desc)")
    }

    @Test func atop() throws {
        let str = "1 \\atop c"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(!(frac.hasRule))
        #expect(frac.rightDelimiter.isEmpty)
        #expect(frac.leftDelimiter.isEmpty)

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "1", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "c", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "{1 \\atop c}", "\(desc)")
    }

    @Test func atopInParens() throws {
        let str = "5 + {1 \\atop c} + 8"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 5, "desc")
        let types = [MathAtomType.number, .binaryOperator, .fraction, .binaryOperator, .number]
        checkAtomTypes(list, types: types, desc: desc)

        let frac = try #require(list.atoms[2] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(!(frac.hasRule))
        #expect(frac.rightDelimiter.isEmpty)
        #expect(frac.leftDelimiter.isEmpty)

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "1", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "c", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "5+{1 \\atop c}+8", "\(desc)")
    }

    @Test func choose() throws {
        let str = "n \\choose k"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(!(frac.hasRule))
        #expect(frac.rightDelimiter == ")")
        #expect(frac.leftDelimiter == "(")

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "n", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "k", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "{n \\choose k}", "\(desc)")
    }

    @Test func brack() throws {
        let str = "n \\brack k"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(!(frac.hasRule))
        #expect(frac.rightDelimiter == "]")
        #expect(frac.leftDelimiter == "[")

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "n", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "k", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "{n \\brack k}", "\(desc)")
    }

    @Test func brace() throws {
        let str = "n \\brace k"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(!(frac.hasRule))
        #expect(frac.rightDelimiter == "}")
        #expect(frac.leftDelimiter == "{")

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "n", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "k", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "{n \\brace k}", "\(desc)")
    }

    @Test func binom() throws {
        let str = "\\binom{n}{k}"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let frac = try #require(list.atoms[0] as? Fraction)
        #expect(frac.type == .fraction, "\(desc)")
        #expect(frac.nucleus.isEmpty, "\(desc)")
        #expect(!(frac.hasRule))
        #expect(frac.rightDelimiter == ")")
        #expect(frac.leftDelimiter == "(")

        var subList = try #require(frac.numerator)
        #expect((subList.atoms.count) == 1, "desc")
        var atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "n", "\(desc)")

        atom = list.atoms[0]
        subList = try #require(frac.denominator)
        #expect((subList.atoms.count) == 1, "desc")
        atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "k", "\(desc)")

        // convert it back to latex (binom converts to choose)
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "{n \\choose k}", "\(desc)")
    }

    @Test func overLine() throws {
        let str = "\\overline 2"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let over = try #require(list.atoms[0] as? Overline)
        #expect(over.type == .overline, "\(desc)")
        #expect(over.nucleus.isEmpty, "\(desc)")

        let subList = try #require(over.innerList)
        #expect((subList.atoms.count) == 1, "desc")
        let atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "2", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\overline{2}", "\(desc)")
    }

    @Test func underline() throws {
        let str = "\\underline 2"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let under = try #require(list.atoms[0] as? Underline)
        #expect(under.type == .underline, "\(desc)")
        #expect(under.nucleus.isEmpty, "\(desc)")

        let subList = try #require(under.innerList)
        #expect((subList.atoms.count) == 1, "desc")
        let atom = subList.atoms[0]
        #expect(atom.type == .number, "\(desc)")
        #expect(atom.nucleus == "2", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\underline{2}", "\(desc)")
    }

    @Test func accent() throws {
        let str = "\\bar x"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let accent = try #require(list.atoms[0] as? Accent)
        #expect(accent.type == .accent, "\(desc)")
        #expect(accent.nucleus == "\u{0304}", "\(desc)")

        let subList = try #require(accent.innerList)
        #expect((subList.atoms.count) == 1, "desc")
        let atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "x", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\bar{x}", "\(desc)")
    }

    @Test func accentedCharacter() throws {
        let str = "á"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let accent = try #require(list.atoms[0] as? Accent)
        #expect(accent.type == .accent, "\(desc)")
        #expect(accent.nucleus == "\u{0301}", "\(desc)")

        let subList = try #require(accent.innerList)
        #expect((subList.atoms.count) == 1, "desc")
        let atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "a", "\(desc)")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\acute{a}", "\(desc)")
    }

    @Test func mathSpace() throws {
        let str = "\\!"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        let space = try #require(list.atoms[0] as? MathSpace)
        #expect(space.type == .space, "\(desc)")
        #expect(space.nucleus.isEmpty, "\(desc)")
        #expect(space.space == -3)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\! ", "\(desc)")
    }

    @Test func mathStyle() throws {
        let str = "\\textstyle y \\scriptstyle x"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 4, "desc")
        let style = try #require(list.atoms[0] as? MathStyle)
        #expect(style.type == .style, "\(desc)")
        #expect(style.nucleus.isEmpty, "\(desc)")
        #expect(style.style == .text)

        let style2 = try #require(list.atoms[2] as? MathStyle)
        #expect(style2.type == .style, "\(desc)")
        #expect(style2.nucleus.isEmpty, "\(desc)")
        #expect(style2.style == .script)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\textstyle y\\scriptstyle x", "\(desc)")
    }

    @Test func matrix() throws {
        let str = "\\begin{matrix} x & y \\\\ z & w \\end{matrix}"
        let list = try #require(MathListBuilder.build(fromString: str))

        #expect((list.atoms.count) == 1)
        let table = try #require(list.atoms[0] as? MathTable)
        #expect(table.type == .table)
        #expect(table.nucleus.isEmpty)
        #expect(table.environment == "matrix")
        #expect(table.interRowAdditionalSpacing == 0)
        #expect(table.interColumnSpacing == 18)
        #expect(table.numRows == 2)
        #expect(table.numColumns == 2)

        for i in 0 ..< 2 {
            let alignment = table.alignment(forColumn: i)
            #expect(alignment == .center)
            for j in 0 ..< 2 {
                let cell = table.cells[j][i]
                #expect(cell.atoms.count == 2)
                let style = try #require(cell.atoms[0] as? MathStyle)
                #expect(style.type == .style)
                #expect(style.style == .text)

                let atom = cell.atoms[1]
                #expect(atom.type == .variable)
            }
        }

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\begin{matrix}x&y\\\\ z&w\\end{matrix}")
    }

    @Test func pMatrix() throws {
        let str = "\\begin{pmatrix} x & y \\\\ z & w \\end{pmatrix}"
        let list = try #require(MathListBuilder.build(fromString: str))

        #expect((list.atoms.count) == 1)
        let inner = try #require(list.atoms[0] as? Inner)
        #expect(inner.type == .inner, "\(str)")
        #expect(inner.nucleus.isEmpty, "\(str)")

        let innerList = try #require(inner.innerList)

        #expect(inner.leftBoundary != nil, "\(str)")
        #expect(inner.leftBoundary?.type == .boundary, "\(str)")
        #expect(inner.leftBoundary?.nucleus == "(", "\(str)")

        #expect(inner.rightBoundary != nil, "\(str)")
        #expect(inner.rightBoundary?.type == .boundary, "\(str)")
        #expect(inner.rightBoundary?.nucleus == ")", "str")

        #expect((innerList.atoms.count) == 1)
        let table = try #require(innerList.atoms[0] as? MathTable)
        #expect(table.type == .table)
        #expect(table.nucleus.isEmpty)
        #expect(table.environment == "matrix")
        #expect(table.interRowAdditionalSpacing == 0)
        #expect(table.interColumnSpacing == 18)
        #expect(table.numRows == 2)
        #expect(table.numColumns == 2)

        for i in 0 ..< 2 {
            let alignment = table.alignment(forColumn: i)
            #expect(alignment == .center)
            for j in 0 ..< 2 {
                let cell = table.cells[j][i]
                #expect(cell.atoms.count == 2)
                let style = try #require(cell.atoms[0] as? MathStyle)
                #expect(style.type == .style)
                #expect(style.style == .text)

                let atom = cell.atoms[1]
                #expect(atom.type == .variable)
            }
        }

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\left( \\begin{matrix}x&y\\\\ z&w\\end{matrix}\\right) ")
    }

    @Test func defaultTable() throws {
        let str = "x \\\\ y"
        let list = try #require(MathListBuilder.build(fromString: str))

        #expect(list.atoms.count == 1)
        let table = try #require(list.atoms[0] as? MathTable)
        #expect(table.type == .table)
        #expect(table.nucleus.isEmpty)
        #expect(table.environment.isEmpty)
        #expect(table.interRowAdditionalSpacing == 1)
        #expect(table.interColumnSpacing == 0)
        #expect(table.numRows == 2)
        #expect(table.numColumns == 1)

        for i in 0 ..< 1 {
            let alignment = table.alignment(forColumn: i)
            #expect(alignment == .left)
            for j in 0 ..< 2 {
                let cell = table.cells[j][i]
                #expect(cell.atoms.count == 1)
                let atom = cell.atoms[0]
                #expect(atom.type == .variable)
            }
        }

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "x\\\\ y")
    }

    @Test func defaultTableWithCols() throws {
        let str = "x & y \\\\ z & w"
        let list = try #require(MathListBuilder.build(fromString: str))

        #expect((list.atoms.count) == 1)
        let table = try #require(list.atoms[0] as? MathTable)
        #expect(table.type == .table)
        #expect(table.nucleus.isEmpty)
        #expect(table.environment.isEmpty)
        #expect(table.interRowAdditionalSpacing == 1)
        #expect(table.interColumnSpacing == 0)
        #expect(table.numRows == 2)
        #expect(table.numColumns == 2)

        for i in 0 ..< 2 {
            let alignment = table.alignment(forColumn: i)
            #expect(alignment == .left)
            for j in 0 ..< 2 {
                let cell = table.cells[j][i]
                #expect(cell.atoms.count == 1)
                let atom = cell.atoms[0]
                #expect(atom.type == .variable)
            }
        }

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "x&y\\\\ z&w")
    }

    @Test func eqalign() throws {
        let str1 = "\\begin{eqalign}x&y\\\\ z&w\\end{eqalign}"
        let str2 = "\\begin{split}x&y\\\\ z&w\\end{split}"
        let str3 = "\\begin{aligned}x&y\\\\ z&w\\end{aligned}"
        for str in [str1, str2, str3] {
            let list = try #require(MathListBuilder.build(fromString: str))

            #expect((list.atoms.count) == 1)
            let table = try #require(list.atoms[0] as? MathTable)
            #expect(table.type == .table)
            #expect(table.nucleus.isEmpty)
            #expect(table.interRowAdditionalSpacing == 1)
            #expect(table.interColumnSpacing == 0)
            #expect(table.numRows == 2)
            #expect(table.numColumns == 2)

            for i in 0 ..< 2 {
                let alignment = table.alignment(forColumn: i)
                #expect(alignment == ((i == 0) ? .right : .left))
                for j in 0 ..< 2 {
                    let cell = table.cells[j][i]
                    if i == 0 {
                        #expect(cell.atoms.count == 1)
                        let atom = cell.atoms[0]
                        #expect(atom.type == .variable)
                    } else {
                        #expect(cell.atoms.count == 2)
                        checkAtomTypes(cell, types: [.ordinary, .variable], desc: str)
                    }
                }
            }

            // convert it back to latex
            let latex = MathListBuilder.mathListToString(list)
            #expect(latex == str)
        }
    }

    @Test func displayLines() throws {
        let str1 = "\\begin{displaylines}x\\\\ y\\end{displaylines}"
        let str2 = "\\begin{gather}x\\\\ y\\end{gather}"
        for str in [str1, str2] {
            let list = MathListBuilder.build(fromString: str)

            #expect(list != nil)
            #expect(list?.atoms.count == 1)
            let table = try #require(list?.atoms[0] as? MathTable)
            #expect(table.type == .table)
            #expect(table.nucleus.isEmpty)
            #expect(table.interRowAdditionalSpacing == 1)
            #expect(table.interColumnSpacing == 0)
            #expect(table.numRows == 2)
            #expect(table.numColumns == 1)

            for i in 0 ..< 1 {
                let alignment = table.alignment(forColumn: i)
                #expect(alignment == .center)
                for j in 0 ..< 2 {
                    let cell = table.cells[j][i]
                    #expect(cell.atoms.count == 1)
                    let atom = cell.atoms[0]
                    #expect(atom.type == .variable)
                }
            }

            // convert it back to latex
            let latex = MathListBuilder.mathListToString(list)
            #expect(latex == str)
        }
    }

    @Test(arguments: ParseErrorRecord.parseErrorCases)
    func errors(_ testCase: ParseErrorRecord) {
        let str = testCase.input
        let list = MathListBuilder.build(fromString: str)
        #expect(list == nil, "Should have error for: \(str)")
        // Verify the error case matches using the throwing API
        do {
            _ = try MathListBuilder.buildChecked(fromString: str)
            Issue.record("Expected error for \(str)")
        } catch {
            let expectedCase = testCase.expectedError
            #expect(
                expectedCase.matches(error),
                "\(str): expected \(expectedCase) but got \(error)",
            )
        }
    }

    @Test func custom() throws {
        let str = "\\lcm(a,b)"
        let failedList = MathListBuilder.build(fromString: str)
        #expect(failedList == nil)

        MathAtomFactory.add(
            latexSymbol: "lcm", value: MathAtomFactory.`operator`(named: "lcm", hasLimits: false),
        )
        let list = try MathListBuilder.buildChecked(fromString: str)
        let atomTypes = [
            MathAtomType.largeOperator,
            .open,
            .variable,
            .punctuation,
            .variable,
            .close,
        ]
        checkAtomTypes(list, types: atomTypes, desc: "Error for lcm")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\lcm (a,b)")
    }

    @Test func fontSingle() throws {
        let str = "\\mathbf x"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect(list.atoms.count == 1, "\(desc)")
        let atom = list.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "x", "\(desc)")
        #expect(atom.fontStyle == .bold)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\mathbf{x}", "\(desc)")
    }

    @Test func fontOneChar() throws {
        let str = "\\cal xy"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 2, "desc")
        var atom = list.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "x", "\(desc)")
        #expect(atom.fontStyle == .calligraphic)

        atom = list.atoms[1]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "y", "\(desc)")
        #expect(atom.fontStyle == .defaultStyle)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\mathcal{x}y", "\(desc)")
    }

    @Test func fontMultipleChars() throws {
        let str = "\\frak{xy}"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 2, "desc")
        var atom = list.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "x", "\(desc)")
        #expect(atom.fontStyle == .fraktur)

        atom = list.atoms[1]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "y", "\(desc)")
        #expect(atom.fontStyle == .fraktur)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\mathfrak{xy}", "\(desc)")
    }

    @Test func fontOneCharInside() throws {
        let str = "\\sqrt \\mathrm x y"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 2, "desc")

        let rad = try #require(list.atoms[0] as? Radical)
        #expect(rad.type == .radical, "\(desc)")
        #expect(rad.nucleus.isEmpty, "\(desc)")

        let subList = try #require(rad.radicand)
        var atom = subList.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "x", "\(desc)")
        #expect(atom.fontStyle == .roman)

        atom = list.atoms[1]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "y", "\(desc)")
        #expect(atom.fontStyle == .defaultStyle)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sqrt{\\mathrm{x}}y", "\(desc)")
    }

    @Test func boldsymbol() throws {
        // \boldsymbol{x} creates bold italic - Greek letters have fontStyle set
        let str = "\\boldsymbol{\\alpha + \\beta}"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect(list.atoms.count == 3, "\(desc)")

        var atom = list.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "\u{03B1}", "\(desc)") // alpha - nucleus is base char
        #expect(atom.fontStyle == .boldItalic)

        atom = list.atoms[1]
        #expect(atom.type == .binaryOperator, "\(desc)")
        #expect(atom.nucleus == "+", "\(desc)")

        atom = list.atoms[2]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "\u{03B2}", "\(desc)") // beta - nucleus is base char
        #expect(atom.fontStyle == .boldItalic)
    }

    @Test func boldsymbolSingle() throws {
        // \boldsymbol x creates bold italic single char
        let str = "\\boldsymbol x"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect(list.atoms.count == 1, "\(desc)")

        let atom = list.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "x", "\(desc)")
        #expect(atom.fontStyle == .boldItalic)

        // convert it back to latex - uses the first mapped name for boldItalic
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\bm{x}", "\(desc)")
    }

    @Test func text() throws {
        let str = "\\text{x y}"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 3, "desc")
        var atom = list.atoms[0]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "x", "\(desc)")
        #expect(atom.fontStyle == .roman)

        atom = list.atoms[1]
        #expect(atom.type == .ordinary, "\(desc)")
        #expect(atom.nucleus == " ", "\(desc)")

        atom = list.atoms[2]
        #expect(atom.type == .variable, "\(desc)")
        #expect(atom.nucleus == "y", "\(desc)")
        #expect(atom.fontStyle == .roman)

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\mathrm{x\\  y}", "\(desc)")
    }

    @Test func operatorName() throws {
        // \operatorname{dim} creates a single large operator atom (like \sin, \cos, etc.)
        let str = "\\operatorname{dim}"
        let list = try #require(MathListBuilder.build(fromString: str))
        let desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")

        let op = list.atoms[0] as? LargeOperator
        #expect(op != nil, "\(desc)")
        #expect(op?.type == .largeOperator, "\(desc)")
        #expect(op?.nucleus == "dim", "\(desc)")
        #expect(!(op?.hasLimits ?? true), "desc")

        // convert it back to latex
        let latex = MathListBuilder.mathListToString(list)
        // Note: large operators are converted to their command name if available
        #expect(latex == "\\dim ", "\(desc)")
    }

    @Test func limits() throws {
        // Int with no limits (default)
        var str = "\\int"
        var list = try #require(MathListBuilder.build(fromString: str))
        var desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        var op = try #require(list.atoms[0] as? LargeOperator)
        #expect(op.type == .largeOperator, "\(desc)")
        #expect(!(op.hasLimits))

        // convert it back to latex
        var latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\int ", "\(desc)")

        // Int with limits
        str = "\\int\\limits"
        list = try #require(MathListBuilder.build(fromString: str))
        desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        op = try #require(list.atoms[0] as? LargeOperator)
        #expect(op.type == .largeOperator, "\(desc)")
        #expect(op.hasLimits)

        // convert it back to latex
        latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\int \\limits ", "\(desc)")
    }

    @Test func noLimits() throws {
        // Sum with limits (default)
        var str = "\\sum"
        var list = try #require(MathListBuilder.build(fromString: str))
        var desc = "Error for string:\(str)"

        #expect((list.atoms.count) == 1, "desc")
        var op = try #require(list.atoms[0] as? LargeOperator)
        #expect(op.type == .largeOperator, "\(desc)")
        #expect(op.hasLimits)

        // convert it back to latex
        var latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sum ", "\(desc)")

        // Int with limits
        str = "\\sum\\nolimits"
        list = try #require(MathListBuilder.build(fromString: str))
        desc = "Error for string:\(str)"

        #expect(list.atoms.count == 1, "\(desc)")
        op = try #require(list.atoms[0] as? LargeOperator)
        #expect(op.type == .largeOperator, "\(desc)")
        #expect(!(op.hasLimits))

        // convert it back to latex
        latex = MathListBuilder.mathListToString(list)
        #expect(latex == "\\sum \\nolimits ", "\(desc)")
    }

    @Test func emptyInputs() {
        // Test 1: Completely empty string
        let result1 = MathListBuilder.build(fromString: "")
        // Empty input should return nil or empty list (both acceptable)
        if let list = result1 {
            #expect(list.atoms.isEmpty, "Empty string should produce empty atom list")
        }

        // Test 2: Just whitespace
        let result2 = MathListBuilder.build(fromString: "   ")
        if let list = result2 {
            #expect(list.atoms.isEmpty, "Whitespace-only string should produce empty atom list")
        }

        // Test 3: \sqrt with no content - this should not crash
        let result3 = MathListBuilder.build(fromString: "\\sqrt")
        #expect(result3 != nil, "\\sqrt with no content should not crash")

        // Test 4: \cfrac[ with no alignment - this should not crash
        _ = MathListBuilder.build(fromString: "\\cfrac[")
        // This may return nil due to error, but it should not crash
        // The test passes if we get here without crashing
    }
}
