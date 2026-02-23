import CoreText
import Foundation
import CoreGraphics

/// Calculates widths for breakable elements with appropriate spacing
final class ElementWidthCalculator {
    // MARK: - Properties

    let font: FontInstance
    let style: LineStyle

    // MARK: - Initialization

    init(font: FontInstance, style: LineStyle) {
        self.font = font
        self.style = style
    }

    // MARK: - Text Width Measurement

    /// Measure width of simple text
    func measureText(_ text: String) -> CGFloat {
        guard !text.isEmpty else { return 0 }

        let attrString = NSAttributedString(
            string: text,
            attributes: [
                kCTFontAttributeName as NSAttributedString.Key: font.coreTextFont as Any,
            ],
        )
        let line = CTLineCreateWithAttributedString(attrString as CFAttributedString)
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }

    // MARK: - Operator Width Measurement

    /// Measure width of operator with appropriate spacing
    func measureOperator(_ op: String, type: MathAtomType) -> CGFloat {
        let baseWidth = measureText(op)
        let spacing = operatorSpacing(for: type)
        return baseWidth + spacing
    }

    /// Get spacing for an operator (both sides)
    private func operatorSpacing(for type: MathAtomType) -> CGFloat {
        guard let mathTable = font.mathTable else { return 0 }
        let muUnit = mathTable.muUnit

        switch type {
            case .binaryOperator:
                // Binary operators: 4mu on each side = 8mu total
                return 2 * muUnit * 4

            case .relation:
                // Relations: 5mu on each side = 10mu total
                return 2 * muUnit * 5

            case .largeOperator:
                // Large operators in inline mode: 1mu on each side
                if style == .display || style == .text {
                    return 0 // In display mode, handled by LargeOpLimitsDisplay
                }
                return 2 * muUnit * 1

            default:
                return 0
        }
    }

    // MARK: - Display Width Measurement

    /// Measure width of a pre-rendered display
    func measureDisplay(_ display: Display) -> CGFloat {
        display.width
    }

    // MARK: - Space Width Measurement

    /// Get width of explicit spacing command
    func measureSpace(_ spaceType: MathAtomType) -> CGFloat {
        guard let mathTable = font.mathTable else { return 0 }
        let muUnit = mathTable.muUnit

        // Note: These are the explicit spacing commands in LaTeX
        // \, = thin space (3mu)
        // \: = medium space (4mu)
        // \; = thick space (5mu)
        // \quad = 1em
        // \qquad = 2em

        switch spaceType {
            case .space:
                // Default space - context dependent
                // For now, use thin space
                return muUnit * 3
            default:
                return 0
        }
    }

    /// Measure explicit space value
    func measureExplicitSpace(_ width: CGFloat) -> CGFloat {
        width
    }

    // MARK: - Inter-element Spacing

    /// Get inter-element spacing between two atom types
    func interElementSpacing(left: MathAtomType, right: MathAtomType) -> CGFloat {
        let leftIndex = interElementSpaceIndex(for: left, row: true)
        let rightIndex = interElementSpaceIndex(for: right, row: false)
        let spaceArray = interElementSpaces[Int(leftIndex)]
        let spaceType = spaceArray[Int(rightIndex)]

        guard spaceType != .invalid else {
            // Should not happen in well-formed math
            return 0
        }

        let spaceMultiplier = spacingInMu(spaceType)
        if spaceMultiplier > 0, let mathTable = font.mathTable {
            return CGFloat(spaceMultiplier) * mathTable.muUnit
        }
        return 0
    }

    /// Get spacing multiplier in mu units
    private func spacingInMu(_ spaceType: InterElementSpaceType) -> Int {
        switch style {
            case .display, .text:
                switch spaceType {
                    case .none, .invalid:
                        return 0
                    case .thin:
                        return 3
                    case .nonScriptThin, .nonScriptMedium, .nonScriptThick:
                        // ns = non-script, same as regular in display/text mode
                        switch spaceType {
                            case .nonScriptThin: return 3
                            case .nonScriptMedium: return 4
                            case .nonScriptThick: return 5
                            default: return 0
                        }
                }

            case .script, .scriptOfScript:
                switch spaceType {
                    case .none, .invalid:
                        return 0
                    case .thin:
                        return 3
                    case .nonScriptThin, .nonScriptMedium, .nonScriptThick:
                        // In script mode, ns types don't add space
                        return 0
                }
        }
    }
}
