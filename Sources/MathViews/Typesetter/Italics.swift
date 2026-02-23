import CoreText
import Foundation

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Character Style Mapping

/// Unicode block offsets for a single math font style.
///
/// Each optional field is the start code point for that character class in this style's
/// Unicode Mathematical Alphanumeric Symbols block. `nil` means the style doesn't cover
/// that class (the caller provides a fallback).
private struct CharStyleMap {
    var exceptions: [Character: UTF32Char] = [:]
    var upperEnglish: UTF32Char?
    var lowerEnglish: UTF32Char?
    var capitalGreek: UTF32Char?
    var lowerGreek: UTF32Char?
    var greekSymbol: UTF32Char?
    var number: UTF32Char?
}

/// Apply a style map to a character, returning `nil` if no mapping covers it.
private func applyMap(_ character: Character, _ map: CharStyleMap) -> UTF32Char? {
    if let exceptionValue = map.exceptions[character] { return exceptionValue }
    let codePoint = character.utf32Char
    if character.isUpperEnglish, let rangeStart = map.upperEnglish { return rangeStart + (codePoint - Character("A").utf32Char) }
    if character.isLowerEnglish, let rangeStart = map.lowerEnglish { return rangeStart + (codePoint - Character("a").utf32Char) }
    if character.isCapitalGreek, let rangeStart = map.capitalGreek { return rangeStart + (codePoint - UnicodeSymbol.capitalGreekStart) }
    if character.isLowerGreek, let rangeStart = map.lowerGreek { return rangeStart + (codePoint - UnicodeSymbol.lowerGreekStart) }
    if character.isGreekSymbol, let rangeStart = map.greekSymbol { return rangeStart + character.greekSymbolOrder! }
    if character.isNumber, let rangeStart = map.number { return rangeStart + (codePoint - Character("0").utf32Char) }
    return nil
}

// Style maps — one per font style that uses Unicode block offsets.

private let italicMap = CharStyleMap(
    exceptions: ["h": UnicodeSymbol.planksConstant, "\u{0131}": 0x1D6A4, "\u{0237}": 0x1D6A5],
    upperEnglish: UnicodeSymbol.capitalItalicStart,
    lowerEnglish: UnicodeSymbol.lowerItalicStart,
    capitalGreek: UnicodeSymbol.greekCapitalItalicStart,
    lowerGreek: UnicodeSymbol.greekLowerItalicStart,
    greekSymbol: UnicodeSymbol.greekSymbolItalicStart
)

private let boldMap = CharStyleMap(
    upperEnglish: UnicodeSymbol.mathCapitalBoldStart,
    lowerEnglish: UnicodeSymbol.mathLowerBoldStart,
    capitalGreek: UnicodeSymbol.greekCapitalBoldStart,
    lowerGreek: UnicodeSymbol.greekLowerBoldStart,
    greekSymbol: UnicodeSymbol.greekSymbolBoldStart,
    number: UnicodeSymbol.numberBoldStart
)

private let boldItalicMap = CharStyleMap(
    upperEnglish: UnicodeSymbol.mathCapitalBoldItalicStart,
    lowerEnglish: UnicodeSymbol.mathLowerBoldItalicStart,
    capitalGreek: UnicodeSymbol.greekCapitalBoldItalicStart,
    lowerGreek: UnicodeSymbol.greekLowerBoldItalicStart,
    greekSymbol: UnicodeSymbol.greekSymbolBoldItalicStart
    // No bold italic numbers in Unicode — falls back to bold in styleCharacter
)

private let calligraphicMap = CharStyleMap(
    exceptions: [
        "B": 0x212C, "E": 0x2130, "F": 0x2131, "H": 0x210B, "I": 0x2110,
        "L": 0x2112, "M": 0x2133, "R": 0x211B,
        "e": 0x212F, "g": 0x210A, "o": 0x2134,
    ],
    upperEnglish: UnicodeSymbol.mathCapitalScriptStart
    // Lower English and non-Latin fall back to defaultStyleChar
)

