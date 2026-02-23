import CoreText
import Foundation

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

// MARK: - Typesetter

/// `Typesetter` is the core rendering engine that converts mathematical atom structures (`MathList`)
/// into displayable visual representations (`MathListDisplay`).
///
/// ## Overview
///
/// This class implements the fundamental typesetting algorithm for mathematical equations, following TeX's
/// typesetting rules for spacing, positioning, and layout. It handles:
///
/// - **Atom processing**: Converts mathematical atoms into display objects with proper positioning
/// - **Inter-element spacing**: Applies TeX spacing rules between different atom types (operators, relations, etc.)
/// - **Script positioning**: Places superscripts and subscripts at appropriate positions and sizes
/// - **Line breaking**: Supports automatic line wrapping with intelligent breaking points
/// - **Complex structures**: Handles fractions, radicals, matrices, delimiters, accents, and large operators
///
/// ## Architecture
///
/// The typesetter uses a stateful approach where it maintains:
/// - Current position (`currentPosition`) for placing elements
/// - Display atom array (`displayAtoms`) collecting rendered elements
/// - Font and style information for determining sizes and positioning
/// - Line breaking state when width constraints are active
///
/// ## Line Breaking
///
/// MathViews implements sophisticated multiline support with two complementary mechanisms:
///
/// ### 1. Interatom Line Breaking (Primary)
/// Breaks equations **between atoms** when content exceeds width constraints. This preserves semantic
/// structure and respects TeX spacing rules. Supported for:
/// - Variables, operators, relations, punctuation
/// - Fractions, radicals, large operators (inline when they fit)
/// - Delimited expressions, colored sections, matrices
/// - Atoms with scripts (superscripts/subscripts)
///
/// ### 2. Universal Line Breaking (Fallback)
/// Uses Core Text for Unicode-aware breaking within very long text atoms, with number protection
/// to prevent splitting numerical values.
///
/// ### Advanced Features
/// - **Dynamic line height**: Adjusts spacing based on actual content height (tall fractions get more space)
/// - **Break quality scoring**: Prefers breaking after operators rather than arbitrary positions
/// - **Look-ahead optimization**: Considers upcoming atoms to find better break points
/// - **Early exit optimization**: Skips expensive checks when remaining content clearly fits
///
/// ## Usage
///
/// The main entry point is the static `makeLineDisplay(for:)` method:
///
/// ```swift
/// // Basic rendering (no line breaking)
/// let display = Typesetter.makeLineDisplay(for: mathList, font: font, style: .display)
///
/// // With line breaking support
/// let display = Typesetter.makeLineDisplay(for: mathList, font: font, style: .display, maxWidth: 300)
/// ```
///
/// ## Implementation Notes
///
/// - Total implementation: ~7,900 lines including helper functions and spacing rules
/// - Tokenization infrastructure: Additional ~2,000 lines for advanced line breaking (see `Tokenization/` folder)
/// - Threading: Uses locks for thread-safe access to spacing tables
/// - Performance: Includes early-exit optimizations when content fits within constraints
///
/// For detailed line breaking implementation notes, see `MULTILINE_IMPLEMENTATION_NOTES.md`.
class Typesetter {
  var font: FontInstance!
  var displayAtoms = [Display]()
  var currentPosition = CGPoint.zero
  var style: LineStyle { didSet { _styleFont = nil } }
  private var _styleFont: FontInstance?
  var styleFont: FontInstance {
    if _styleFont == nil {
      _styleFont = font.withSize(Self.styleSize(style, font: font))
    }
    return _styleFont!
  }

  var cramped = false
  var spaced = false
  var maxWidth: CGFloat = 0  // Maximum width for line breaking, 0 means no constraint

  static func makeLineDisplay(
    for mathList: MathList?,
    font: FontInstance?,
    style: LineStyle,
    maxWidth: CGFloat = 0,
  ) -> MathListDisplay? {
    let finalizedList = mathList?.finalized
    return makeLineDisplay(
      for: finalizedList, font: font, style: style, cramped: false, spaced: false,
      maxWidth: maxWidth,
    )
  }

