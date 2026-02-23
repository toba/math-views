import Foundation
import CoreGraphics

/// Tokenizes MathAtom lists into breakable elements
final class AtomTokenizer {
    // MARK: - Properties

    let font: FontInstance
    let style: LineStyle
    let cramped: Bool
    let maxWidth: CGFloat
    let widthCalculator: ElementWidthCalculator
    let displayRenderer: DisplayPreRenderer

    // MARK: - Initialization

    init(font: FontInstance, style: LineStyle, cramped: Bool = false, maxWidth: CGFloat = 0) {
        self.font = font
        self.style = style
        self.cramped = cramped
        self.maxWidth = maxWidth
        widthCalculator = ElementWidthCalculator(font: font, style: style)
        displayRenderer = DisplayPreRenderer(font: font, style: style, cramped: cramped)
    }

    // MARK: - Main Tokenization

    /// Tokenize a list of atoms into breakable elements
    func tokenize(_ atoms: [MathAtom]) -> [BreakableElement] {
        var elements: [BreakableElement] = []
        var index = 0
        var currentStyle = style

        while index < atoms.count {
            let atom = atoms[index]
            let prevAtom = index > 0 ? atoms[index - 1] : nil

            // Check for style change atoms
            if atom.type == .style, let styleAtom = atom as? MathStyle {
                // Update style for subsequent atoms
                currentStyle = styleAtom.style
                index += 1
                continue
            }

            // Create a tokenizer with the current style for this atom
            let atomTokenizer: AtomTokenizer
            if currentStyle != style {
                atomTokenizer = AtomTokenizer(
                    font: font, style: currentStyle, cramped: cramped, maxWidth: maxWidth,
                )
            } else {
                atomTokenizer = self
            }

            // Handle scripts (subscript/superscript) - these must be grouped with their base
            if atom.superScript != nil || atom.subScript != nil {
                let baseElements = atomTokenizer.tokenizeAtomWithScripts(
                    atom, prevAtom: prevAtom, atomIndex: index, allAtoms: atoms,
                )
                elements.append(contentsOf: baseElements)
            } else {
                // Check if this is a multi-character text atom that needs character-level tokenization
                let isTextAtom = atom.fontStyle == .roman
                let isMultiChar = atom.nucleus.count > 1

                if isTextAtom, isMultiChar {
                    // Break down multi-character text into individual characters for punctuation rules
                    let charElements = atomTokenizer.tokenizeMultiCharText(
                        atom, prevElements: elements, atomIndex: index, allAtoms: atoms,
                    )
                    elements.append(contentsOf: charElements)
                } else {
                    // Regular atom without scripts
                    if let element = atomTokenizer.tokenizeAtom(
                        atom, prevAtom: prevAtom, atomIndex: index, allAtoms: atoms,
                    ) {
                        elements.append(element)
                    }
                }
            }

            index += 1
        }

        return elements
    }

    // MARK: - Atom Tokenization

    /// Tokenize a single atom (without scripts)
    private func tokenizeAtom(
        _ atom: MathAtom, prevAtom: MathAtom?, atomIndex: Int, allAtoms: [MathAtom],
    ) -> BreakableElement? {
        switch atom.type {
            // Simple text and variables
            case .ordinary, .variable, .number:
                return tokenizeTextAtom(
                    atom,
                    prevAtom: prevAtom,
                    atomIndex: atomIndex,
                    allAtoms: allAtoms,
                )

            // Operators
            case .binaryOperator, .relation, .unaryOperator:
                return tokenizeOperator(atom, prevAtom: prevAtom, atomIndex: atomIndex)

            // Delimiters
            case .open:
                return tokenizeOpenDelimiter(atom, prevAtom: prevAtom, atomIndex: atomIndex)

            case .close:
                return tokenizeCloseDelimiter(atom, prevAtom: prevAtom, atomIndex: atomIndex)

            // Punctuation
            case .punctuation:
                return tokenizePunctuation(atom, prevAtom: prevAtom, atomIndex: atomIndex)

            // Complex structures (atomic)
            case .fraction:
                guard let fraction = atom as? Fraction else { return nil }
                return tokenizeFraction(fraction, prevAtom: prevAtom, atomIndex: atomIndex)

            case .radical:
                guard let radical = atom as? Radical else { return nil }
                return tokenizeRadical(radical, prevAtom: prevAtom, atomIndex: atomIndex)

            case .largeOperator:
                guard let largeOp = atom as? LargeOperator else { return nil }
                return tokenizeLargeOperator(
                    largeOp,
                    prevAtom: prevAtom,
                    atomIndex: atomIndex,
                )

            case .accent:
                guard let accent = atom as? Accent else { return nil }
                return tokenizeAccent(
                    accent, prevAtom: prevAtom, atomIndex: atomIndex, allAtoms: allAtoms,
                )

            case .underline:
                guard let underline = atom as? Underline else { return nil }
                return tokenizeUnderline(
                    underline,
                    prevAtom: prevAtom,
                    atomIndex: atomIndex,
                )

            case .overline:
                guard let overline = atom as? Overline else { return nil }
                return tokenizeOverline(overline, prevAtom: prevAtom, atomIndex: atomIndex)

            case .table:
                guard let table = atom as? MathTable else { return nil }
                return tokenizeTable(table, prevAtom: prevAtom, atomIndex: atomIndex)

            case .inner:
                guard let inner = atom as? Inner else { return nil }
                return tokenizeInner(inner, prevAtom: prevAtom, atomIndex: atomIndex)

            // Spacing
            case .space:
                return tokenizeSpace(atom, prevAtom: prevAtom, atomIndex: atomIndex)

            // Style changes - these don't create elements
            case .style:
                return nil

            // Color - extract inner content with color attribute
            case .color, .colorBox, .textColor:
                // For now, treat as ordinary (color will be handled in display generation)
                return tokenizeTextAtom(
                    atom,
                    prevAtom: prevAtom,
                    atomIndex: atomIndex,
                    allAtoms: allAtoms,
                )

            default:
                // Treat unknown types as ordinary
                return tokenizeTextAtom(
                    atom,
                    prevAtom: prevAtom,
                    atomIndex: atomIndex,
                    allAtoms: allAtoms,
                )
        }
    }

