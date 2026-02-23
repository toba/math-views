import Foundation

extension MathAtomFactory {
    /// The master lookup table mapping LaTeX command names to their ``MathAtom`` representations.
    ///
    /// Contains 300+ entries organized into groups:
    /// - Greek letters (`\alpha` … `\omega`, `\Gamma` … `\Omega`)
    /// - Binary operators (`\pm`, `\times`, `\cup`, `\wedge`, …)
    /// - Relations (`\leq`, `\geq`, `\equiv`, `\sim`, …)
    /// - Arrows (`\rightarrow`, `\Leftrightarrow`, `\mapsto`, …)
    /// - Delimiters and punctuation
    /// - Negated relations (`\neq`, `\nleq`, …)
    /// - Miscellaneous symbols (`\infty`, `\partial`, `\nabla`, …)
    /// - Large operators (`\sum`, `\prod`, `\int`, …)
    /// - Named math functions (`\sin`, `\cos`, `\log`, …)
    ///
    /// This table is loaded lazily by ``MathAtomFactory/atom(forLatexSymbol:)`` and cached
    /// for the lifetime of the process.
    static let initialSymbols: [String: MathAtom] = [
        "square": MathAtomFactory.placeholder(),

        // Greek characters
        "alpha": MathAtom(type: .variable, value: "\u{03B1}"),
        "beta": MathAtom(type: .variable, value: "\u{03B2}"),
        "gamma": MathAtom(type: .variable, value: "\u{03B3}"),
        "delta": MathAtom(type: .variable, value: "\u{03B4}"),
        "varepsilon": MathAtom(type: .variable, value: "\u{03B5}"),
        "zeta": MathAtom(type: .variable, value: "\u{03B6}"),
        "eta": MathAtom(type: .variable, value: "\u{03B7}"),
        "theta": MathAtom(type: .variable, value: "\u{03B8}"),
        "iota": MathAtom(type: .variable, value: "\u{03B9}"),
        "kappa": MathAtom(type: .variable, value: "\u{03BA}"),
        "lambda": MathAtom(type: .variable, value: "\u{03BB}"),
        "mu": MathAtom(type: .variable, value: "\u{03BC}"),
        "nu": MathAtom(type: .variable, value: "\u{03BD}"),
        "xi": MathAtom(type: .variable, value: "\u{03BE}"),
        "omicron": MathAtom(type: .variable, value: "\u{03BF}"),
        "pi": MathAtom(type: .variable, value: "\u{03C0}"),
        "rho": MathAtom(type: .variable, value: "\u{03C1}"),
        "varsigma": MathAtom(type: .variable, value: "\u{03C2}"),
        "sigma": MathAtom(type: .variable, value: "\u{03C3}"),
        "tau": MathAtom(type: .variable, value: "\u{03C4}"),
        "upsilon": MathAtom(type: .variable, value: "\u{03C5}"),
        "varphi": MathAtom(type: .variable, value: "\u{03C6}"),
        "chi": MathAtom(type: .variable, value: "\u{03C7}"),
        "psi": MathAtom(type: .variable, value: "\u{03C8}"),
        "omega": MathAtom(type: .variable, value: "\u{03C9}"),
        // We mark the following greek chars as ordinary so that we don't try
        // to automatically italicize them as we do with variables.
        // These characters fall outside the rules of italicization that we have defined.
        "epsilon": MathAtom(type: .ordinary, value: "\u{0001D716}"),
        "vartheta": MathAtom(type: .ordinary, value: "\u{0001D717}"),
        "phi": MathAtom(type: .ordinary, value: "\u{0001D719}"),
        "varrho": MathAtom(type: .ordinary, value: "\u{0001D71A}"),
        "varpi": MathAtom(type: .ordinary, value: "\u{0001D71B}"),
        "varkappa": MathAtom(type: .ordinary, value: "\u{03F0}"),
        // digamma glyphs are missing from Latin Modern Math but present in XITS, Libertinus,
        // and Garamond math fonts. When unavailable the existing fallback renders .notdef.
        "digamma": MathAtom(type: .ordinary, value: "\u{03DD}"),
        "Digamma": MathAtom(type: .ordinary, value: "\u{03DC}"),

        // Capital greek characters
        "Gamma": MathAtom(type: .variable, value: "\u{0393}"),
        "Delta": MathAtom(type: .variable, value: "\u{0394}"),
        "Theta": MathAtom(type: .variable, value: "\u{0398}"),
        "Lambda": MathAtom(type: .variable, value: "\u{039B}"),
        "Xi": MathAtom(type: .variable, value: "\u{039E}"),
        "Pi": MathAtom(type: .variable, value: "\u{03A0}"),
        "Sigma": MathAtom(type: .variable, value: "\u{03A3}"),
        "Upsilon": MathAtom(type: .variable, value: "\u{03A5}"),
        "Phi": MathAtom(type: .variable, value: "\u{03A6}"),
        "Psi": MathAtom(type: .variable, value: "\u{03A8}"),
        "Omega": MathAtom(type: .variable, value: "\u{03A9}"),

        // Open
        "lceil": MathAtom(type: .open, value: "\u{2308}"),
        "lfloor": MathAtom(type: .open, value: "\u{230A}"),
        "langle": MathAtom(type: .open, value: "\u{27E8}"),
        "lgroup": MathAtom(type: .open, value: "\u{27EE}"),

        // Close
        "rceil": MathAtom(type: .close, value: "\u{2309}"),
        "rfloor": MathAtom(type: .close, value: "\u{230B}"),
        "rangle": MathAtom(type: .close, value: "\u{27E9}"),
        "rgroup": MathAtom(type: .close, value: "\u{27EF}"),

        // Arrows
        "leftarrow": MathAtom(type: .relation, value: "\u{2190}"),
        "uparrow": MathAtom(type: .relation, value: "\u{2191}"),
        "rightarrow": MathAtom(type: .relation, value: "\u{2192}"),
        "downarrow": MathAtom(type: .relation, value: "\u{2193}"),
        "leftrightarrow": MathAtom(type: .relation, value: "\u{2194}"),
        "updownarrow": MathAtom(type: .relation, value: "\u{2195}"),
        "nwarrow": MathAtom(type: .relation, value: "\u{2196}"),
        "nearrow": MathAtom(type: .relation, value: "\u{2197}"),
        "searrow": MathAtom(type: .relation, value: "\u{2198}"),
        "swarrow": MathAtom(type: .relation, value: "\u{2199}"),
        "mapsto": MathAtom(type: .relation, value: "\u{21A6}"),
        "Leftarrow": MathAtom(type: .relation, value: "\u{21D0}"),
        "Uparrow": MathAtom(type: .relation, value: "\u{21D1}"),
        "Rightarrow": MathAtom(type: .relation, value: "\u{21D2}"),
        "Downarrow": MathAtom(type: .relation, value: "\u{21D3}"),
        "Leftrightarrow": MathAtom(type: .relation, value: "\u{21D4}"),
        "Updownarrow": MathAtom(type: .relation, value: "\u{21D5}"),
        "longleftarrow": MathAtom(type: .relation, value: "\u{27F5}"),
        "longrightarrow": MathAtom(type: .relation, value: "\u{27F6}"),
        "longleftrightarrow": MathAtom(type: .relation, value: "\u{27F7}"),
        "Longleftarrow": MathAtom(type: .relation, value: "\u{27F8}"),
        "Longrightarrow": MathAtom(type: .relation, value: "\u{27F9}"),
        "Longleftrightarrow": MathAtom(type: .relation, value: "\u{27FA}"),
        "longmapsto": MathAtom(type: .relation, value: "\u{27FC}"),
        "hookrightarrow": MathAtom(type: .relation, value: "\u{21AA}"),
        "hookleftarrow": MathAtom(type: .relation, value: "\u{21A9}"),

        // Relations
        "leq": MathAtom(type: .relation, value: UnicodeSymbol.lessEqual),
        "geq": MathAtom(type: .relation, value: UnicodeSymbol.greaterEqual),
        "leqslant": MathAtom(type: .relation, value: "\u{2A7D}"),
        "geqslant": MathAtom(type: .relation, value: "\u{2A7E}"),
        "neq": MathAtom(type: .relation, value: UnicodeSymbol.notEqual),
        "in": MathAtom(type: .relation, value: "\u{2208}"),
        "notin": MathAtom(type: .relation, value: "\u{2209}"),
        "ni": MathAtom(type: .relation, value: "\u{220B}"),
        "propto": MathAtom(type: .relation, value: "\u{221D}"),
        "mid": MathAtom(type: .relation, value: "\u{2223}"),
        "parallel": MathAtom(type: .relation, value: "\u{2225}"),
        "sim": MathAtom(type: .relation, value: "\u{223C}"),
        "simeq": MathAtom(type: .relation, value: "\u{2243}"),
        "cong": MathAtom(type: .relation, value: "\u{2245}"),
        "approx": MathAtom(type: .relation, value: "\u{2248}"),
        "asymp": MathAtom(type: .relation, value: "\u{224D}"),
        "doteq": MathAtom(type: .relation, value: "\u{2250}"),
        "equiv": MathAtom(type: .relation, value: "\u{2261}"),
        "gg": MathAtom(type: .relation, value: "\u{226B}"),
        "ll": MathAtom(type: .relation, value: "\u{226A}"),
        "prec": MathAtom(type: .relation, value: "\u{227A}"),
        "succ": MathAtom(type: .relation, value: "\u{227B}"),
        "preceq": MathAtom(type: .relation, value: "\u{2AAF}"),
        "succeq": MathAtom(type: .relation, value: "\u{2AB0}"),
        "subset": MathAtom(type: .relation, value: "\u{2282}"),
        "supset": MathAtom(type: .relation, value: "\u{2283}"),
        "subseteq": MathAtom(type: .relation, value: "\u{2286}"),
        "supseteq": MathAtom(type: .relation, value: "\u{2287}"),
        "sqsubset": MathAtom(type: .relation, value: "\u{228F}"),
        "sqsupset": MathAtom(type: .relation, value: "\u{2290}"),
        "sqsubseteq": MathAtom(type: .relation, value: "\u{2291}"),
        "sqsupseteq": MathAtom(type: .relation, value: "\u{2292}"),
        "models": MathAtom(type: .relation, value: "\u{22A7}"),
        "vdash": MathAtom(type: .relation, value: "\u{22A2}"),
        "dashv": MathAtom(type: .relation, value: "\u{22A3}"),
        "bowtie": MathAtom(type: .relation, value: "\u{22C8}"),
        "perp": MathAtom(type: .relation, value: "\u{27C2}"),
        "implies": MathAtom(type: .relation, value: "\u{27F9}"),

        // Negated relations (amssymb)
        // Inequality negations
        "nless": MathAtom(type: .relation, value: "\u{226E}"),
        "ngtr": MathAtom(type: .relation, value: "\u{226F}"),
        "nleq": MathAtom(type: .relation, value: "\u{2270}"),
        "ngeq": MathAtom(type: .relation, value: "\u{2271}"),
        "nleqslant": MathAtom(type: .relation, value: "\u{2A87}"),
        "ngeqslant": MathAtom(type: .relation, value: "\u{2A88}"),
        "lneq": MathAtom(type: .relation, value: "\u{2A87}"),
        "gneq": MathAtom(type: .relation, value: "\u{2A88}"),
        "lneqq": MathAtom(type: .relation, value: "\u{2268}"),
        "gneqq": MathAtom(type: .relation, value: "\u{2269}"),
        "lnsim": MathAtom(type: .relation, value: "\u{22E6}"),
        "gnsim": MathAtom(type: .relation, value: "\u{22E7}"),
        "lnapprox": MathAtom(type: .relation, value: "\u{2A89}"),
        "gnapprox": MathAtom(type: .relation, value: "\u{2A8A}"),

        // Ordering negations
        "nprec": MathAtom(type: .relation, value: "\u{2280}"),
        "nsucc": MathAtom(type: .relation, value: "\u{2281}"),
        "npreceq": MathAtom(type: .relation, value: "\u{22E0}"),
        "nsucceq": MathAtom(type: .relation, value: "\u{22E1}"),
        "precneqq": MathAtom(type: .relation, value: "\u{2AB5}"),
        "succneqq": MathAtom(type: .relation, value: "\u{2AB6}"),
        "precnsim": MathAtom(type: .relation, value: "\u{22E8}"),
        "succnsim": MathAtom(type: .relation, value: "\u{22E9}"),
        "precnapprox": MathAtom(type: .relation, value: "\u{2AB9}"),
        "succnapprox": MathAtom(type: .relation, value: "\u{2ABA}"),

        // Similarity/congruence negations
        "nsim": MathAtom(type: .relation, value: "\u{2241}"),
        "ncong": MathAtom(type: .relation, value: "\u{2247}"),
        "nmid": MathAtom(type: .relation, value: "\u{2224}"),
        "nshortmid": MathAtom(type: .relation, value: "\u{2224}"),
        "nparallel": MathAtom(type: .relation, value: "\u{2226}"),
        "nshortparallel": MathAtom(type: .relation, value: "\u{2226}"),

        // Set relation negations
        "nsubseteq": MathAtom(type: .relation, value: "\u{2288}"),
        "nsupseteq": MathAtom(type: .relation, value: "\u{2289}"),
        "subsetneq": MathAtom(type: .relation, value: "\u{228A}"),
        "supsetneq": MathAtom(type: .relation, value: "\u{228B}"),
        "subsetneqq": MathAtom(type: .relation, value: "\u{2ACB}"),
        "supsetneqq": MathAtom(type: .relation, value: "\u{2ACC}"),
        "varsubsetneq": MathAtom(type: .relation, value: "\u{228A}"),
        "varsupsetneq": MathAtom(type: .relation, value: "\u{228B}"),
        "varsubsetneqq": MathAtom(type: .relation, value: "\u{2ACB}"),
        "varsupsetneqq": MathAtom(type: .relation, value: "\u{2ACC}"),
        "notni": MathAtom(type: .relation, value: "\u{220C}"),
        "nni": MathAtom(type: .relation, value: "\u{220C}"),

        // Triangle negations
        "ntriangleleft": MathAtom(type: .relation, value: "\u{22EA}"),
        "ntriangleright": MathAtom(type: .relation, value: "\u{22EB}"),
        "ntrianglelefteq": MathAtom(type: .relation, value: "\u{22EC}"),
        "ntrianglerighteq": MathAtom(type: .relation, value: "\u{22ED}"),

        // Turnstile negations
        "nvdash": MathAtom(type: .relation, value: "\u{22AC}"),
        "nvDash": MathAtom(type: .relation, value: "\u{22AD}"),
        "nVdash": MathAtom(type: .relation, value: "\u{22AE}"),
        "nVDash": MathAtom(type: .relation, value: "\u{22AF}"),

        // Square subset negations
        "nsqsubseteq": MathAtom(type: .relation, value: "\u{22E2}"),
        "nsqsupseteq": MathAtom(type: .relation, value: "\u{22E3}"),

        // operators
        "times": MathAtomFactory.times(),
        "div": MathAtomFactory.divide(),
        "pm": MathAtom(type: .binaryOperator, value: "\u{00B1}"),
        "dagger": MathAtom(type: .binaryOperator, value: "\u{2020}"),
        "ddagger": MathAtom(type: .binaryOperator, value: "\u{2021}"),
        "mp": MathAtom(type: .binaryOperator, value: "\u{2213}"),
        "setminus": MathAtom(type: .binaryOperator, value: "\u{2216}"),
        "ast": MathAtom(type: .binaryOperator, value: "\u{2217}"),
        "circ": MathAtom(type: .binaryOperator, value: "\u{2218}"),
        "bullet": MathAtom(type: .binaryOperator, value: "\u{2219}"),
        "wedge": MathAtom(type: .binaryOperator, value: "\u{2227}"),
        "vee": MathAtom(type: .binaryOperator, value: "\u{2228}"),
        "cap": MathAtom(type: .binaryOperator, value: "\u{2229}"),
        "cup": MathAtom(type: .binaryOperator, value: "\u{222A}"),
        "wr": MathAtom(type: .binaryOperator, value: "\u{2240}"),
        "uplus": MathAtom(type: .binaryOperator, value: "\u{228E}"),
        "sqcap": MathAtom(type: .binaryOperator, value: "\u{2293}"),
        "sqcup": MathAtom(type: .binaryOperator, value: "\u{2294}"),
        "oplus": MathAtom(type: .binaryOperator, value: "\u{2295}"),
        "ominus": MathAtom(type: .binaryOperator, value: "\u{2296}"),
        "otimes": MathAtom(type: .binaryOperator, value: "\u{2297}"),
        "oslash": MathAtom(type: .binaryOperator, value: "\u{2298}"),
        "odot": MathAtom(type: .binaryOperator, value: "\u{2299}"),
        "star": MathAtom(type: .binaryOperator, value: "\u{22C6}"),
        "cdot": MathAtom(type: .binaryOperator, value: "\u{22C5}"),
        "diamond": MathAtom(type: .binaryOperator, value: "\u{22C4}"),
        "amalg": MathAtom(type: .binaryOperator, value: "\u{2A3F}"),

        // Additional binary operators (amssymb)
        "ltimes": MathAtom(type: .binaryOperator, value: "\u{22C9}"), // left semidirect product
        "rtimes": MathAtom(type: .binaryOperator, value: "\u{22CA}"), // right semidirect product
        "circledast": MathAtom(type: .binaryOperator, value: "\u{229B}"),
        "circledcirc": MathAtom(type: .binaryOperator, value: "\u{229A}"),
        "circleddash": MathAtom(type: .binaryOperator, value: "\u{229D}"),
        "boxdot": MathAtom(type: .binaryOperator, value: "\u{22A1}"),
        "boxminus": MathAtom(type: .binaryOperator, value: "\u{229F}"),
        "boxplus": MathAtom(type: .binaryOperator, value: "\u{229E}"),
        "boxtimes": MathAtom(type: .binaryOperator, value: "\u{22A0}"),
        "divideontimes": MathAtom(type: .binaryOperator, value: "\u{22C7}"),
        "dotplus": MathAtom(type: .binaryOperator, value: "\u{2214}"),
        "lhd": MathAtom(type: .binaryOperator, value: "\u{22B2}"), // left normal subgroup
        "rhd": MathAtom(type: .binaryOperator, value: "\u{22B3}"), // right normal subgroup
        "unlhd": MathAtom(type: .binaryOperator,
                          value: "\u{22B4}"), // left normal subgroup or equal
        "unrhd": MathAtom(type: .binaryOperator,
                          value: "\u{22B5}"), // right normal subgroup or equal
        "intercal": MathAtom(type: .binaryOperator, value: "\u{22BA}"),
        "barwedge": MathAtom(type: .binaryOperator, value: "\u{22BC}"),
        "veebar": MathAtom(type: .binaryOperator, value: "\u{22BB}"),
        "curlywedge": MathAtom(type: .binaryOperator, value: "\u{22CF}"),
        "curlyvee": MathAtom(type: .binaryOperator, value: "\u{22CE}"),
        "doublebarwedge": MathAtom(type: .binaryOperator, value: "\u{2A5E}"),
        "centerdot": MathAtom(type: .binaryOperator, value: "\u{22C5}"), // alias for cdot

        // No limit operators
        "log": MathAtomFactory.`operator`(named: "log", hasLimits: false),
        "lg": MathAtomFactory.`operator`(named: "lg", hasLimits: false),
        "ln": MathAtomFactory.`operator`(named: "ln", hasLimits: false),
        "sin": MathAtomFactory.`operator`(named: "sin", hasLimits: false),
        "arcsin": MathAtomFactory.`operator`(named: "arcsin", hasLimits: false),
        "sinh": MathAtomFactory.`operator`(named: "sinh", hasLimits: false),
        "cos": MathAtomFactory.`operator`(named: "cos", hasLimits: false),
        "arccos": MathAtomFactory.`operator`(named: "arccos", hasLimits: false),
        "cosh": MathAtomFactory.`operator`(named: "cosh", hasLimits: false),
        "tan": MathAtomFactory.`operator`(named: "tan", hasLimits: false),
        "arctan": MathAtomFactory.`operator`(named: "arctan", hasLimits: false),
        "tanh": MathAtomFactory.`operator`(named: "tanh", hasLimits: false),
        "cot": MathAtomFactory.`operator`(named: "cot", hasLimits: false),
        "coth": MathAtomFactory.`operator`(named: "coth", hasLimits: false),
        "sec": MathAtomFactory.`operator`(named: "sec", hasLimits: false),
        "csc": MathAtomFactory.`operator`(named: "csc", hasLimits: false),
        // Additional inverse trig functions
        "arccot": MathAtomFactory.`operator`(named: "arccot", hasLimits: false),
        "arcsec": MathAtomFactory.`operator`(named: "arcsec", hasLimits: false),
        "arccsc": MathAtomFactory.`operator`(named: "arccsc", hasLimits: false),
        // Additional hyperbolic functions
        "sech": MathAtomFactory.`operator`(named: "sech", hasLimits: false),
        "csch": MathAtomFactory.`operator`(named: "csch", hasLimits: false),
        // Inverse hyperbolic functions
        "arcsinh": MathAtomFactory.`operator`(named: "arcsinh", hasLimits: false),
        "arccosh": MathAtomFactory.`operator`(named: "arccosh", hasLimits: false),
        "arctanh": MathAtomFactory.`operator`(named: "arctanh", hasLimits: false),
        "arccoth": MathAtomFactory.`operator`(named: "arccoth", hasLimits: false),
        "arcsech": MathAtomFactory.`operator`(named: "arcsech", hasLimits: false),
        "arccsch": MathAtomFactory.`operator`(named: "arccsch", hasLimits: false),
        "arg": MathAtomFactory.`operator`(named: "arg", hasLimits: false),
        "ker": MathAtomFactory.`operator`(named: "ker", hasLimits: false),
        "dim": MathAtomFactory.`operator`(named: "dim", hasLimits: false),
        "hom": MathAtomFactory.`operator`(named: "hom", hasLimits: false),
        "exp": MathAtomFactory.`operator`(named: "exp", hasLimits: false),
        "deg": MathAtomFactory.`operator`(named: "deg", hasLimits: false),
        "mod": MathAtomFactory.`operator`(named: "mod", hasLimits: false),

        // Limit operators
        "lim": MathAtomFactory.`operator`(named: "lim", hasLimits: true),
        "limsup": MathAtomFactory.`operator`(named: "lim sup", hasLimits: true),
        "liminf": MathAtomFactory.`operator`(named: "lim inf", hasLimits: true),
        "max": MathAtomFactory.`operator`(named: "max", hasLimits: true),
        "min": MathAtomFactory.`operator`(named: "min", hasLimits: true),
        "sup": MathAtomFactory.`operator`(named: "sup", hasLimits: true),
        "inf": MathAtomFactory.`operator`(named: "inf", hasLimits: true),
        "det": MathAtomFactory.`operator`(named: "det", hasLimits: true),
        "Pr": MathAtomFactory.`operator`(named: "Pr", hasLimits: true),
        "gcd": MathAtomFactory.`operator`(named: "gcd", hasLimits: true),

        // Large operators
        "prod": MathAtomFactory.`operator`(named: "\u{220F}", hasLimits: true),
        "coprod": MathAtomFactory.`operator`(named: "\u{2210}", hasLimits: true),
        "sum": MathAtomFactory.`operator`(named: "\u{2211}", hasLimits: true),
        "int": MathAtomFactory.`operator`(named: "\u{222B}", hasLimits: false),
        "iint": MathAtomFactory.`operator`(named: "\u{222C}", hasLimits: false),
        "iiint": MathAtomFactory.`operator`(named: "\u{222D}", hasLimits: false),
        "iiiint": MathAtomFactory.`operator`(named: "\u{2A0C}", hasLimits: false),
        "oint": MathAtomFactory.`operator`(named: "\u{222E}", hasLimits: false),
        "bigwedge": MathAtomFactory.`operator`(named: "\u{22C0}", hasLimits: true),
        "bigvee": MathAtomFactory.`operator`(named: "\u{22C1}", hasLimits: true),
        "bigcap": MathAtomFactory.`operator`(named: "\u{22C2}", hasLimits: true),
        "bigcup": MathAtomFactory.`operator`(named: "\u{22C3}", hasLimits: true),
        "bigodot": MathAtomFactory.`operator`(named: "\u{2A00}", hasLimits: true),
        "bigoplus": MathAtomFactory.`operator`(named: "\u{2A01}", hasLimits: true),
        "bigotimes": MathAtomFactory.`operator`(named: "\u{2A02}", hasLimits: true),
        "biguplus": MathAtomFactory.`operator`(named: "\u{2A04}", hasLimits: true),
        "bigsqcup": MathAtomFactory.`operator`(named: "\u{2A06}", hasLimits: true),

        // Latex command characters
        "{": MathAtom(type: .open, value: "{"),
        "}": MathAtom(type: .close, value: "}"),
        "$": MathAtom(type: .ordinary, value: "$"),
        "&": MathAtom(type: .ordinary, value: "&"),
        "#": MathAtom(type: .ordinary, value: "#"),
        "%": MathAtom(type: .ordinary, value: "%"),
        "_": MathAtom(type: .ordinary, value: "_"),
        " ": MathAtom(type: .ordinary, value: " "),
        "backslash": MathAtom(type: .ordinary, value: "\\"),

        // Punctuation
        // Note: \colon is different from : which is a relation
        "colon": MathAtom(type: .punctuation, value: ":"),
        "cdotp": MathAtom(type: .punctuation, value: "\u{00B7}"),

        // Other symbols
        "degree": MathAtom(type: .ordinary, value: "\u{00B0}"),
        "neg": MathAtom(type: .ordinary, value: "\u{00AC}"),
        "angstrom": MathAtom(type: .ordinary, value: "\u{00C5}"),
        "aa": MathAtom(type: .ordinary, value: "\u{00E5}"), // NEW å
        "ae": MathAtom(type: .ordinary, value: "\u{00E6}"), // NEW æ
        "o": MathAtom(type: .ordinary, value: "\u{00F8}"), // NEW ø
        "oe": MathAtom(type: .ordinary, value: "\u{0153}"), // NEW œ
        "ss": MathAtom(type: .ordinary, value: "\u{00DF}"), // NEW ß
        "cc": MathAtom(type: .ordinary, value: "\u{00E7}"), // NEW ç
        "CC": MathAtom(type: .ordinary, value: "\u{00C7}"), // NEW Ç
        "O": MathAtom(type: .ordinary, value: "\u{00D8}"), // NEW Ø
        "AE": MathAtom(type: .ordinary, value: "\u{00C6}"), // NEW Æ
        "OE": MathAtom(type: .ordinary, value: "\u{0152}"), // NEW Œ
        "|": MathAtom(type: .ordinary, value: "\u{2016}"),
        "vert": MathAtom(type: .ordinary, value: "|"),
        "ldots": MathAtom(type: .ordinary, value: "\u{2026}"),
        "prime": MathAtom(type: .ordinary, value: "\u{2032}"),
        "hbar": MathAtom(type: .ordinary, value: "\u{210F}"),
        "lbar": MathAtom(type: .ordinary, value: "\u{019B}"), // NEW ƛ
        "Im": MathAtom(type: .ordinary, value: "\u{2111}"),
        "ell": MathAtom(type: .ordinary, value: "\u{2113}"),
        "wp": MathAtom(type: .ordinary, value: "\u{2118}"),
        "Re": MathAtom(type: .ordinary, value: "\u{211C}"),
        "mho": MathAtom(type: .ordinary, value: "\u{2127}"),
        "aleph": MathAtom(type: .ordinary, value: "\u{2135}"),
        "beth": MathAtom(type: .ordinary, value: "\u{2136}"),
        "gimel": MathAtom(type: .ordinary, value: "\u{2137}"),
        "daleth": MathAtom(type: .ordinary, value: "\u{2138}"),
        "forall": MathAtom(type: .ordinary, value: "\u{2200}"),
        "exists": MathAtom(type: .ordinary, value: "\u{2203}"),
        "nexists": MathAtom(type: .ordinary, value: "\u{2204}"),
        "emptyset": MathAtom(type: .ordinary, value: "\u{2205}"),
        "varnothing": MathAtom(type: .ordinary, value: "\u{2205}"),
        "nabla": MathAtom(type: .ordinary, value: "\u{2207}"),
        "infty": MathAtom(type: .ordinary, value: "\u{221E}"),
        "angle": MathAtom(type: .ordinary, value: "\u{2220}"),
        "measuredangle": MathAtom(type: .ordinary, value: "\u{2221}"),
        "top": MathAtom(type: .ordinary, value: "\u{22A4}"),
        "bot": MathAtom(type: .ordinary, value: "\u{22A5}"),
        "vdots": MathAtom(type: .ordinary, value: "\u{22EE}"),
        "cdots": MathAtom(type: .ordinary, value: "\u{22EF}"),
        "ddots": MathAtom(type: .ordinary, value: "\u{22F1}"),
        "triangle": MathAtom(type: .ordinary, value: "\u{25B3}"),
        "Box": MathAtom(type: .ordinary, value: "\u{25A1}"),
        "imath": MathAtom(type: .ordinary, value: "\u{0001D6A4}"),
        "jmath": MathAtom(type: .ordinary, value: "\u{0001D6A5}"),
        "upquote": MathAtom(type: .ordinary, value: "\u{0027}"),
        "partial": MathAtom(type: .ordinary, value: "\u{0001D715}"),

        // Spacing — short forms
        ",": MathSpace(space: 3),
        ">": MathSpace(space: 4),
        ";": MathSpace(space: 5),
        "!": MathSpace(space: -3),
        "quad": MathSpace(space: 18), // quad = 1em = 18mu
        "qquad": MathSpace(space: 36), // qquad = 2em
        // Spacing — verbose aliases (same mu values as short forms)
        "thinspace": MathSpace(space: 3), // same as \,
        ":": MathSpace(space: 4), // same as \>
        "medspace": MathSpace(space: 4), // same as \>
        "thickspace": MathSpace(space: 5), // same as \;
        "negthinspace": MathSpace(space: -3), // same as \!
        "negmedspace": MathSpace(space: -4),
        "negthickspace": MathSpace(space: -5),
        "enspace": MathSpace(space: 9), // 0.5em = 9mu

        // Style
        "displaystyle": MathStyle(style: .display),
        "textstyle": MathStyle(style: .text),
        "scriptstyle": MathStyle(style: .script),
        "scriptscriptstyle": MathStyle(style: .scriptOfScript),
    ]

