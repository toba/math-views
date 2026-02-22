public import Foundation

/** A factory to create commonly used MathAtoms. */
public class MathAtomFactory {
    
    public static let aliases = [
        "lnot" : "neg",
        "land" : "wedge",
        "lor" : "vee",
        "ne" : "neq",
        "le" : "leq",
        "ge" : "geq",
        "lbrace" : "{",
        "rbrace" : "}",
        "Vert" : "|",
        "gets" : "leftarrow",
        "to" : "rightarrow",
        "iff" : "Longleftrightarrow",
        "AA" : "angstrom"
    ]
    
    public static let delimiters = [
        "." : "", // . means no delimiter
        "(" : "(",
        ")" : ")",
        "[" : "[",
        "]" : "]",
        "<" : "\u{2329}",
        ">" : "\u{232A}",
        "/" : "/",
        "\\" : "\\",
        "|" : "|",
        "lgroup" : "\u{27EE}",
        "rgroup" : "\u{27EF}",
        "||" : "\u{2016}",
        "Vert" : "\u{2016}",
        "vert" : "|",
        "uparrow" : "\u{2191}",
        "downarrow" : "\u{2193}",
        "updownarrow" : "\u{2195}",
        "Uparrow" : "\u{21D1}",
        "Downarrow" : "\u{21D3}",
        "Updownarrow" : "\u{21D5}",
        "backslash" : "\\",
        "rangle" : "\u{232A}",
        "langle" : "\u{2329}",
        "rbrace" : "}",
        "}" : "}",
        "{" : "{",
        "lbrace" : "{",
        "lceil" : "\u{2308}",
        "rceil" : "\u{2309}",
        "lfloor" : "\u{230A}",
        "rfloor" : "\u{230B}",
        // Corner brackets (amssymb)
        "ulcorner" : "\u{231C}",  // upper left corner
        "urcorner" : "\u{231D}",  // upper right corner
        "llcorner" : "\u{231E}",  // lower left corner
        "lrcorner" : "\u{231F}",  // lower right corner
        // Double square brackets (strachey brackets)
        "llbracket" : "\u{27E6}",  // left double bracket
        "rrbracket" : "\u{27E7}",  // right double bracket
    ]
    
    private static let delimValueLock = NSLock()
    static var _delimValueToName = [String: String]()
    public static var delimValueToName: [String: String] {
        if _delimValueToName.isEmpty {
            var output = [String: String]()
            for (key, value) in Self.delimiters {
                if let existingValue = output[value] {
                    if key.count > existingValue.count {
                        continue
                    } else if key.count == existingValue.count {
                        if key.compare(existingValue) == .orderedDescending {
                            continue
                        }
                    }
                }
                output[value] = key
            }
            // protect lazily loading table in a multi-thread concurrent environment
            delimValueLock.lock()
            defer { delimValueLock.unlock() }
            if _delimValueToName.isEmpty {
                _delimValueToName = output
            }
        }
        return _delimValueToName
    }
    
    public static let accents = [
        "grave" :  "\u{0300}",
        "acute" :  "\u{0301}",
        "hat" :  "\u{0302}",  // In our implementation hat and widehat behave the same.
        "tilde" :  "\u{0303}", // In our implementation tilde and widetilde behave the same.
        "bar" :  "\u{0304}",
        "breve" :  "\u{0306}",
        "dot" :  "\u{0307}",
        "ddot" :  "\u{0308}",
        "check" :  "\u{030C}",
        "vec" :  "\u{20D7}",
        "widehat" :  "\u{0302}",
        "widetilde" :  "\u{0303}",
        "overleftarrow" :  "\u{20D6}",      // Combining left arrow above
        "overrightarrow" :  "\u{20D7}",     // Combining right arrow above (same as vec)
        "overleftrightarrow" :  "\u{20E1}"  // Combining left right arrow above
    ]
    
    private static let accentValueLock = NSLock()
    static var _accentValueToName: [String: String]? = nil
    public static var accentValueToName: [String: String] {
        if _accentValueToName == nil {
            var output = [String: String]()

            for (key, value) in Self.accents {
                if let existingValue = output[value] {
                    if key.count > existingValue.count {
                        continue
                    } else if key.count == existingValue.count {
                        if key.compare(existingValue) == .orderedDescending {
                            continue
                        }
                    }
                }
                output[value] = key
            }
            // protect lazily loading table in a multi-thread concurrent environment
            accentValueLock.lock()
            defer { accentValueLock.unlock() }
            if _accentValueToName == nil {
                _accentValueToName = output
            }
        }
        return _accentValueToName!
    }
    
    static var supportedLatexSymbolNames:[String] {
        let commands = MathAtomFactory.supportedLatexSymbols
        return commands.keys.map { String($0) }
    }
    