  static func makeLineDisplay(
    for mathList: MathList?,
    font: FontInstance?,
    style: LineStyle,
    cramped: Bool,
    spaced: Bool = false,
    maxWidth: CGFloat = 0,
  ) -> MathListDisplay? {
    assert(font != nil)

    // Always use tokenization approach
    // The tokenization path handles both constrained (maxWidth > 0) and unconstrained (maxWidth = 0) rendering
    return makeLineDisplayWithTokenization(
      for: mathList,
      font: font,
      style: style,
      cramped: cramped,
      spaced: spaced,
      maxWidth: maxWidth,
    )
  }

  static var placeholderColor: PlatformColor { PlatformColor.blue }

  init(
    withFont font: FontInstance?,
    style: LineStyle,
    cramped: Bool,
    spaced: Bool,
    maxWidth: CGFloat = 0,
  ) {
    self.font = font
    displayAtoms = [Display]()
    currentPosition = CGPoint.zero
    self.cramped = cramped
    self.spaced = spaced
    self.maxWidth = maxWidth
    self.style = style
  }

  /// Preprocesses a math list before typesetting: converts variable/number/unary atoms to
  /// ordinary, applies TeX Rule 14 (fusing consecutive ordinary atoms with the same font
  /// style), and converts binary operators to ordinary in unary contexts (Rule 5).
  static func preprocessMathList(_ mathList: MathList?) -> [MathAtom] {
    var preprocessed = [MathAtom]()  //  arrayWithCapacity:ml.atoms.count)
    var prevNode: MathAtom! = nil
    preprocessed.reserveCapacity(mathList!.atoms.count)
    for atom in mathList!.atoms {
      if atom.type == .variable || atom.type == .number {
        // This is not a TeX type node. TeX does this during parsing the input.
        // switch to using the italic math font
        // We convert it to ordinary
        let newFont = changeFont(
          atom.nucleus,
          fontStyle: atom.fontStyle)  // mathItalicize(atom.nucleus)
        atom.type = .ordinary
        atom.nucleus = newFont
      } else if atom.type == .unaryOperator {
        // Neither of these are TeX nodes. TeX treats these as Ordinary. So will we.
        atom.type = .ordinary
      } else if atom.type == .binaryOperator {
        // CRITICAL FIX: Convert binary operators to ordinary (unary) in appropriate contexts
        // According to TeX rules (TeXbook Appendix G, Rule 5), a binary operator is converted
        // to ordinary when it appears after: Bin, Op, Rel, Open, Punct, or at the beginning
        // This handles cases like "=-2" where minus should be unary, not binary
        let shouldConvertToOrdinary: Bool
        if prevNode == nil {
          // At the beginning of the list
          shouldConvertToOrdinary = true
        } else {
          switch prevNode.type {
          case .binaryOperator, .relation, .open, .punctuation, .largeOperator:
            shouldConvertToOrdinary = true
          default:
            shouldConvertToOrdinary = false
          }
        }

        if shouldConvertToOrdinary {
          atom.type = .ordinary
        }
      }

      if atom.type == .ordinary {
        // This is Rule 14 to merge ordinary characters.
        // combine ordinary atoms together
        // CRITICAL FIX: Only fuse atoms with the same fontStyle
        // This prevents fusing roman text (\text{...}) with italic math variables (A, B, etc.)
        // which would cause incorrect line breaking when the combined string is tokenized
        if prevNode != nil, prevNode.type == .ordinary, prevNode.subScript == nil,
          prevNode.superScript == nil, prevNode.fontStyle == atom.fontStyle
        {
          prevNode.fuse(with: atom)
          // skip the current node, we are done here.
          continue
        }
      }

      // Italic correction could be added here or in second pass
      prevNode = atom
      preprocessed.append(atom)
    }
    return preprocessed
  }