    // MARK: - Text Atom Tokenization

    private func tokenizeTextAtom(
        _ atom: MathAtom, prevAtom: MathAtom?, atomIndex: Int, allAtoms: [MathAtom],
    ) -> BreakableElement? {
        let text = atom.nucleus
        guard !text.isEmpty else { return nil }

        // Calculate width
        let width = widthCalculator.measureText(text)

        // Calculate ascent/descent (approximate using font metrics)
        let ascent = font.mathTable?.axisHeight ?? font.fontSize * 0.5
        let descent = font.fontSize * 0.2
        let height = ascent + descent

        // Determine break rules using Unicode word boundary detection
        var isBreakBefore = true
        var isBreakAfter = true
        var penaltyBefore = BreakPenalty.good
        var penaltyAfter = BreakPenalty.good

        let isTextAtom = atom.fontStyle == .roman

        // Only apply word boundary logic to text atoms (not math variables)
        if isTextAtom {
            // First apply punctuation rules for single-character text
            // This handles cases where punctuation appears in roman text rather than as separate punctuation atoms
            if text.count == 1, let char = text.first {
                let (punctBreakBefore, punctBreakAfter, punctPenaltyBefore, punctPenaltyAfter) =
                    punctuationBreakRules(char)

                // Apply punctuation rules
                isBreakBefore = punctBreakBefore
                penaltyBefore = punctPenaltyBefore
                isBreakAfter = punctBreakAfter
                penaltyAfter = punctPenaltyAfter
            }

            // Then apply word boundary logic - this ANDs with punctuation rules
            // Both rules must allow breaking for a break to be permitted

            // Check if we should break BEFORE this atom
            if let prevAtom {
                // Handle previous accent atoms (e.g., "é" before "r" in "bactéries")
                if prevAtom.type == .accent, isTextLetterAtom(prevAtom) {
                    // Previous is a text accent - don't break if current is a letter
                    if text.first?.isLetter == true {
                        isBreakBefore = false
                        penaltyBefore = BreakPenalty.never
                    }
                } else if prevAtom.fontStyle == .roman {
                    let prevText = prevAtom.nucleus
                    if !prevText.isEmpty, !text.isEmpty {
                        // Use Unicode word boundary detection
                        if !hasWordBoundaryBetween(prevText, and: text) {
                            // No word boundary = we're in the middle of a word
                            isBreakBefore = false
                            penaltyBefore = BreakPenalty.never
                        }
                    }
                }
            }

            // Check if we should break AFTER this atom
            if atomIndex + 1 < allAtoms.count {
                let nextAtom = allAtoms[atomIndex + 1]
                // Handle next accent atoms (e.g., "t" before "é" in "bactéries")
                if nextAtom.type == .accent, isTextLetterAtom(nextAtom) {
                    // Next is a text accent - don't break if current is a letter
                    if text.last?.isLetter == true {
                        isBreakAfter = false
                        penaltyAfter = BreakPenalty.never
                    }
                } else if nextAtom.fontStyle == .roman {
                    let nextText = nextAtom.nucleus
                    if !text.isEmpty, !nextText.isEmpty {
                        // Use Unicode word boundary detection
                        if !hasWordBoundaryBetween(text, and: nextText) {
                            // No word boundary = next atom is part of same word
                            isBreakAfter = false
                            penaltyAfter = BreakPenalty.never
                        }
                    }
                }
            }
        }

        return BreakableElement(
            content: .text(text),
            width: width,
            height: height,
            ascent: ascent,
            descent: descent,
            isBreakBefore: isBreakBefore,
            isBreakAfter: isBreakAfter,
            penaltyBefore: penaltyBefore,
            penaltyAfter: penaltyAfter,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: atom.indexRange,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }

    /// Tokenize a multi-character text atom into individual character elements
    /// This enables character-level line breaking with proper punctuation rules
    private func tokenizeMultiCharText(
        _ atom: MathAtom, prevElements: [BreakableElement], atomIndex: Int, allAtoms: [MathAtom],
    ) -> [BreakableElement] {
        let text = atom.nucleus
        guard text.count > 1 else { return [] }

        var charElements: [BreakableElement] = []
        let characters = Array(text)

        for (charIndex, char) in characters.enumerated() {
            let charString = String(char)

            // Calculate width for this character
            let width = widthCalculator.measureText(charString)

            // Calculate ascent/descent (approximate using font metrics)
            let ascent = font.mathTable?.axisHeight ?? font.fontSize * 0.5
            let descent = font.fontSize * 0.2
            let height = ascent + descent

            // Determine break rules for this character
            let (isBreakBefore, isBreakAfter, penaltyBefore, penaltyAfter) = characterBreakRules(
                char: char,
                prevChar: charIndex > 0 ? characters[charIndex - 1] : nil,
                nextChar: charIndex < characters.count - 1 ? characters[charIndex + 1] : nil,
                isFirstInAtom: charIndex == 0,
                isLastInAtom: charIndex == characters.count - 1,
                prevElements: prevElements,
                nextAtom: atomIndex + 1 < allAtoms.count ? allAtoms[atomIndex + 1] : nil,
            )

            let element = BreakableElement(
                content: .text(charString),
                width: width,
                height: height,
                ascent: ascent,
                descent: descent,
                isBreakBefore: isBreakBefore,
                isBreakAfter: isBreakAfter,
                penaltyBefore: penaltyBefore,
                penaltyAfter: penaltyAfter,
                groupId: nil,
                parentId: nil,
                originalAtom: atom,
                indexRange: atom.indexRange,
                color: nil,
                backgroundColor: nil,
                indivisible: false,
            )

            charElements.append(element)
        }

        return charElements
    }

    /// Determine break rules for a character in a multi-character text string
    private func characterBreakRules(
        char: Character,
        prevChar: Character?,
        nextChar: Character?,
        isFirstInAtom: Bool,
        isLastInAtom: Bool,
        prevElements: [BreakableElement],
        nextAtom: MathAtom?,
    ) -> (isBreakBefore: Bool, isBreakAfter: Bool, penaltyBefore: Int, penaltyAfter: Int) {
        // Apply punctuation rules
        let (punctBreakBefore, punctBreakAfter, punctPenaltyBefore, punctPenaltyAfter) =
            punctuationBreakRules(char)

        var isBreakBefore = punctBreakBefore
        var isBreakAfter = punctBreakAfter
        var penaltyBefore = punctPenaltyBefore
        var penaltyAfter = punctPenaltyAfter

        // Apply word boundary logic
        // Don't break in the middle of a word (but CJK characters CAN break between each other)
        if let prevChar {
            if char.isLetter && prevChar.isLetter {
                // Check if either character is CJK - CJK allows breaks between characters
                let isCJKBreak = isCJKCharacter(char) || isCJKCharacter(prevChar)

                if !isCJKBreak {
                    // Both letters in same non-CJK script - middle of word, don't break
                    isBreakBefore = false
                    penaltyBefore = BreakPenalty.never
                }
                // else: At least one is CJK - allow break (keep punctBreakBefore value)
            } else if prevChar == "'" || prevChar == "-" {
                // Apostrophe or hyphen - part of word
                isBreakBefore = false
                penaltyBefore = BreakPenalty.never
            }
        } else if isFirstInAtom {
            // First character - check against previous element
            if let lastElement = prevElements.last {
                switch lastElement.content {
                    case let .text(prevText):
                        if let prevLastChar = prevText.last {
                            if char.isLetter && prevLastChar.isLetter {
                                // Check if either character is CJK
                                let isCJKBreak = isCJKCharacter(char) ||
                                    isCJKCharacter(prevLastChar)

                                if !isCJKBreak {
                                    // Both non-CJK letters - don't break
                                    isBreakBefore = false
                                    penaltyBefore = BreakPenalty.never
                                }
                            } else if prevLastChar == "'" || prevLastChar == "-" {
                                isBreakBefore = false
                                penaltyBefore = BreakPenalty.never
                            }
                        }
                    case .display:
                        // Check if previous element is a text-mode accent (e.g., "é")
                        // Accents in text mode should not allow breaks after them if current is a letter
                        if lastElement.originalAtom.type == .accent,
                           isTextLetterAtom(lastElement.originalAtom),
                           char.isLetter
                        {
                            isBreakBefore = false
                            penaltyBefore = BreakPenalty.never
                        }
                    default:
                        break
                }
            }
        }

        if let nextChar {
            if char.isLetter && nextChar.isLetter {
                // Check if either character is CJK
                let isCJKBreak = isCJKCharacter(char) || isCJKCharacter(nextChar)

                if !isCJKBreak {
                    // Both non-CJK letters - middle of word, don't break
                    isBreakAfter = false
                    penaltyAfter = BreakPenalty.never
                }
            } else if nextChar == "'" || nextChar == "-" {
                // Before apostrophe or hyphen - part of word
                isBreakAfter = false
                penaltyAfter = BreakPenalty.never
            }
        } else if isLastInAtom {
            // Last character - check against next atom
            if let nextAtom {
                // Handle next accent atoms (e.g., "t" before "é" in "bactéries")
                if nextAtom.type == .accent, isTextLetterAtom(nextAtom) {
                    if char.isLetter {
                        isBreakAfter = false
                        penaltyAfter = BreakPenalty.never
                    }
                } else if nextAtom.fontStyle == .roman,
                          let nextFirstChar = nextAtom.nucleus.first
                {
                    if char.isLetter, nextFirstChar.isLetter {
                        // Check if either character is CJK
                        let isCJKBreak = isCJKCharacter(char) || isCJKCharacter(nextFirstChar)

                        if !isCJKBreak {
                            // Both non-CJK letters - don't break
                            isBreakAfter = false
                            penaltyAfter = BreakPenalty.never
                        }
                    }
                }
            }
        }

        return (isBreakBefore, isBreakAfter, penaltyBefore, penaltyAfter)
    }

    // MARK: - Word Boundary Detection

    /// Determines if a character is a CJK (Chinese, Japanese, Korean) character
    /// CJK characters can break between each other even though they are technically "letters"
    private func isCJKCharacter(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value

        // CJK Unified Ideographs and extensions
        return (value >= 0x4E00 && value <=
            0x9FFF) // CJK Unified Ideographs (most common Chinese/Japanese kanji)
            || (value >= 0x3400 && value <= 0x4DBF) // CJK Unified Ideographs Extension A
            || (value >= 0x20000 && value <= 0x2A6DF) // CJK Unified Ideographs Extension B
            || (value >= 0x3040 && value <= 0x309F) // Hiragana (Japanese)
            || (value >= 0x30A0 && value <= 0x30FF) // Katakana (Japanese)
            || (value >= 0xAC00 && value <= 0xD7AF) // Hangul Syllables (Korean)
    }

    /// Determines if there's a word boundary between two text fragments
    /// Combines Unicode word segmentation with special handling for contractions and hyphenated words
    private func hasWordBoundaryBetween(_ text1: String, and text2: String) -> Bool {
        // RULE 1: Check for apostrophes and hyphens between letters (contractions and hyphenated words)
        // These should NOT be treated as word boundaries even though Unicode does
        if let lastChar1 = text1.last, let firstChar2 = text2.first {
            // Pattern: letter + apostrophe|hyphen + letter → NOT a word boundary
            if lastChar1.isLetter, firstChar2 == "'" || firstChar2 == "-" {
                return false // Don't break before apostrophe/hyphen
            }
            if lastChar1 == "'" || lastChar1 == "-", firstChar2.isLetter {
                return false // Don't break after apostrophe/hyphen
            }
        }

        // RULE 2: Use Unicode word boundary detection for everything else
        // This properly handles:
        // - International text (café, naïve, etc.)
        // - Various Unicode whitespace characters
        // - Em-dashes, ellipses, and other Unicode punctuation
        // - Complex scripts (Thai, Japanese, etc.)
        let combined = text1 + text2
        let junctionIndex = text1.endIndex

        var wordBoundaries: Set<String.Index> = []
        combined.enumerateSubstrings(
            in: combined.startIndex ..< combined.endIndex,
            options: .byWords,
        ) {
            _, substringRange, _, _ in
            wordBoundaries.insert(substringRange.lowerBound)
            wordBoundaries.insert(substringRange.upperBound)
        }

        return wordBoundaries.contains(junctionIndex)
    }

    // MARK: - Punctuation Classification

    /// Classification for punctuation line breaking rules
    enum PunctuationClass {
        case openingPunctuation // Never break after these: ( [ { " ' « ‹ and CJK 「『（【〔〈《
        case closingPunctuation // Never break before these: ) ] } " ' » › and CJK 」』）】〕〉》
        case sentenceEnding // Never break before these: . , ; : ! ? and CJK 。、！？：；
        case cjkSmallKana // Never break before these: ぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮ
        case neutral // Normal punctuation with no special rules
    }

    /// Classify a character for punctuation line breaking rules
    private func classifyPunctuation(_ char: Character) -> PunctuationClass {
        let scalar = String(char).unicodeScalars.first?.value ?? 0

        // Latin opening punctuation - never break after
        if "([{".contains(char) { return .openingPunctuation }

        // Latin closing punctuation and sentence-ending - never break before
        if ")]}".contains(char) { return .closingPunctuation }
        if ".,;:!?".contains(char) { return .sentenceEnding }

        // Latin quotation marks - opening quotes
        // U+0022 " QUOTATION MARK, U+0027 ' APOSTROPHE
        // U+2018 ' LEFT SINGLE QUOTATION MARK, U+201C " LEFT DOUBLE QUOTATION MARK
        // U+00AB « LEFT-POINTING DOUBLE ANGLE QUOTATION MARK, U+2039 ‹ SINGLE LEFT-POINTING ANGLE QUOTATION MARK
        if scalar == 0x0022 || scalar == 0x0027 // Basic quotes
            || scalar == 0x2018 || scalar == 0x201C // Curly left quotes
            || scalar == 0x00AB || scalar == 0x2039
        { // Guillemets
            return .openingPunctuation
        }

        // Latin quotation marks - closing quotes
        // U+2019 ' RIGHT SINGLE QUOTATION MARK, U+201D " RIGHT DOUBLE QUOTATION MARK
        // U+00BB » RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK, U+203A › SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
        if scalar == 0x2019 || scalar == 0x201D // Curly right quotes
            || scalar == 0x00BB || scalar == 0x203A
        { // Guillemets
            return .closingPunctuation
        }

        // CJK opening brackets (禁則: line-start prohibited)
        // Japanese/Chinese full-width brackets and corner brackets
        if "「『（【〔〈《".contains(char) {
            return .openingPunctuation
        }

        // CJK closing brackets (禁則: line-end prohibited)
        if "」』）】〕〉》".contains(char) {
            return .closingPunctuation
        }

        // CJK sentence-ending punctuation (禁則: line-end prohibited)
        // Japanese/Chinese full-width periods, commas, and other punctuation
        if "。、！？：；".contains(char) {
            return .sentenceEnding
        }

        // CJK small kana (禁則: line-end prohibited)
        // These are smaller versions of hiragana/katakana that must not start a line
        if "ぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮ".contains(char) {
            return .cjkSmallKana
        }

        // CJK iteration marks (禁則: line-end prohibited)
        if "ゝゞヽヾ々〻".contains(char) {
            return .cjkSmallKana // Same rules as small kana
        }

        // CJK prolonged sound mark (禁則: line-end prohibited)
        if char == "ー" {
            return .cjkSmallKana // Same rules as small kana
        }

        return .neutral
    }

    /// Determine break rules for punctuation based on its classification
    private func punctuationBreakRules(_ char: Character) -> (
        isBreakBefore: Bool, isBreakAfter: Bool, penaltyBefore: Int, penaltyAfter: Int,
    ) {
        let classification = classifyPunctuation(char)

        switch classification {
            case .openingPunctuation:
                // Opening punctuation: can break before, NEVER after
                // Examples: ( [ { " ' « 「『
                return (true, false, BreakPenalty.good, BreakPenalty.never)

            case .closingPunctuation:
                // Closing punctuation: NEVER before, can break after
                // Examples: ) ] } " ' » 」』
                return (false, true, BreakPenalty.never, BreakPenalty.good)

            case .sentenceEnding:
                // Sentence-ending punctuation: NEVER before, good break after
                // Examples: . , ; : ! ? 。、
                return (false, true, BreakPenalty.never, BreakPenalty.best)

            case .cjkSmallKana:
                // CJK small kana and iteration marks: NEVER before, can break after
                // Examples: っゃゅょゎ ゝゞ ー
                return (false, true, BreakPenalty.never, BreakPenalty.good)

            case .neutral:
                // Other punctuation: use default rules
                return (true, true, BreakPenalty.good, BreakPenalty.good)
        }
    }

    // MARK: - Operator Tokenization

    private func tokenizeOperator(_ atom: MathAtom, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let op = atom.nucleus
        guard !op.isEmpty else { return nil }

        // Calculate width with operator spacing
        let width = widthCalculator.measureOperator(op, type: atom.type)

        let ascent = font.fontSize * 0.5
        let descent = font.fontSize * 0.2
        let height = ascent + descent

        return BreakableElement(
            content: .operator(op, type: atom.type),
            width: width,
            height: height,
            ascent: ascent,
            descent: descent,
            isBreakBefore: true,
            isBreakAfter: true,
            penaltyBefore: BreakPenalty.best, // Operators are best break points
            penaltyAfter: BreakPenalty.best,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: atom.indexRange,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }

    // MARK: - Delimiter Tokenization

    private func tokenizeOpenDelimiter(_ atom: MathAtom, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let delimiter = atom.nucleus
        let width = widthCalculator.measureText(delimiter)
        let ascent = font.fontSize * 0.6
        let descent = font.fontSize * 0.2

        return BreakableElement(
            content: .text(delimiter),
            width: width,
            height: ascent + descent,
            ascent: ascent,
            descent: descent,
            isBreakBefore: true,
            isBreakAfter: false, // NEVER break after open delimiter
            penaltyBefore: BreakPenalty.acceptable,
            penaltyAfter: BreakPenalty.bad,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: atom.indexRange,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }

    private func tokenizeCloseDelimiter(_ atom: MathAtom, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let delimiter = atom.nucleus
        let width = widthCalculator.measureText(delimiter)
        let ascent = font.fontSize * 0.6
        let descent = font.fontSize * 0.2

        return BreakableElement(
            content: .text(delimiter),
            width: width,
            height: ascent + descent,
            ascent: ascent,
            descent: descent,
            isBreakBefore: false, // NEVER break before close delimiter
            isBreakAfter: true,
            penaltyBefore: BreakPenalty.bad,
            penaltyAfter: BreakPenalty.acceptable,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: atom.indexRange,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }

    // MARK: - Punctuation Tokenization

    private func tokenizePunctuation(_ atom: MathAtom, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let punct = atom.nucleus
        let width = widthCalculator.measureText(punct)
        let ascent = font.fontSize * 0.5
        let descent = font.fontSize * 0.2

        // Apply proper punctuation breaking rules based on character classification
        // Default rules for multi-character punctuation or empty
        var isBreakBefore = false
        var isBreakAfter = true
        var penaltyBefore = BreakPenalty.bad
        var penaltyAfter = BreakPenalty.good

        // For single-character punctuation, use classification rules
        if punct.count == 1, let char = punct.first {
            (isBreakBefore, isBreakAfter, penaltyBefore, penaltyAfter) = punctuationBreakRules(char)
        }

        return BreakableElement(
            content: .text(punct),
            width: width,
            height: ascent + descent,
            ascent: ascent,
            descent: descent,
            isBreakBefore: isBreakBefore,
            isBreakAfter: isBreakAfter,
            penaltyBefore: penaltyBefore,
            penaltyAfter: penaltyAfter,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: atom.indexRange,
            color: nil,
            backgroundColor: nil,
            indivisible: false,
        )
    }

    // MARK: - Script Tokenization

    private func tokenizeAtomWithScripts(
        _ atom: MathAtom, prevAtom: MathAtom?, atomIndex: Int, allAtoms: [MathAtom],
    ) -> [BreakableElement] {
        var elements: [BreakableElement] = []
        let groupId = UUID() // All elements in this group must stay together

        // First, create the base element
        if let baseElement = tokenizeAtom(
            atom, prevAtom: prevAtom, atomIndex: atomIndex, allAtoms: allAtoms,
        ) {
            var modifiedBase = baseElement
            // Modify to be part of group
            modifiedBase = BreakableElement(
                content: baseElement.content,
                width: baseElement.width,
                height: baseElement.height,
                ascent: baseElement.ascent,
                descent: baseElement.descent,
                isBreakBefore: baseElement.isBreakBefore,
                isBreakAfter: false, // Cannot break after base - must include scripts
                penaltyBefore: baseElement.penaltyBefore,
                penaltyAfter: BreakPenalty.never,
                groupId: groupId,
                parentId: nil,
                originalAtom: baseElement.originalAtom,
                indexRange: baseElement.indexRange,
                color: baseElement.color,
                backgroundColor: baseElement.backgroundColor,
                indivisible: baseElement.indivisible,
            )
            elements.append(modifiedBase)
        }

        // Add superscript first if present (matches legacy typesetter order)
        if let superScript = atom.superScript {
            if let scriptDisplay = displayRenderer.renderScript(superScript, isSuper: true) {
                let scriptElement = BreakableElement(
                    content: .script(scriptDisplay, isSuper: true),
                    width: scriptDisplay.width,
                    height: scriptDisplay.ascent + scriptDisplay.descent,
                    ascent: scriptDisplay.ascent,
                    descent: scriptDisplay.descent,
                    isBreakBefore: false, // Must stay with base
                    isBreakAfter: atom.subScript == nil, // Can break after if last script
                    penaltyBefore: BreakPenalty.never,
                    penaltyAfter: atom.subScript == nil ? BreakPenalty.good : BreakPenalty.never,
                    groupId: groupId,
                    parentId: nil,
                    originalAtom: atom,
                    indexRange: atom.indexRange,
                    color: nil,
                    backgroundColor: nil,
                    indivisible: true,
                )
                elements.append(scriptElement)
            }
        }

        // Add subscript after superscript (matches legacy typesetter order)
        if let subScript = atom.subScript {
            if let scriptDisplay = displayRenderer.renderScript(subScript, isSuper: false) {
                let scriptElement = BreakableElement(
                    content: .script(scriptDisplay, isSuper: false),
                    width: scriptDisplay.width,
                    height: scriptDisplay.ascent + scriptDisplay.descent,
                    ascent: scriptDisplay.ascent,
                    descent: scriptDisplay.descent,
                    isBreakBefore: false, // Must stay with base
                    isBreakAfter: true, // Can break after subscript (it's always last)
                    penaltyBefore: BreakPenalty.never,
                    penaltyAfter: BreakPenalty.good,
                    groupId: groupId,
                    parentId: nil,
                    originalAtom: atom,
                    indexRange: atom.indexRange,
                    color: nil,
                    backgroundColor: nil,
                    indivisible: true,
                )
                elements.append(scriptElement)
            }
        }

        return elements
    }

    // MARK: - Complex Structure Tokenization

    /// Creates a BreakableElement from a pre-rendered display and its source atom.
    private func makeDisplayElement(
        _ display: Display,
        atom: MathAtom,
        width: CGFloat? = nil,
        breakBefore: Bool = true,
        breakAfter: Bool = true,
        penaltyBefore: Int = BreakPenalty.good,
        penaltyAfter: Int = BreakPenalty.good,
        indivisible: Bool = true,
    ) -> BreakableElement {
        BreakableElement(
            content: .display(display),
            width: width ?? display.width,
            height: display.ascent + display.descent,
            ascent: display.ascent,
            descent: display.descent,
            isBreakBefore: breakBefore,
            isBreakAfter: breakAfter,
            penaltyBefore: penaltyBefore,
            penaltyAfter: penaltyAfter,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: atom.indexRange,
            color: nil,
            backgroundColor: nil,
            indivisible: indivisible,
        )
    }

    private func tokenizeFraction(_ fraction: Fraction, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let typesetter = Typesetter(withFont: font, style: style, cramped: cramped, spaced: false)
        guard let display = typesetter.makeFraction(fraction) else { return nil }
        return makeDisplayElement(
            display, atom: fraction,
            penaltyBefore: BreakPenalty.moderate, penaltyAfter: BreakPenalty.moderate,
        )
    }

    private func tokenizeRadical(_ radical: Radical, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let typesetter = Typesetter(withFont: font, style: style, cramped: cramped, spaced: false)
        guard let display = typesetter.makeRadical(radical.radicand, range: radical.indexRange)
        else {
            return nil
        }

        // Add degree if present
        if radical.degree != nil {
            // Use .script style (71% size) instead of .scriptOfScript (50% size)
            // This matches TeX standard for radical degrees
            let degree = Typesetter.makeLineDisplay(
                for: radical.degree,
                font: font,
                style: .script,
            )
            display.setDegree(degree, fontMetrics: font.mathTable)
        }

        return makeDisplayElement(display, atom: radical)
    }

    private func tokenizeLargeOperator(_ op: LargeOperator, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        // CRITICAL DISTINCTION:
        // - If op.limits=true (e.g., \sum, \prod, \lim in text mode): Scripts go ABOVE/BELOW
        //   → makeLargeOp() creates LargeOpLimitsDisplay, which is self-contained
        //   → We should NOT clear scripts, let makeLargeOp() handle everything
        //
        // - If op.limits=false (e.g., \int in text mode): Scripts go TO THE SIDE
        //   → makeLargeOp() would create scripts via makeScripts(), causing duplication
        //   → We MUST clear scripts and let tokenizeAtomWithScripts() handle them separately

        let limits = op.hasLimits && (style == .display || style == .text)

        let originalSuperScript = op.superScript
        let originalSubScript = op.subScript

        // Only clear scripts for side-script operators (limits=false)
        if !limits, originalSuperScript != nil || originalSubScript != nil {
            op.superScript = nil
            op.subScript = nil
        }

        let typesetter = Typesetter(withFont: font, style: style, cramped: cramped, spaced: false)
        guard let operatorDisplay = typesetter.makeLargeOp(op) else {
            // Restore scripts before returning
            op.superScript = originalSuperScript
            op.subScript = originalSubScript
            return nil
        }

        // CRITICAL: Handle scripts based on positioning mode
        if !limits {
            // Side-script operators (limits=false): Restore scripts for tokenizeAtomWithScripts to handle
            op.superScript = originalSuperScript
            op.subScript = originalSubScript
        } else {
            // Limit operators (limits=true): Scripts are already rendered in LargeOpLimitsDisplay
            // MUST clear them from atom to prevent tokenizeAtomWithScripts from rendering them again
            op.superScript = nil
            op.subScript = nil
        }

        // CRITICAL: Handle italic correction (delta) for side-script operators
        // When scripts are present and limits is false, the operator width is reduced by delta
        // (see Typesetter.makeLargeOp line 1046-1050)
        // Since we cleared scripts for side-script operators, makeLargeOp() didn't apply this reduction
        var finalWidth = operatorDisplay.width

        if !limits, originalSubScript != nil {
            // Get the italic correction for the operator glyph
            if let glyphDisplay = operatorDisplay as? GlyphDisplay,
               let mathTable = font.mathTable
            {
                let delta = mathTable.italicCorrection(for: glyphDisplay.glyph)
                finalWidth -= delta
            }
        }

        return makeDisplayElement(operatorDisplay, atom: op, width: finalWidth)
    }

    private func tokenizeAccent(
        _ accent: Accent, prevAtom: MathAtom?, atomIndex: Int, allAtoms: [MathAtom],
    ) -> BreakableElement? {
        let typesetter = Typesetter(withFont: font, style: style, cramped: cramped, spaced: false)
        guard let display = typesetter.makeAccent(accent) else { return nil }

        // Determine break rules - accents in text mode should respect word boundaries
        var breakBefore = true
        var breakAfter = true
        var penBefore = BreakPenalty.good
        var penAfter = BreakPenalty.good

        // Check if this accent is in a text context (the accented character is roman text)
        let isTextAccent = accent.innerList?.atoms.first?.fontStyle == .roman

        if isTextAccent {
            if let prevAtom, isTextLetterAtom(prevAtom) {
                breakBefore = false
                penBefore = BreakPenalty.never
            }
            if atomIndex + 1 < allAtoms.count, isTextLetterAtom(allAtoms[atomIndex + 1]) {
                breakAfter = false
                penAfter = BreakPenalty.never
            }
        }

        return makeDisplayElement(
            display, atom: accent,
            breakBefore: breakBefore, breakAfter: breakAfter,
            penaltyBefore: penBefore, penaltyAfter: penAfter,
        )
    }

    /// Helper to check if an atom is a letter in text mode (roman style)
    private func isTextLetterAtom(_ atom: MathAtom) -> Bool {
        if let accent = atom as? Accent {
            if let firstInner = accent.innerList?.atoms.first {
                return isTextLetterAtom(firstInner)
            }
            return false
        }
        if atom.fontStyle == .roman {
            let nucleus = atom.nucleus
            if !nucleus.isEmpty {
                return nucleus.allSatisfy(\.isLetter)
            }
        }
        return false
    }

    private func tokenizeUnderline(_ underline: Underline, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let typesetter = Typesetter(withFont: font, style: style, cramped: cramped, spaced: false)
        guard let display = typesetter.makeUnderline(underline) else { return nil }
        return makeDisplayElement(display, atom: underline)
    }

    private func tokenizeOverline(_ overline: Overline, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let typesetter = Typesetter(withFont: font, style: style, cramped: cramped, spaced: false)
        guard let display = typesetter.makeOverline(overline) else { return nil }
        return makeDisplayElement(display, atom: overline)
    }

    private func tokenizeTable(_ table: MathTable, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let typesetter = Typesetter(
            withFont: font, style: style, cramped: cramped, spaced: false, maxWidth: maxWidth,
        )
        guard let display = typesetter.makeTable(table) else { return nil }
        return makeDisplayElement(
            display, atom: table,
            penaltyBefore: BreakPenalty.moderate, penaltyAfter: BreakPenalty.moderate,
        )
    }

    private func tokenizeInner(_ inner: Inner, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        let typesetter = Typesetter(withFont: font, style: style, cramped: cramped, spaced: false)
        guard let display = typesetter.makeLeftRight(inner) else { return nil }
        return makeDisplayElement(display, atom: inner, indivisible: false)
    }

    private func tokenizeSpace(_ atom: MathAtom, prevAtom _: MathAtom?, atomIndex _: Int)
        -> BreakableElement?
    {
        // Space atoms typically don't participate in breaking
        // They are rendered as-is
        let width = widthCalculator.measureSpace(atom.type)

        return BreakableElement(
            content: .space(width),
            width: width,
            height: 0,
            ascent: 0,
            descent: 0,
            isBreakBefore: false,
            isBreakAfter: false,
            penaltyBefore: BreakPenalty.never,
            penaltyAfter: BreakPenalty.never,
            groupId: nil,
            parentId: nil,
            originalAtom: atom,
            indexRange: atom.indexRange,
            color: nil,
            backgroundColor: nil,
            indivisible: true,
        )
    }
}