    static var supportedLatexSymbols: [String: MathAtom] = [
        "square" : MathAtomFactory.placeholder(),
        
         // Greek characters
        "alpha" : MathAtom(type: .variable, value: "\u{03B1}"),
        "beta" : MathAtom(type: .variable, value: "\u{03B2}"),
        "gamma" : MathAtom(type: .variable, value: "\u{03B3}"),
        "delta" : MathAtom(type: .variable, value: "\u{03B4}"),
        "varepsilon" : MathAtom(type: .variable, value: "\u{03B5}"),
        "zeta" : MathAtom(type: .variable, value: "\u{03B6}"),
        "eta" : MathAtom(type: .variable, value: "\u{03B7}"),
        "theta" : MathAtom(type: .variable, value: "\u{03B8}"),
        "iota" : MathAtom(type: .variable, value: "\u{03B9}"),
        "kappa" : MathAtom(type: .variable, value: "\u{03BA}"),
        "lambda" : MathAtom(type: .variable, value: "\u{03BB}"),
        "mu" : MathAtom(type: .variable, value: "\u{03BC}"),
        "nu" : MathAtom(type: .variable, value: "\u{03BD}"),
        "xi" : MathAtom(type: .variable, value: "\u{03BE}"),
        "omicron" : MathAtom(type: .variable, value: "\u{03BF}"),
        "pi" : MathAtom(type: .variable, value: "\u{03C0}"),
        "rho" : MathAtom(type: .variable, value: "\u{03C1}"),
        "varsigma" : MathAtom(type: .variable, value: "\u{03C2}"),
        "sigma" : MathAtom(type: .variable, value: "\u{03C3}"),
        "tau" : MathAtom(type: .variable, value: "\u{03C4}"),
        "upsilon" : MathAtom(type: .variable, value: "\u{03C5}"),
        "varphi" : MathAtom(type: .variable, value: "\u{03C6}"),
        "chi" : MathAtom(type: .variable, value: "\u{03C7}"),
        "psi" : MathAtom(type: .variable, value: "\u{03C8}"),
        "omega" : MathAtom(type: .variable, value: "\u{03C9}"),
        // We mark the following greek chars as ordinary so that we don't try
        // to automatically italicize them as we do with variables.
        // These characters fall outside the rules of italicization that we have defined.
        "epsilon" : MathAtom(type: .ordinary, value: "\u{0001D716}"),
        "vartheta" : MathAtom(type: .ordinary, value: "\u{0001D717}"),
        "phi" : MathAtom(type: .ordinary, value: "\u{0001D719}"),
        "varrho" : MathAtom(type: .ordinary, value: "\u{0001D71A}"),
        "varpi" : MathAtom(type: .ordinary, value: "\u{0001D71B}"),
        "varkappa" : MathAtom(type: .ordinary, value: "\u{03F0}"),
        // Note: digamma (U+03DD) and Digamma (U+03DC) are not supported by Latin Modern Math font

        // Capital greek characters
        "Gamma" : MathAtom(type: .variable, value: "\u{0393}"),
        "Delta" : MathAtom(type: .variable, value: "\u{0394}"),
        "Theta" : MathAtom(type: .variable, value: "\u{0398}"),
        "Lambda" : MathAtom(type: .variable, value: "\u{039B}"),
        "Xi" : MathAtom(type: .variable, value: "\u{039E}"),
        "Pi" : MathAtom(type: .variable, value: "\u{03A0}"),
        "Sigma" : MathAtom(type: .variable, value: "\u{03A3}"),
        "Upsilon" : MathAtom(type: .variable, value: "\u{03A5}"),
        "Phi" : MathAtom(type: .variable, value: "\u{03A6}"),
        "Psi" : MathAtom(type: .variable, value: "\u{03A8}"),
        "Omega" : MathAtom(type: .variable, value: "\u{03A9}"),

        // Open
        "lceil" : MathAtom(type: .open, value: "\u{2308}"),
        "lfloor" : MathAtom(type: .open, value: "\u{230A}"),
        "langle" : MathAtom(type: .open, value: "\u{27E8}"),
        "lgroup" : MathAtom(type: .open, value: "\u{27EE}"),

        // Close
        "rceil" : MathAtom(type: .close, value: "\u{2309}"),
        "rfloor" : MathAtom(type: .close, value: "\u{230B}"),
        "rangle" : MathAtom(type: .close, value: "\u{27E9}"),
        "rgroup" : MathAtom(type: .close, value: "\u{27EF}"),

        // Arrows
        "leftarrow" : MathAtom(type: .relation, value: "\u{2190}"),
        "uparrow" : MathAtom(type: .relation, value: "\u{2191}"),
        "rightarrow" : MathAtom(type: .relation, value: "\u{2192}"),
        "downarrow" : MathAtom(type: .relation, value: "\u{2193}"),
        "leftrightarrow" : MathAtom(type: .relation, value: "\u{2194}"),
        "updownarrow" : MathAtom(type: .relation, value: "\u{2195}"),
        "nwarrow" : MathAtom(type: .relation, value: "\u{2196}"),
        "nearrow" : MathAtom(type: .relation, value: "\u{2197}"),
        "searrow" : MathAtom(type: .relation, value: "\u{2198}"),
        "swarrow" : MathAtom(type: .relation, value: "\u{2199}"),
        "mapsto" : MathAtom(type: .relation, value: "\u{21A6}"),
        "Leftarrow" : MathAtom(type: .relation, value: "\u{21D0}"),
        "Uparrow" : MathAtom(type: .relation, value: "\u{21D1}"),
        "Rightarrow" : MathAtom(type: .relation, value: "\u{21D2}"),
        "Downarrow" : MathAtom(type: .relation, value: "\u{21D3}"),
        "Leftrightarrow" : MathAtom(type: .relation, value: "\u{21D4}"),
        "Updownarrow" : MathAtom(type: .relation, value: "\u{21D5}"),
        "longleftarrow" : MathAtom(type: .relation, value: "\u{27F5}"),
        "longrightarrow" : MathAtom(type: .relation, value: "\u{27F6}"),
        "longleftrightarrow" : MathAtom(type: .relation, value: "\u{27F7}"),
        "Longleftarrow" : MathAtom(type: .relation, value: "\u{27F8}"),
        "Longrightarrow" : MathAtom(type: .relation, value: "\u{27F9}"),
        "Longleftrightarrow" : MathAtom(type: .relation, value: "\u{27FA}"),
        "longmapsto" : MathAtom(type: .relation, value: "\u{27FC}"),
        "hookrightarrow" : MathAtom(type: .relation, value: "\u{21AA}"),
        "hookleftarrow" : MathAtom(type: .relation, value: "\u{21A9}"),


        // Relations
        "leq" : MathAtom(type: .relation, value: UnicodeSymbol.lessEqual),
        "geq" : MathAtom(type: .relation, value: UnicodeSymbol.greaterEqual),
        "leqslant" : MathAtom(type: .relation, value: "\u{2A7D}"),
        "geqslant" : MathAtom(type: .relation, value: "\u{2A7E}"),
        "neq" : MathAtom(type: .relation, value: UnicodeSymbol.notEqual),
        "in" : MathAtom(type: .relation, value: "\u{2208}"),
        "notin" : MathAtom(type: .relation, value: "\u{2209}"),
        "ni" : MathAtom(type: .relation, value: "\u{220B}"),
        "propto" : MathAtom(type: .relation, value: "\u{221D}"),
        "mid" : MathAtom(type: .relation, value: "\u{2223}"),
        "parallel" : MathAtom(type: .relation, value: "\u{2225}"),
        "sim" : MathAtom(type: .relation, value: "\u{223C}"),
        "simeq" : MathAtom(type: .relation, value: "\u{2243}"),
        "cong" : MathAtom(type: .relation, value: "\u{2245}"),
        "approx" : MathAtom(type: .relation, value: "\u{2248}"),
        "asymp" : MathAtom(type: .relation, value: "\u{224D}"),
        "doteq" : MathAtom(type: .relation, value: "\u{2250}"),
        "equiv" : MathAtom(type: .relation, value: "\u{2261}"),
        "gg" : MathAtom(type: .relation, value: "\u{226B}"),
        "ll" : MathAtom(type: .relation, value: "\u{226A}"),
        "prec" : MathAtom(type: .relation, value: "\u{227A}"),
        "succ" : MathAtom(type: .relation, value: "\u{227B}"),
        "preceq" : MathAtom(type: .relation, value: "\u{2AAF}"),
        "succeq" : MathAtom(type: .relation, value: "\u{2AB0}"),
        "subset" : MathAtom(type: .relation, value: "\u{2282}"),
        "supset" : MathAtom(type: .relation, value: "\u{2283}"),
        "subseteq" : MathAtom(type: .relation, value: "\u{2286}"),
        "supseteq" : MathAtom(type: .relation, value: "\u{2287}"),
        "sqsubset" : MathAtom(type: .relation, value: "\u{228F}"),
        "sqsupset" : MathAtom(type: .relation, value: "\u{2290}"),
        "sqsubseteq" : MathAtom(type: .relation, value: "\u{2291}"),
        "sqsupseteq" : MathAtom(type: .relation, value: "\u{2292}"),
        "models" : MathAtom(type: .relation, value: "\u{22A7}"),
        "vdash" : MathAtom(type: .relation, value: "\u{22A2}"),
        "dashv" : MathAtom(type: .relation, value: "\u{22A3}"),
        "bowtie" : MathAtom(type: .relation, value: "\u{22C8}"),
        "perp" : MathAtom(type: .relation, value: "\u{27C2}"),
        "implies" : MathAtom(type: .relation, value: "\u{27F9}"),

        // Negated relations (amssymb)
        // Inequality negations
        "nless" : MathAtom(type: .relation, value: "\u{226E}"),
        "ngtr" : MathAtom(type: .relation, value: "\u{226F}"),
        "nleq" : MathAtom(type: .relation, value: "\u{2270}"),
        "ngeq" : MathAtom(type: .relation, value: "\u{2271}"),
        "nleqslant" : MathAtom(type: .relation, value: "\u{2A87}"),
        "ngeqslant" : MathAtom(type: .relation, value: "\u{2A88}"),
        "lneq" : MathAtom(type: .relation, value: "\u{2A87}"),
        "gneq" : MathAtom(type: .relation, value: "\u{2A88}"),
        "lneqq" : MathAtom(type: .relation, value: "\u{2268}"),
        "gneqq" : MathAtom(type: .relation, value: "\u{2269}"),
        "lnsim" : MathAtom(type: .relation, value: "\u{22E6}"),
        "gnsim" : MathAtom(type: .relation, value: "\u{22E7}"),
        "lnapprox" : MathAtom(type: .relation, value: "\u{2A89}"),
        "gnapprox" : MathAtom(type: .relation, value: "\u{2A8A}"),

        // Ordering negations
        "nprec" : MathAtom(type: .relation, value: "\u{2280}"),
        "nsucc" : MathAtom(type: .relation, value: "\u{2281}"),
        "npreceq" : MathAtom(type: .relation, value: "\u{22E0}"),
        "nsucceq" : MathAtom(type: .relation, value: "\u{22E1}"),
        "precneqq" : MathAtom(type: .relation, value: "\u{2AB5}"),
        "succneqq" : MathAtom(type: .relation, value: "\u{2AB6}"),
        "precnsim" : MathAtom(type: .relation, value: "\u{22E8}"),
        "succnsim" : MathAtom(type: .relation, value: "\u{22E9}"),
        "precnapprox" : MathAtom(type: .relation, value: "\u{2AB9}"),
        "succnapprox" : MathAtom(type: .relation, value: "\u{2ABA}"),

        // Similarity/congruence negations
        "nsim" : MathAtom(type: .relation, value: "\u{2241}"),
        "ncong" : MathAtom(type: .relation, value: "\u{2247}"),
        "nmid" : MathAtom(type: .relation, value: "\u{2224}"),
        "nshortmid" : MathAtom(type: .relation, value: "\u{2224}"),
        "nparallel" : MathAtom(type: .relation, value: "\u{2226}"),
        "nshortparallel" : MathAtom(type: .relation, value: "\u{2226}"),

        // Set relation negations
        "nsubseteq" : MathAtom(type: .relation, value: "\u{2288}"),
        "nsupseteq" : MathAtom(type: .relation, value: "\u{2289}"),
        "subsetneq" : MathAtom(type: .relation, value: "\u{228A}"),
        "supsetneq" : MathAtom(type: .relation, value: "\u{228B}"),
        "subsetneqq" : MathAtom(type: .relation, value: "\u{2ACB}"),
        "supsetneqq" : MathAtom(type: .relation, value: "\u{2ACC}"),
        "varsubsetneq" : MathAtom(type: .relation, value: "\u{228A}"),
        "varsupsetneq" : MathAtom(type: .relation, value: "\u{228B}"),
        "varsubsetneqq" : MathAtom(type: .relation, value: "\u{2ACB}"),
        "varsupsetneqq" : MathAtom(type: .relation, value: "\u{2ACC}"),
        "notni" : MathAtom(type: .relation, value: "\u{220C}"),
        "nni" : MathAtom(type: .relation, value: "\u{220C}"),

        // Triangle negations
        "ntriangleleft" : MathAtom(type: .relation, value: "\u{22EA}"),
        "ntriangleright" : MathAtom(type: .relation, value: "\u{22EB}"),
        "ntrianglelefteq" : MathAtom(type: .relation, value: "\u{22EC}"),
        "ntrianglerighteq" : MathAtom(type: .relation, value: "\u{22ED}"),

        // Turnstile negations
        "nvdash" : MathAtom(type: .relation, value: "\u{22AC}"),
        "nvDash" : MathAtom(type: .relation, value: "\u{22AD}"),
        "nVdash" : MathAtom(type: .relation, value: "\u{22AE}"),
        "nVDash" : MathAtom(type: .relation, value: "\u{22AF}"),

        // Square subset negations
        "nsqsubseteq" : MathAtom(type: .relation, value: "\u{22E2}"),
        "nsqsupseteq" : MathAtom(type: .relation, value: "\u{22E3}"),

        // operators
        "times" : MathAtomFactory.times(),
        "div"   : MathAtomFactory.divide(),
        "pm"    : MathAtom(type: .binaryOperator, value: "\u{00B1}"),
        "dagger" : MathAtom(type: .binaryOperator, value: "\u{2020}"),
        "ddagger" : MathAtom(type: .binaryOperator, value: "\u{2021}"),
        "mp"    : MathAtom(type: .binaryOperator, value: "\u{2213}"),
        "setminus" : MathAtom(type: .binaryOperator, value: "\u{2216}"),
        "ast"   : MathAtom(type: .binaryOperator, value: "\u{2217}"),
        "circ"  : MathAtom(type: .binaryOperator, value: "\u{2218}"),
        "bullet" : MathAtom(type: .binaryOperator, value: "\u{2219}"),
        "wedge" : MathAtom(type: .binaryOperator, value: "\u{2227}"),
        "vee" : MathAtom(type: .binaryOperator, value: "\u{2228}"),
        "cap" : MathAtom(type: .binaryOperator, value: "\u{2229}"),
        "cup" : MathAtom(type: .binaryOperator, value: "\u{222A}"),
        "wr" : MathAtom(type: .binaryOperator, value: "\u{2240}"),
        "uplus" : MathAtom(type: .binaryOperator, value: "\u{228E}"),
        "sqcap" : MathAtom(type: .binaryOperator, value: "\u{2293}"),
        "sqcup" : MathAtom(type: .binaryOperator, value: "\u{2294}"),
        "oplus" : MathAtom(type: .binaryOperator, value: "\u{2295}"),
        "ominus" : MathAtom(type: .binaryOperator, value: "\u{2296}"),
        "otimes" : MathAtom(type: .binaryOperator, value: "\u{2297}"),
        "oslash" : MathAtom(type: .binaryOperator, value: "\u{2298}"),
        "odot" : MathAtom(type: .binaryOperator, value: "\u{2299}"),
        "star"  : MathAtom(type: .binaryOperator, value: "\u{22C6}"),
        "cdot"  : MathAtom(type: .binaryOperator, value: "\u{22C5}"),
        "diamond" : MathAtom(type: .binaryOperator, value: "\u{22C4}"),
        "amalg" : MathAtom(type: .binaryOperator, value: "\u{2A3F}"),

        // Additional binary operators (amssymb)
        "ltimes" : MathAtom(type: .binaryOperator, value: "\u{22C9}"),  // left semidirect product
        "rtimes" : MathAtom(type: .binaryOperator, value: "\u{22CA}"),  // right semidirect product
        "circledast" : MathAtom(type: .binaryOperator, value: "\u{229B}"),
        "circledcirc" : MathAtom(type: .binaryOperator, value: "\u{229A}"),
        "circleddash" : MathAtom(type: .binaryOperator, value: "\u{229D}"),
        "boxdot" : MathAtom(type: .binaryOperator, value: "\u{22A1}"),
        "boxminus" : MathAtom(type: .binaryOperator, value: "\u{229F}"),
        "boxplus" : MathAtom(type: .binaryOperator, value: "\u{229E}"),
        "boxtimes" : MathAtom(type: .binaryOperator, value: "\u{22A0}"),
        "divideontimes" : MathAtom(type: .binaryOperator, value: "\u{22C7}"),
        "dotplus" : MathAtom(type: .binaryOperator, value: "\u{2214}"),
        "lhd" : MathAtom(type: .binaryOperator, value: "\u{22B2}"),  // left normal subgroup
        "rhd" : MathAtom(type: .binaryOperator, value: "\u{22B3}"),  // right normal subgroup
        "unlhd" : MathAtom(type: .binaryOperator, value: "\u{22B4}"),  // left normal subgroup or equal
        "unrhd" : MathAtom(type: .binaryOperator, value: "\u{22B5}"),  // right normal subgroup or equal
        "intercal" : MathAtom(type: .binaryOperator, value: "\u{22BA}"),
        "barwedge" : MathAtom(type: .binaryOperator, value: "\u{22BC}"),
        "veebar" : MathAtom(type: .binaryOperator, value: "\u{22BB}"),
        "curlywedge" : MathAtom(type: .binaryOperator, value: "\u{22CF}"),
        "curlyvee" : MathAtom(type: .binaryOperator, value: "\u{22CE}"),
        "doublebarwedge" : MathAtom(type: .binaryOperator, value: "\u{2A5E}"),
        "centerdot" : MathAtom(type: .binaryOperator, value: "\u{22C5}"),  // alias for cdot

        // No limit operators
        "log" : MathAtomFactory.operatorWithName( "log", limits: false),
        "lg" : MathAtomFactory.operatorWithName( "lg", limits: false),
        "ln" : MathAtomFactory.operatorWithName( "ln", limits: false),
        "sin" : MathAtomFactory.operatorWithName( "sin", limits: false),
        "arcsin" : MathAtomFactory.operatorWithName( "arcsin", limits: false),
        "sinh" : MathAtomFactory.operatorWithName( "sinh", limits: false),
        "cos" : MathAtomFactory.operatorWithName( "cos", limits: false),
        "arccos" : MathAtomFactory.operatorWithName( "arccos", limits: false),
        "cosh" : MathAtomFactory.operatorWithName( "cosh", limits: false),
        "tan" : MathAtomFactory.operatorWithName( "tan", limits: false),
        "arctan" : MathAtomFactory.operatorWithName( "arctan", limits: false),
        "tanh" : MathAtomFactory.operatorWithName( "tanh", limits: false),
        "cot" : MathAtomFactory.operatorWithName( "cot", limits: false),
        "coth" : MathAtomFactory.operatorWithName( "coth", limits: false),
        "sec" : MathAtomFactory.operatorWithName( "sec", limits: false),
        "csc" : MathAtomFactory.operatorWithName( "csc", limits: false),
        // Additional inverse trig functions
        "arccot" : MathAtomFactory.operatorWithName( "arccot", limits: false),
        "arcsec" : MathAtomFactory.operatorWithName( "arcsec", limits: false),
        "arccsc" : MathAtomFactory.operatorWithName( "arccsc", limits: false),
        // Additional hyperbolic functions
        "sech" : MathAtomFactory.operatorWithName( "sech", limits: false),
        "csch" : MathAtomFactory.operatorWithName( "csch", limits: false),
        // Inverse hyperbolic functions
        "arcsinh" : MathAtomFactory.operatorWithName( "arcsinh", limits: false),
        "arccosh" : MathAtomFactory.operatorWithName( "arccosh", limits: false),
        "arctanh" : MathAtomFactory.operatorWithName( "arctanh", limits: false),
        "arccoth" : MathAtomFactory.operatorWithName( "arccoth", limits: false),
        "arcsech" : MathAtomFactory.operatorWithName( "arcsech", limits: false),
        "arccsch" : MathAtomFactory.operatorWithName( "arccsch", limits: false),
        "arg" : MathAtomFactory.operatorWithName( "arg", limits: false),
        "ker" : MathAtomFactory.operatorWithName( "ker", limits: false),
        "dim" : MathAtomFactory.operatorWithName( "dim", limits: false),
        "hom" : MathAtomFactory.operatorWithName( "hom", limits: false),
        "exp" : MathAtomFactory.operatorWithName( "exp", limits: false),
        "deg" : MathAtomFactory.operatorWithName( "deg", limits: false),
        "mod" : MathAtomFactory.operatorWithName("mod", limits: false),

        // Limit operators
        "lim" : MathAtomFactory.operatorWithName( "lim", limits: true),
        "limsup" : MathAtomFactory.operatorWithName( "lim sup", limits: true),
        "liminf" : MathAtomFactory.operatorWithName( "lim inf", limits: true),
        "max" : MathAtomFactory.operatorWithName( "max", limits: true),
        "min" : MathAtomFactory.operatorWithName( "min", limits: true),
        "sup" : MathAtomFactory.operatorWithName( "sup", limits: true),
        "inf" : MathAtomFactory.operatorWithName( "inf", limits: true),
        "det" : MathAtomFactory.operatorWithName( "det", limits: true),
        "Pr" : MathAtomFactory.operatorWithName( "Pr", limits: true),
        "gcd" : MathAtomFactory.operatorWithName( "gcd", limits: true),

        // Large operators
        "prod" : MathAtomFactory.operatorWithName( "\u{220F}", limits: true),
        "coprod" : MathAtomFactory.operatorWithName( "\u{2210}", limits: true),
        "sum" : MathAtomFactory.operatorWithName( "\u{2211}", limits: true),
        "int" : MathAtomFactory.operatorWithName( "\u{222B}", limits: false),
        "iint" : MathAtomFactory.operatorWithName( "\u{222C}", limits: false),
        "iiint" : MathAtomFactory.operatorWithName( "\u{222D}", limits: false),
        "iiiint" : MathAtomFactory.operatorWithName( "\u{2A0C}", limits: false),
        "oint" : MathAtomFactory.operatorWithName( "\u{222E}", limits: false),
        "bigwedge" : MathAtomFactory.operatorWithName( "\u{22C0}", limits: true),
        "bigvee" : MathAtomFactory.operatorWithName( "\u{22C1}", limits: true),
        "bigcap" : MathAtomFactory.operatorWithName( "\u{22C2}", limits: true),
        "bigcup" : MathAtomFactory.operatorWithName( "\u{22C3}", limits: true),
        "bigodot" : MathAtomFactory.operatorWithName( "\u{2A00}", limits: true),
        "bigoplus" : MathAtomFactory.operatorWithName( "\u{2A01}", limits: true),
        "bigotimes" : MathAtomFactory.operatorWithName( "\u{2A02}", limits: true),
        "biguplus" : MathAtomFactory.operatorWithName( "\u{2A04}", limits: true),
        "bigsqcup" : MathAtomFactory.operatorWithName( "\u{2A06}", limits: true),

        // Latex command characters
        "{" : MathAtom(type: .open, value: "{"),
        "}" : MathAtom(type: .close, value: "}"),
        "$" : MathAtom(type: .ordinary, value: "$"),
        "&" : MathAtom(type: .ordinary, value: "&"),
        "#" : MathAtom(type: .ordinary, value: "#"),
        "%" : MathAtom(type: .ordinary, value: "%"),
        "_" : MathAtom(type: .ordinary, value: "_"),
        " " : MathAtom(type: .ordinary, value: " "),
        "backslash" : MathAtom(type: .ordinary, value: "\\"),

        // Punctuation
        // Note: \colon is different from : which is a relation
        "colon" : MathAtom(type: .punctuation, value: ":"),
        "cdotp" : MathAtom(type: .punctuation, value: "\u{00B7}"),

        // Other symbols
        "degree" : MathAtom(type: .ordinary, value: "\u{00B0}"),
        "neg" : MathAtom(type: .ordinary, value: "\u{00AC}"),
        "angstrom" : MathAtom(type: .ordinary, value: "\u{00C5}"),
		"aa" : MathAtom(type: .ordinary, value: "\u{00E5}"),	// NEW å
		"ae" : MathAtom(type: .ordinary, value: "\u{00E6}"),	// NEW æ
		"o"  : MathAtom(type: .ordinary, value: "\u{00F8}"),	// NEW ø
		"oe" : MathAtom(type: .ordinary, value: "\u{0153}"),	// NEW œ
		"ss" : MathAtom(type: .ordinary, value: "\u{00DF}"),	// NEW ß
		"cc" : MathAtom(type: .ordinary, value: "\u{00E7}"),	// NEW ç
		"CC" : MathAtom(type: .ordinary, value: "\u{00C7}"),	// NEW Ç
		"O"  : MathAtom(type: .ordinary, value: "\u{00D8}"),	// NEW Ø
		"AE" : MathAtom(type: .ordinary, value: "\u{00C6}"),	// NEW Æ
		"OE" : MathAtom(type: .ordinary, value: "\u{0152}"),	// NEW Œ
        "|" : MathAtom(type: .ordinary, value: "\u{2016}"),
        "vert" : MathAtom(type: .ordinary, value: "|"),
        "ldots" : MathAtom(type: .ordinary, value: "\u{2026}"),
        "prime" : MathAtom(type: .ordinary, value: "\u{2032}"),
        "hbar" : MathAtom(type: .ordinary, value: "\u{210F}"),
        "lbar" : MathAtom(type: .ordinary, value: "\u{019B}"),  // NEW ƛ
        "Im" : MathAtom(type: .ordinary, value: "\u{2111}"),
        "ell" : MathAtom(type: .ordinary, value: "\u{2113}"),
        "wp" : MathAtom(type: .ordinary, value: "\u{2118}"),
        "Re" : MathAtom(type: .ordinary, value: "\u{211C}"),
        "mho" : MathAtom(type: .ordinary, value: "\u{2127}"),
        "aleph" : MathAtom(type: .ordinary, value: "\u{2135}"),
        "beth" : MathAtom(type: .ordinary, value: "\u{2136}"),
        "gimel" : MathAtom(type: .ordinary, value: "\u{2137}"),
        "daleth" : MathAtom(type: .ordinary, value: "\u{2138}"),
        "forall" : MathAtom(type: .ordinary, value: "\u{2200}"),
        "exists" : MathAtom(type: .ordinary, value: "\u{2203}"),
        "nexists" : MathAtom(type: .ordinary, value: "\u{2204}"),
        "emptyset" : MathAtom(type: .ordinary, value: "\u{2205}"),
        "varnothing" : MathAtom(type: .ordinary, value: "\u{2205}"),
        "nabla" : MathAtom(type: .ordinary, value: "\u{2207}"),
        "infty" : MathAtom(type: .ordinary, value: "\u{221E}"),
        "angle" : MathAtom(type: .ordinary, value: "\u{2220}"),
        "measuredangle" : MathAtom(type: .ordinary, value: "\u{2221}"),
        "top" : MathAtom(type: .ordinary, value: "\u{22A4}"),
        "bot" : MathAtom(type: .ordinary, value: "\u{22A5}"),
        "vdots" : MathAtom(type: .ordinary, value: "\u{22EE}"),
        "cdots" : MathAtom(type: .ordinary, value: "\u{22EF}"),
        "ddots" : MathAtom(type: .ordinary, value: "\u{22F1}"),
        "triangle" : MathAtom(type: .ordinary, value: "\u{25B3}"),
        "Box" : MathAtom(type: .ordinary, value: "\u{25A1}"),
        "imath" : MathAtom(type: .ordinary, value: "\u{0001D6A4}"),
        "jmath" : MathAtom(type: .ordinary, value: "\u{0001D6A5}"),
        "upquote" : MathAtom(type: .ordinary, value: "\u{0027}"),
        "partial" : MathAtom(type: .ordinary, value: "\u{0001D715}"),

        // Spacing
        "," : MathSpace(space: 3),
        ">" : MathSpace(space: 4),
        ";" : MathSpace(space: 5),
        "!" : MathSpace(space: -3),
        "quad" : MathSpace(space: 18),  // quad = 1em = 18mu
        "qquad" : MathSpace(space: 36), // qquad = 2em

        // Style
        "displaystyle" : MathStyle(style: .display),
        "textstyle" : MathStyle(style: .text),
        "scriptstyle" : MathStyle(style: .script),
        "scriptscriptstyle" : MathStyle(style: .scriptOfScript),
    ]
	