    /// Maps pre-composed Unicode accented characters to their (accent-command, base-character) pairs.
    ///
    /// When the parser encounters an accented character like `á` in the input, it decomposes
    /// it into `\acute{a}` using this table. Keys are the pre-composed characters; values are
    /// tuples of `(accentName, baseCharacter)`.
    static let supportedAccentedCharacters: [Character: (String, String)] = [
        // Acute accents
        "á": ("acute", "a"), "é": ("acute", "e"), "í": ("acute", "i"),
        "ó": ("acute", "o"), "ú": ("acute", "u"), "ý": ("acute", "y"),

        // Grave accents
        "à": ("grave", "a"), "è": ("grave", "e"), "ì": ("grave", "i"),
        "ò": ("grave", "o"), "ù": ("grave", "u"),

        // Circumflex
        "â": ("hat", "a"), "ê": ("hat", "e"), "î": ("hat", "i"),
        "ĵ": ("hat", "j"), // j with circumflex (Esperanto)
        "ô": ("hat", "o"), "û": ("hat", "u"),

        // Umlaut/dieresis
        "ä": ("ddot", "a"), "ë": ("ddot", "e"), "ï": ("ddot", "i"),
        "ö": ("ddot", "o"), "ü": ("ddot", "u"), "ÿ": ("ddot", "y"),

        // Tilde
        "ã": ("tilde", "a"), "ñ": ("tilde", "n"), "õ": ("tilde", "o"),

        // Special characters
        "ç": ("cc", ""), "ø": ("o", ""), "å": ("aa", ""), "æ": ("ae", ""),
        "œ": ("oe", ""), "ß": ("ss", ""),
        "'": ("upquote", ""), // this may be dangerous in math mode

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
}