  /// Returns the font size for the given style, scaling down for script/scriptOfScript
  /// using the font's OpenType MATH scale-down factors. Clamps to a minimum of 6pt.
  static func styleSize(_ style: LineStyle, font: FontInstance?) -> CGFloat {
    let original = font!.fontSize
    let scaled: CGFloat
    switch style {
    case .display, .text:
      scaled = original
    case .script:
      scaled = original * font!.mathTable!.scriptScaleDown
    case .scriptOfScript:
      scaled = original * font!.mathTable!.scriptScriptScaleDown
    }
    // Apply minimum font size threshold to prevent deeply nested exponents
    // from becoming unreadable (common for expressions like 2^{2^{2^2}})
    // Minimum of 6pt ensures readability while maintaining proper hierarchy
    return max(scaled, 6.0)
  }

  // MARK: - Spacing

  /// Returns the spacing multiplier in mu (1/18 em) for the given inter-element space type,
  /// suppressing non-script spaces when the current style is script or scriptOfScript.
  func spacingInMu(_ type: InterElementSpaceType) -> Int {
    // let valid = [LineStyle.display, .text]
    switch type {
    case .invalid: return -1
    case .none: return 0
    case .thin: return 3
    case .nonScriptThin: return style.isAboveScript ? 3 : 0
    case .nonScriptMedium: return style.isAboveScript ? 4 : 0
    case .nonScriptThick: return style.isAboveScript ? 5 : 0
    }
  }

  /// Computes the horizontal spacing in points between two adjacent atom types.
  func interElementSpace(_ left: MathAtomType, right: MathAtomType) -> CGFloat {
    let leftIndex = interElementSpaceIndex(for: left, row: true)
    let rightIndex = interElementSpaceIndex(for: right, row: false)
    let spaceArray = interElementSpaces[Int(leftIndex)]
    let spaceTypeObj = spaceArray[Int(rightIndex)]
    let spaceType = spaceTypeObj
    assert(spaceType != .invalid, "Invalid space between \(left) and \(right)")

    let spaceMultiplier = spacingInMu(spaceType)
    if spaceMultiplier > 0 {
      // 1 em = size of font in pt. space multiplier is in multiples mu or 1/18 em
      return CGFloat(spaceMultiplier) * styleFont.mathTable!.muUnit
    }
    return 0
  }

  // MARK: - Subscript/Superscript

  /// Returns the line style for sub/superscripts of the current style.
  func scriptStyle() -> LineStyle {
    switch style {
    case .display, .text: return .script
    case .script, .scriptOfScript: return .scriptOfScript
    }
  }

  /// Subscripts are always typeset in cramped style.
  func subscriptCramped() -> Bool { true }

  /// Superscripts are cramped only when the surrounding style is already cramped.
  func superScriptCramped() -> Bool { cramped }

  /// Returns the baseline shift for superscripts, using the cramped variant when appropriate.
  func superScriptShiftUp() -> CGFloat {
    if cramped {
      return styleFont.mathTable!.superscriptShiftUpCramped
    } else {
      return styleFont.mathTable!.superscriptShiftUp
    }
  }