	static var supportedAccentedCharacters: [Character: (String, String)] = [
		// Acute accents
		"á": ("acute", "a"), "é": ("acute", "e"), "í": ("acute", "i"),
		"ó": ("acute", "o"), "ú": ("acute", "u"), "ý": ("acute", "y"),
		
		// Grave accents
		"à": ("grave", "a"), "è": ("grave", "e"), "ì": ("grave", "i"),
		"ò": ("grave", "o"), "ù": ("grave", "u"),
		
		// Circumflex
		"â": ("hat", "a"), "ê": ("hat", "e"), "î": ("hat", "i"),
		"ĵ": ("hat", "j"),  // j with circumflex (Esperanto)
		"ô": ("hat", "o"), "û": ("hat", "u"),
		
		// Umlaut/dieresis
		"ä": ("ddot", "a"), "ë": ("ddot", "e"), "ï": ("ddot", "i"),
		"ö": ("ddot", "o"), "ü": ("ddot", "u"), "ÿ": ("ddot", "y"),
		
		// Tilde
		"ã": ("tilde", "a"), "ñ": ("tilde", "n"), "õ": ("tilde", "o"),
		
		// Special characters
		"ç": ("cc", ""), "ø": ("o", ""), "å": ("aa", ""), "æ": ("ae", ""),
		"œ": ("oe", ""), "ß": ("ss", ""),
		"'": ("upquote", ""),  // this may be dangerous in math mode
		
		// Upper case variants
		"Á": ("acute", "A"), "É": ("acute", "E"), "Í": ("acute", "I"),
		"Ó": ("acute", "O"), "Ú": ("acute", "U"), "Ý": ("acute", "Y"),
		"À": ("grave", "A"), "È": ("grave", "E"), "Ì": ("grave", "I"),
		"Ò": ("grave", "O"), "Ù": ("grave", "U"),
		"Â": ("hat", "A"), "Ê": ("hat", "E"), "Î": ("hat", "I"),
		"Ô": ("hat", "O"), "Û": ("hat", "U"),
		"Ä": ("ddot", "A"), "Ë": ("ddot", "E"), "Ï": ("ddot", "I"),
		"Ö": ("ddot", "O"), "Ü": ("ddot", "U"),
		"Ã": ("tilde", "A"), "Ñ": ("tilde", "N"), "Õ": ("tilde", "O"),
		"Ç": ("CC", ""),
		"Ø": ("O", ""),
		"Å": ("AA", ""),
		"Æ": ("AE", ""),
		"Œ": ("OE", ""),
	]
    