private let typewriterMap = CharStyleMap(
    upperEnglish: UnicodeSymbol.mathCapitalTTStart,
    lowerEnglish: UnicodeSymbol.mathLowerTTStart,
    number: UnicodeSymbol.numberTTStart
)

private let sansSerifMap = CharStyleMap(
    upperEnglish: UnicodeSymbol.mathCapitalSansSerifStart,
    lowerEnglish: UnicodeSymbol.mathLowerSansSerifStart,
    number: UnicodeSymbol.numberSansSerifStart
)

private let frakturMap = CharStyleMap(
    exceptions: ["C": 0x212D, "H": 0x210C, "I": 0x2111, "R": 0x211C, "Z": 0x2128],
    upperEnglish: UnicodeSymbol.mathCapitalFrakturStart,
    lowerEnglish: UnicodeSymbol.mathLowerFrakturStart
)

private let blackboardMap = CharStyleMap(
    exceptions: [
        "C": 0x2102, "H": 0x210D, "N": 0x2115, "P": 0x2119,
        "Q": 0x211A, "R": 0x211D, "Z": 0x2124,
    ],
    upperEnglish: UnicodeSymbol.mathCapitalBlackboardStart,
    lowerEnglish: UnicodeSymbol.mathLowerBlackboardStart,
    number: UnicodeSymbol.numberBlackboardStart
)

/// LaTeX default style: italic for letters/Greek symbols, roman for numbers/capital Greek.
private func defaultStyleChar(_ character: Character) -> UTF32Char {
    if character.isLowerEnglish || character.isUpperEnglish || character.isLowerGreek || character.isGreekSymbol {
        return applyMap(character, italicMap) ?? character.utf32Char
    } else if character == "\u{0131}" || character == "\u{0237}" {
        return applyMap(character, italicMap) ?? character.utf32Char
    } else if character.isNumber || character.isCapitalGreek || character == "." {
        return character.utf32Char
    } else {
        preconditionFailure("Unknown character \(character) for default style.")
    }
}

/// Converts `character` to its styled Unicode codepoint for the given `fontStyle`,
/// using the character-style map tables. Falls back to the default (math italic) style
/// for styles that don't cover the character's class.
func styleCharacter(_ character: Character, fontStyle: FontStyle) -> UTF32Char {
    switch fontStyle {
        case .defaultStyle: return defaultStyleChar(character)
        case .roman: return character.utf32Char
        case .italic: return applyMap(character, italicMap) ?? character.utf32Char
        case .bold: return applyMap(character, boldMap) ?? character.utf32Char
        case .boldItalic:
            // Bold italic numbers fall back to bold since Unicode has no bold-italic digits.
            return applyMap(character, boldItalicMap)
                ?? (character.isNumber ? applyMap(character, boldMap) ?? character.utf32Char : character.utf32Char)
        case .calligraphic: return applyMap(character, calligraphicMap) ?? defaultStyleChar(character)
        case .typewriter: return applyMap(character, typewriterMap) ?? defaultStyleChar(character)
        case .sansSerif: return applyMap(character, sansSerifMap) ?? defaultStyleChar(character)
        case .fraktur: return applyMap(character, frakturMap) ?? defaultStyleChar(character)
        case .blackboard: return applyMap(character, blackboardMap) ?? defaultStyleChar(character)
    }
}

/// Converts every character in `input` to its styled Unicode codepoint for `fontStyle`.
func changeFont(_ input: String, fontStyle: FontStyle) -> String {
    var result = ""
    let codes = Array(input)
    for i in 0 ..< input.count {
        let character = codes[i]
        var unicode = styleCharacter(character, fontStyle: fontStyle)
        unicode = NSSwapHostIntToLittle(unicode)
        let charStr = String(UnicodeScalar(unicode)!)
        result.append(charStr)
    }
    return result
}

/// Extracts the ascent and descent from a CoreText bounding box rectangle,
/// clamping negative values to zero.
func bboxDetails(_ bbox: CGRect, ascent: inout CGFloat, descent: inout CGFloat) {
    ascent = max(0, bbox.maxY)

    // Descent is how much the line goes below the origin. However if the line is all above the origin, then descent can't be negative.
    descent = max(0, 0 - bbox.minY)
}
