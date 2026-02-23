import CoreText
import Foundation

#if os(iOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

// MARK: - Inter Element Spacing

/// The amount of space to insert between two adjacent atoms.
///
/// TeX defines a matrix of spacing rules indexed by left-atom-type × right-atom-type.
/// Some spacing is suppressed in script styles (sub/superscripts) to keep them compact.
enum InterElementSpaceType: Int {
  case invalid = -1
  case none = 0
  /// Thin space (3 mu). Always applied regardless of style.
  case thin
  /// Thin space (3 mu) but suppressed in script and scriptOfScript styles.
  case nonScriptThin
  /// Medium space (4 mu) but suppressed in script styles.
  case nonScriptMedium
  /// Thick space (5 mu) but suppressed in script styles.
  case nonScriptThick
}

/// The TeX inter-element spacing matrix.
///
/// Rows represent the left atom type, columns the right atom type. The value at
/// `[left][right]` determines how much horizontal space the typesetter inserts.
/// This matrix is derived from Appendix G of *The TeXbook* by Donald Knuth.
let interElementSpaces: [[InterElementSpaceType]] =
  //   ordinary   operator   binary     relation  open       close     punct     fraction
  [
    // ordinary
    [.none, .thin, .nonScriptMedium, .nonScriptThick, .none, .none, .none, .nonScriptThin],
    // operator
    [.thin, .thin, .invalid, .nonScriptThick, .none, .none, .none, .nonScriptThin],
    // binary
    [
      .nonScriptMedium,
      .nonScriptMedium,
      .invalid,
      .invalid,
      .nonScriptMedium,
      .invalid,
      .invalid,
      .nonScriptMedium,
    ],
    // relation
    [
      .nonScriptThick,
      .nonScriptThick,
      .invalid,
      .none,
      .nonScriptThick,
      .none,
      .none,
      .nonScriptThick,
    ],
    // open
    [.none, .none, .invalid, .none, .none, .none, .none, .none],
    // close
    [.none, .thin, .nonScriptMedium, .nonScriptThick, .none, .none, .none, .nonScriptThin],
    // punct
    [
      .nonScriptThin,
      .nonScriptThin,
      .invalid,
      .nonScriptThin,
      .nonScriptThin,
      .nonScriptThin,
      .nonScriptThin,
      .nonScriptThin,
    ],
    // fraction
    [
      .nonScriptThin,
      .thin,
      .nonScriptMedium,
      .nonScriptThick,
      .nonScriptThin,
      .none,
      .nonScriptThin,
      .nonScriptThin,
    ],
    // radical
    [
      .nonScriptMedium,
      .nonScriptThin,
      .nonScriptMedium,
      .nonScriptThick,
      .none,
      .none,
      .none,
      .nonScriptThin,
    ],
  ]

/// Maps a ``MathAtomType`` to its row/column index in the inter-element spacing table.
///
/// Pass `row: true` for the left atom and `row: false` for the right atom.
///
/// - Note: Radicals use a dedicated row (index 8) when they appear on the left side
///   of a pair. This is a departure from LaTeX, which treats radicals as ordinary atoms
///   for spacing purposes. The extra row gives `\sqrt{4}4` a thin space after the radical
///   so the adjacent content doesn't collide with the radical sign. When a radical appears
///   on the right side, it is treated as ordinary (index 0).
func interElementSpaceIndex(for type: MathAtomType, row: Bool) -> Int {
  switch type {
  // A placeholder is treated as ordinary
  case .color, .textColor, .colorBox, .ordinary, .placeholder: 0
  case .largeOperator: 1
  case .binaryOperator: 2
  case .relation: 3
  case .open: 4
  case .close: 5
  case .punctuation: 6
  // Fraction and inner are treated the same.
  case .fraction, .inner: 7
  case .radical:
    if row {
      // Radicals have inter element spaces only when on the left side.
      // Note: This is a departure from latex but we don't want \sqrt{4}4 to look weird so we put a space in between.
      // They have the same spacing as ordinary except with ordinary.
      8
    } else {
      // Treat radical as ordinary on the right side
      0
    }
  // Numbers, variables, and unary operators are treated as ordinary
  case .number, .variable, .unaryOperator: 0
  // Decorative types (accent, underline, overline) are treated as ordinary
  case .accent, .underline, .overline, .overbrace, .underbrace: 0
  // Special types that don't typically participate in spacing are treated as ordinary
  case .boundary, .space, .style, .table: 0
  }
}