    private static let textToLatexLock = NSLock()
    static var _textToLatexSymbolName: [String: String]? = nil
    public static var textToLatexSymbolName: [String: String] {
        get {
            if self._textToLatexSymbolName == nil {
                var output = [String: String]()
                for (key, atom) in Self.supportedLatexSymbols {
                    if atom.nucleus.count == 0 {
                        continue
                    }
                    if let existingText = output[atom.nucleus] {
                        // If there are 2 key for the same symbol, choose one deterministically.
                        if key.count > existingText.count {
                            // Keep the shorter command
                            continue
                        } else if key.count == existingText.count {
                            // If the length is the same, keep the alphabetically first
                            if key.compare(existingText) == .orderedDescending {
                                continue
                            }
                        }
                    }
                    output[atom.nucleus] = key
                }
                // protect lazily loading table in a multi-thread concurrent environment
                textToLatexLock.lock()
                defer { textToLatexLock.unlock() }
                if self._textToLatexSymbolName == nil {
                    self._textToLatexSymbolName = output
                }
            }
            return self._textToLatexSymbolName!
        }
        // make textToLatexSymbolName readonly (allows internal load)
        // entries can be lazily added with NSLock protection.
        // set {
        //     self._textToLatexSymbolName = newValue
        // }
    }
    
