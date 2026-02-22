import Foundation
import CoreGraphics

/// Pre-renders complex atoms (fractions, radicals, etc.) as Display objects during tokenization
class DisplayPreRenderer {

    // MARK: - Properties

    let font: FontInstance
    let style: LineStyle
    let cramped: Bool

    // MARK: - Initialization

    init(font: FontInstance, style: LineStyle, cramped: Bool) {
        self.font = font
        self.style = style
        self.cramped = cramped
    }

    // MARK: - Script Rendering

    /// Render a script (superscript or subscript) as a display
    func renderScript(_ mathList: MathList, isSuper: Bool) -> Display? {
        let scriptStyle = getScriptStyle()
        let scriptCramped = isSuper ? cramped : true  // Subscripts are always cramped

        // Scale the font for the script style
        let scriptFontSize = Typesetter.getStyleSize(scriptStyle, font: font)
        let scriptFont = font.copy(withSize: scriptFontSize)

        guard let display = Typesetter.createLineForMathList(
            mathList,
            font: scriptFont,
            style: scriptStyle,
            cramped: scriptCramped,
            spaced: false
        ) else {
            return nil
        }

        // If the result is a MathListDisplay with a single subdisplay, unwrap it
        // This matches the behavior of the legacy typesetter
        if let mathListDisplay = display as? MathListDisplay,
           mathListDisplay.subDisplays.count == 1 {
            return mathListDisplay.subDisplays[0]
        }

        return display
    }

    /// Get the appropriate style for scripts
    private func getScriptStyle() -> LineStyle {
        switch style {
        case .display, .text:
            return .script
        case .script, .scriptOfScript:
            return .scriptOfScript
        }
    }

    // MARK: - Helper Methods

    /// Pre-render a simple math list without width constraints
    /// Used for rendering content inside fractions, radicals, etc.
    func renderMathList(_ mathList: MathList?, style renderStyle: LineStyle? = nil, cramped renderCramped: Bool? = nil) -> Display? {
        guard let mathList = mathList else { return nil }

        let actualStyle = renderStyle ?? style
        let actualCramped = renderCramped ?? cramped

        return Typesetter.createLineForMathList(
            mathList,
            font: font,
            style: actualStyle,
            cramped: actualCramped,
            spaced: false
        )
    }
}