  /// Builds and positions sub/superscript displays for `atom`, attaching them to `display`.
  /// `index` identifies the atom in the parent list; `delta` is the italic correction that
  /// shifts the superscript rightward.
  func makeScripts(_ atom: MathAtom?, display: Display?, index: UInt, delta: CGFloat) {
    guard let atom else { return }
    guard atom.subScript != nil || atom.superScript != nil else { return }
    guard let mathTable = styleFont.mathTable else { return }

    var superScriptShiftUp = 0.0
    var subscriptShiftDown = 0.0

    display?.hasScript = true
    if !(display is CTLineDisplay), let display {
      // get the font in script style
      let scriptFontSize = Self.styleSize(scriptStyle(), font: font)
      let scriptFont = font.withSize(scriptFontSize)
      let scriptFontMetrics = scriptFont.mathTable

      // if it is not a simple line then
      if let scriptFontMetrics {
        superScriptShiftUp = display.ascent - scriptFontMetrics.superscriptBaselineDropMax
        subscriptShiftDown = display.descent + scriptFontMetrics.subscriptBaselineDropMin
      }
    }

    if atom.superScript == nil {
      guard
        let _subscript = Typesetter.makeLineDisplay(
          for: atom.subScript, font: font, style: scriptStyle(), cramped: subscriptCramped(),
        )
      else { return }
      _subscript.type = .subscript
      _subscript.index = Int(index)

      subscriptShiftDown = fmax(subscriptShiftDown, mathTable.subscriptShiftDown)
      subscriptShiftDown = fmax(
        subscriptShiftDown,
        _subscript.ascent - mathTable.subscriptTopMax,
      )
      // add the subscript
      _subscript.position = CGPoint(
        x: currentPosition.x,
        y: currentPosition.y - subscriptShiftDown,
      )
      displayAtoms.append(_subscript)
      // update the position
      currentPosition.x += _subscript.width + mathTable.spaceAfterScript
      return
    }

    guard
      let superScript = Typesetter.makeLineDisplay(
        for: atom.superScript, font: font, style: scriptStyle(), cramped: superScriptCramped(),
      )
    else { return }
    superScript.type = .superscript
    superScript.index = Int(index)
    superScriptShiftUp = fmax(superScriptShiftUp, self.superScriptShiftUp())
    superScriptShiftUp = fmax(
      superScriptShiftUp, superScript.descent + mathTable.superscriptBottomMin,
    )

    if atom.subScript == nil {
      superScript.position = CGPoint(
        x: currentPosition.x, y: currentPosition.y + superScriptShiftUp,
      )
      displayAtoms.append(superScript)
      // update the position
      currentPosition.x += superScript.width + mathTable.spaceAfterScript
      return
    }
    guard
      let ssubscript = Typesetter.makeLineDisplay(
        for: atom.subScript, font: font, style: scriptStyle(), cramped: subscriptCramped(),
      )
    else { return }
    ssubscript.type = .subscript
    ssubscript.index = Int(index)
    subscriptShiftDown = fmax(subscriptShiftDown, mathTable.subscriptShiftDown)

    // joint positioning of subscript & superscript
    let subSuperScriptGap =
      (superScriptShiftUp - superScript.descent) + (subscriptShiftDown - ssubscript.ascent)
    if subSuperScriptGap < mathTable.subSuperscriptGapMin {
      // Set the gap to atleast as much
      subscriptShiftDown += mathTable.subSuperscriptGapMin - subSuperScriptGap
      let superscriptBottomDelta =
        mathTable
        .superscriptBottomMaxWithSubscript - (superScriptShiftUp - superScript.descent)
      if superscriptBottomDelta > 0 {
        // superscript is lower than the max allowed by the font with a subscript.
        superScriptShiftUp += superscriptBottomDelta
        subscriptShiftDown -= superscriptBottomDelta
      }
    }
    // The delta is the italic correction above that shift superscript position
    superScript.position = CGPoint(
      x:
        currentPosition.x + delta, y: currentPosition.y + superScriptShiftUp,
    )
    displayAtoms.append(superScript)
    ssubscript.position = CGPoint(
      x: currentPosition.x,
      y: currentPosition.y - subscriptShiftDown,
    )
    displayAtoms.append(ssubscript)
    currentPosition.x +=
      max(superScript.width + delta, ssubscript.width) + mathTable.spaceAfterScript
  }

  // MARK: - Helper Functions

  /// Converts a location index to `UInt`, clamping negative values to zero.
  func safeUIntFromLocation(_ location: Int) -> UInt {
    if location < 0 { return 0 }
    return UInt(location)
  }
}