  //  public static let sharedInstance = MathAtomFactory()
    
    static let fontStyles : [String: FontStyle] = [
        "mathnormal" : .defaultStyle,
        "mathrm": .roman,
        "textrm": .roman,
        "rm": .roman,
        "mathbf": .bold,
        "bf": .bold,
        "textbf": .bold,
        "mathcal": .caligraphic,
        "cal": .caligraphic,
        "mathtt": .typewriter,
        "texttt": .typewriter,
        "mathit": .italic,
        "textit": .italic,
        "mit": .italic,
        "mathsf": .sansSerif,
        "textsf": .sansSerif,
        "mathfrak": .fraktur,
        "frak": .fraktur,
        "mathbb": .blackboard,
        "mathbfit": .boldItalic,
        "bm": .boldItalic,
        "boldsymbol": .boldItalic,
        "text": .roman,
        // Note: operatorname is handled specially in MathListBuilder to create proper operators
    ]
    
    public static func fontStyleWithName(_ fontName:String) -> FontStyle? {
        fontStyles[fontName]
    }
    
    public static func fontNameForStyle(_ fontStyle:FontStyle) -> String {
        switch fontStyle {
            case .defaultStyle: return "mathnormal"
            case .roman:        return "mathrm"
            case .bold:         return "mathbf"
            case .fraktur:      return "mathfrak"
            case .caligraphic:  return "mathcal"
            case .italic:       return "mathit"
            case .sansSerif:    return "mathsf"
            case .blackboard:   return "mathbb"
            case .typewriter:   return "mathtt"
            case .boldItalic:   return "bm"
        }
    }
    
    /// Returns an atom for the multiplication sign (i.e., \times or "*")
    public static func times() -> MathAtom {
        MathAtom(type: .binaryOperator, value: UnicodeSymbol.multiplication)
    }
    
    /// Returns an atom for the division sign (i.e., \div or "/")
    public static func divide() -> MathAtom {
        MathAtom(type: .binaryOperator, value: UnicodeSymbol.division)
    }
    
    /// Returns an atom which is a placeholder square
    public static func placeholder() -> MathAtom {
        MathAtom(type: .placeholder, value: UnicodeSymbol.whiteSquare)
    }
    
    /** Returns a fraction with a placeholder for the numerator and denominator */
    public static func placeholderFraction() -> Fraction {
        let frac = Fraction()
        frac.numerator = MathList()
        frac.numerator?.add(placeholder())
        frac.denominator = MathList()
        frac.denominator?.add(placeholder())
        return frac
    }
    
    /** Returns a square root with a placeholder as the radicand. */
    public static func placeholderSquareRoot() -> Radical {
        let rad = Radical()
        rad.radicand = MathList()
        rad.radicand?.add(placeholder())
        return rad
    }
    
    /** Returns a radical with a placeholder as the radicand. */
    public static func placeholderRadical() -> Radical {
        let rad = Radical()
        rad.radicand = MathList()
        rad.degree = MathList()
        rad.radicand?.add(placeholder())
        rad.degree?.add(placeholder())
        return rad
    }
	
	/// Latin Small Letter Dotless I (U+0131) - base character that can be styled
	private static let dotlessI: Character = "\u{0131}"
	/// Latin Small Letter Dotless J (U+0237) - base character that can be styled
	private static let dotlessJ: Character = "\u{0237}"

	public static func atom(fromAccentedCharacter ch: Character) -> MathAtom? {
		if let symbol = supportedAccentedCharacters[ch] {
			// first handle any special characters
			if let atom = atom(forLatexSymbol: symbol.0) {
				return atom
			}

			if let accent = MathAtomFactory.accent(withName: symbol.0) {
				// The command is an accent
				let list = MathList()
				let baseChar = Array(symbol.1)[0]
				// Use dotless variants for 'i' and 'j' to avoid double dots with accents.
				// We use the base Latin dotless characters (U+0131, U+0237) rather than
				// the pre-styled mathematical italic versions (U+1D6A4, U+1D6A5) so that
				// font style (roman, bold, etc.) is properly applied during rendering.
				if baseChar == "i" {
					list.add(MathAtom(type: .ordinary, value: String(dotlessI)))
				} else if baseChar == "j" {
					list.add(MathAtom(type: .ordinary, value: String(dotlessJ)))
				} else {
					list.add(atom(forCharacter: baseChar))
				}
				accent.innerList = list
				return accent
			}
		}
		return nil
	}
    
    // MARK: -
    /** Gets the atom with the right type for the given character. If an atom
     cannot be determined for a given character this returns nil.
     This function follows latex conventions for assigning types to the atoms.
     The following characters are not supported and will return nil:
     - Any non-ascii character.
     - Any control character or spaces (< 0x21)
     - Latex control chars: $ % # & ~ '
     - Chars with special meaning in latex: ^ _ { } \
     All other characters, including those with accents, will have a non-nil atom returned.
     */
    public static func atom(forCharacter ch: Character) -> MathAtom? {
        let chStr = String(ch)
        switch chStr {
            case "\u{0410}"..."\u{044F}":
				// Cyrillic alphabet
                return MathAtom(type: .ordinary, value: chStr)
			case _ where supportedAccentedCharacters.keys.contains(ch):
				// support for áéíóúýàèìòùâêîôûäëïöüÿãñõçøåæœß'ÁÉÍÓÚÝÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÃÑÕÇØÅÆŒ
				return atom(fromAccentedCharacter: ch)
            case _ where ch.utf32Char < 0x0021 || ch.utf32Char > 0x007E:
                return nil
            case "$", "%", "#", "&", "~", "\'", "^", "_", "{", "}", "\\":
                return nil
            case "(", "[":
                return MathAtom(type: .open, value: chStr)
            case ")", "]", "!", "?":
                return MathAtom(type: .close, value: chStr)
            case ",", ";":
                return MathAtom(type: .punctuation, value: chStr)
            case "=", ">", "<":
                return MathAtom(type: .relation, value: chStr)
            case ":":
                // Math colon is ratio. Regular colon is \colon
                return MathAtom(type: .relation, value: "\u{2236}")
            case "-":
                return MathAtom(type: .binaryOperator, value: "\u{2212}")
            case "+", "*":
                return MathAtom(type: .binaryOperator, value: chStr)
            case ".", "0"..."9":
                return MathAtom(type: .number, value: chStr)
            case "a"..."z", "A"..."Z":
                return MathAtom(type: .variable, value: chStr)
            case "\"", "/", "@", "`", "|":
                return MathAtom(type: .ordinary, value: chStr)
            default:
                assertionFailure("Unknown ASCII character '\(ch)'. Should have been handled earlier.")
                return nil
        }
    }
    
    /** Returns a `MathList` with one atom per character in the given string. This function
     does not do any LaTeX conversion or interpretation. It simply uses `atom(forCharacter:)` to
     convert the characters to atoms. Any character that cannot be converted is ignored. */
    public static func atomList(for string: String) -> MathList {
        let list = MathList()
        for character in string {
            if let newAtom = atom(forCharacter: character) {
                list.add(newAtom)
            }
        }
        return list
    }
    
    /** Returns an atom with the right type for a given latex symbol (e.g. theta)
     If the latex symbol is unknown this will return nil. This supports LaTeX aliases as well.
     */
    public static func atom(forLatexSymbol name: String) -> MathAtom? {
        var name = name
        if let canonicalName = aliases[name] {
            name = canonicalName
        }
        if let atom = supportedLatexSymbols[name] {
            return atom.copy()
        }
        return nil
    }
    
    /** Finds the name of the LaTeX symbol name for the given atom. This function is a reverse
     of the above function. If no latex symbol name corresponds to the atom, then this returns `nil`
     If nucleus of the atom is empty, then this will return `nil`.
     Note: This is not an exact reverse of the above in the case of aliases. If an LaTeX alias
     points to a given symbol, then this function will return the original symbol name and not the
     alias.
     Note: This function does not convert MathSpaces to latex command names either.
     */
    public static func latexSymbolName(for atom: MathAtom) -> String? {
        guard !atom.nucleus.isEmpty else { return nil }
        return Self.textToLatexSymbolName[atom.nucleus]
    }
    
    /** Define a latex symbol for rendering. This function allows defining custom symbols that are
     not already present in the default set, or override existing symbols with new meaning.
     e.g. to define a symbol for "lcm" one can call:
     `MathAtomFactory.add(latexSymbol:"lcm", value:MathAtomFactory.operatorWithName("lcm", limits: false))` */
    public static func add(latexSymbol name: String, value: MathAtom) {
        let _ = Self.textToLatexSymbolName
        // above force textToLatexSymbolName to initialise first, _textToLatexSymbolName also initialized.
        // protect lazily loading table in a multi-thread concurrent environment
        textToLatexLock.lock()
        defer { textToLatexLock.unlock() }
        supportedLatexSymbols[name] = value
        Self._textToLatexSymbolName?[value.nucleus] = name
    }
    
    /** Returns a large opertor for the given name. If limits is true, limits are set up on
     the operator and displayed differently. */
    public static func operatorWithName(_ name: String, limits: Bool) -> LargeOperator {
        LargeOperator(value: name, limits: limits)
    }
    
    /** Returns an accent with the given name. The name of the accent is the LaTeX name
     such as `grave`, `hat` etc. If the name is not a recognized accent name, this
     returns nil. The `innerList` of the returned `Accent` is nil.
     */
    public static func accent(withName name: String) -> Accent? {
        if let accentValue = accents[name] {
            let accent = Accent(value: accentValue)
            // Mark stretchy arrow accents (\overleftarrow, \overrightarrow, \overleftrightarrow)
            // These should stretch to match content width
            // \vec is NOT stretchy - it should use a small fixed-size arrow
            let stretchyAccents: Set<String> = ["overleftarrow", "overrightarrow", "overleftrightarrow"]
            accent.isStretchy = stretchyAccents.contains(name)

            // Mark wide accents (\widehat, \widetilde, \widecheck)
            // These should stretch horizontally to cover content width
            // \hat, \tilde, \check are NOT wide - they use fixed-size accents
            let wideAccents: Set<String> = ["widehat", "widetilde", "widecheck"]
            accent.isWide = wideAccents.contains(name)

            return accent
        }
        return nil
    }
    
    /** Returns the accent name for the given accent. This is the reverse of the above
     function. */
    public static func accentName(_ accent: Accent) -> String? {
        accentValueToName[accent.nucleus]
    }
    
    /** Creates a new boundary atom for the given delimiter name. If the delimiter name
     is not recognized it returns nil. A delimiter name can be a single character such
     as '(' or a latex command such as 'uparrow'.
     @note In order to distinguish between the delimiter '|' and the delimiter '\|' the delimiter '\|'
     the has been renamed to '||'.
     */
    public static func boundary(forDelimiter name: String) -> MathAtom? {
        if let delimValue = Self.delimiters[name] {
            return MathAtom(type: .boundary, value: delimValue)
        }
        return nil
    }
    
    /** Returns the delimiter name for a boundary atom. This is a reverse of the above function.
     If the atom is not a boundary atom or if the delimiter value is unknown this returns `nil`.
     @note This is not an exact reverse of the above function. Some delimiters have two names (e.g.
     `<` and `langle`) and this function always returns the shorter name.
     */
    public static func getDelimiterName(of boundary: MathAtom) -> String? {
        guard boundary.type == .boundary else { return nil }
        return Self.delimValueToName[boundary.nucleus]
    }
    
    /** Returns a fraction with the given numerator and denominator. */
    public static func fraction(withNumerator num: MathList, denominator denom: MathList) -> Fraction {
        let frac = Fraction()
        frac.numerator = num
        frac.denominator = denom
        return frac
    }
    
    public static func mathListForCharacters(_ chars:String) -> MathList? {
        let list = MathList()
        for ch in chars {
            if let atom = self.atom(forCharacter: ch) {
                list.add(atom)
            }
        }
        return list
    }
    
    /** Simplification of above function when numerator and denominator are simple strings.
     This function converts the strings to a `Fraction`. */
    public static func fraction(withNumeratorString numStr: String, denominatorString denomStr: String) -> Fraction {
        let num = Self.atomList(for: numStr)
        let denom = Self.atomList(for: denomStr)
        return Self.fraction(withNumerator: num, denominator: denom)
    }
    

    static let matrixEnvs = [
        "matrix": [],
        "pmatrix": ["(", ")"],
        "bmatrix": ["[", "]"],
        "Bmatrix": ["{", "}"],
        "vmatrix": ["vert", "vert"],
        "Vmatrix": ["Vert", "Vert"],
        "smallmatrix": [],
        // Starred versions with optional alignment
        "matrix*": [],
        "pmatrix*": ["(", ")"],
        "bmatrix*": ["[", "]"],
        "Bmatrix*": ["{", "}"],
        "vmatrix*": ["vert", "vert"],
        "Vmatrix*": ["Vert", "Vert"]
    ]
    
    /** Builds a table for a given environment with the given rows. Returns a `MathAtom` containing the
     table and any other atoms necessary for the given environment. Returns nil and sets error
     if the table could not be built.
     @param env The environment to use to build the table. If the env is nil, then the default table is built.
     @note The reason this function returns a `MathAtom` and not a `MathTable` is because some
     matrix environments are have builtin delimiters added to the table and hence are returned as inner atoms.

     Column constraints by environment (matching KaTeX behavior):
     - `aligned`, `eqalign`: Any number of columns (1, 2, 3, 4+) with r-l-r-l alignment pattern
     - `split`: Maximum 2 columns with r-l alignment
     - `gather`, `displaylines`: Exactly 1 column, centered
     - `cases`: 1 or 2 columns, left-aligned
     - `eqnarray`: Exactly 3 columns with r-c-l alignment
     */
    public static func table(withEnvironment env: String?, alignment: ColumnAlignment? = nil, rows: [[MathList]]) throws(ParseError) -> MathAtom {
        let table = MathTable(environment: env)

        for i in 0..<rows.count {
            let row = rows[i]
            for j in 0..<row.count {
                table.set(cell: row[j], forRow: i, column: j)
            }
        }

        if env == nil {
            table.interColumnSpacing = 0
            table.interRowAdditionalSpacing = 1
            for i in 0..<table.numColumns {
                table.set(alignment: .left, forColumn: i)
            }
            return table
        } else if let env = env {
            if let delims = matrixEnvs[env] {
                table.environment = "matrix"

                // smallmatrix uses script style and tighter spacing for inline use
                let isSmallMatrix = (env == "smallmatrix")

                table.interRowAdditionalSpacing = 0
                table.interColumnSpacing = isSmallMatrix ? 6 : 18

                let style = MathStyle(style: isSmallMatrix ? .script : .text)

                for i in 0..<table.cells.count {
                    for j in 0..<table.cells[i].count {
                        table.cells[i][j].insert(style, at: 0)
                    }
                }

                // Apply alignment for starred matrix environments
                if let align = alignment {
                    for col in 0..<table.numColumns {
                        table.set(alignment: align, forColumn: col)
                    }
                }

                if delims.count == 2 {
                    let inner = Inner()
                    inner.leftBoundary = Self.boundary(forDelimiter: delims[0])
                    inner.rightBoundary = Self.boundary(forDelimiter: delims[1])
                    inner.innerList = MathList(atoms: [table])
                    return inner
                } else {
                    return table
                }
            } else if env == "eqalign" || env == "split" || env == "aligned" {
                if env == "split" && table.numColumns > 2 {
                    throw .invalidNumColumns("split environment can have at most 2 columns")
                }

                let spacer = MathAtom(type: .ordinary, value: "")

                for i in 0..<table.cells.count {
                    var colIndex = 1
                    while colIndex < table.cells[i].count {
                        table.cells[i][colIndex].insert(spacer, at: 0)
                        colIndex += 2
                    }
                }

                table.interRowAdditionalSpacing = 1
                table.interColumnSpacing = 0

                for col in 0..<table.numColumns {
                    table.set(alignment: col % 2 == 0 ? .right : .left, forColumn: col)
                }

                return table
            } else if env == "displaylines" || env == "gather" {
                if table.numColumns != 1 {
                    throw .invalidNumColumns("\(env) environment can only have 1 column")
                }

                table.interRowAdditionalSpacing = 1
                table.interColumnSpacing = 0

                table.set(alignment: .center, forColumn: 0)

                return table
            } else if env == "eqnarray" {
                if table.numColumns != 3 {
                    throw .invalidNumColumns("\(env) environment can only have 3 columns")
                }

                table.interRowAdditionalSpacing = 1
                table.interColumnSpacing = 18

                table.set(alignment: .right, forColumn: 0)
                table.set(alignment: .center, forColumn: 1)
                table.set(alignment: .left, forColumn: 2)

                return table
            } else if env == "cases" {
                if table.numColumns != 1 && table.numColumns != 2 {
                    throw .invalidNumColumns("cases environment can have 1 or 2 columns")
                }

                table.interRowAdditionalSpacing = 0
                table.interColumnSpacing = 18

                table.set(alignment: .left, forColumn: 0)
                if table.numColumns == 2 {
                    table.set(alignment: .left, forColumn: 1)
                }

                let style = MathStyle(style: .text)
                for i in 0..<table.cells.count {
                    for j in 0..<table.cells[i].count {
                        table.cells[i][j].insert(style, at: 0)
                    }
                }

                let inner = Inner()
                inner.leftBoundary = Self.boundary(forDelimiter: "{")
                inner.rightBoundary = Self.boundary(forDelimiter: ".")
                let space = Self.atom(forLatexSymbol: ",")!

                inner.innerList = MathList(atoms: [space, table])

                return inner
            } else {
                throw .invalidEnv("Unknown environment \(env)")
            }
        }
        throw .internalError("Unexpected nil environment")
    }

    @available(*, deprecated, message: "Use the throwing variant: table(withEnvironment:alignment:rows:) throws(ParseError)")
    public static func table(withEnvironment env: String?, alignment: ColumnAlignment? = nil, rows: [[MathList]], error:inout NSError?) -> MathAtom? {
        do {
            return try table(withEnvironment: env, alignment: alignment, rows: rows)
        } catch {
            return nil
        }
    }
}
