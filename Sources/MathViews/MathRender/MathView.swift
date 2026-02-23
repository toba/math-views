public import SwiftUI

/// Different display styles supported by `MathView`.
///
/// The only significant difference between the two modes is how fractions
/// and limits on large operators are displayed.
public enum MathLabelMode {
    /// Display mode. Equivalent to $$ in TeX
    case display
    /// Text mode. Equivalent to $ in TeX.
    case text
}

/// Horizontal text alignment for `MathView`.
public enum MathTextAlignment: UInt {
    /// Align left.
    case left
    /// Align center.
    case center
    /// Align right.
    case right
}

/// The main SwiftUI view for rendering LaTeX math.
///
/// `MathView` accepts a LaTeX string and renders it natively using CoreText/CoreGraphics.
/// The math is rendered using TeX typesetting rules.
///
/// ```swift
/// MathView(latex: "x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}")
///     .font(.latinModern)
///     .fontSize(24)
/// ```
public struct MathView: View {
    private let latex: String
    private var font: MathFont = .latinModern
    private var fontSize: CGFloat = 20
    private var textColor: Color = .primary
    private var labelMode: MathLabelMode = .display
    private var textAlignment: MathTextAlignment = .center
    private var contentInsets = EdgeInsets()
    private var maxLayoutWidth: CGFloat?

    public init(latex: String) {
        self.latex = latex
    }

    public var body: some View {
        switch render() {
            case let .success(info):
                Canvas { context, _ in
                    context.withCGContext { cgContext in
                        cgContext.saveGState()
                        // Flip coordinates: Canvas is top-left origin,
                        // Display.draw expects bottom-left (CoreGraphics)
                        cgContext.translateBy(x: 0, y: info.size.height)
                        cgContext.scaleBy(x: 1, y: -1)
                        info.displayList.draw(cgContext)
                        cgContext.restoreGState()
                    }
                }
                .frame(width: info.size.width, height: info.size.height)
            case let .failure(error):
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .font(.caption)
        }
    }

    // MARK: - Modifiers

    /// Set the math font.
    public func font(_ font: MathFont) -> MathView {
        var copy = self
        copy.font = font
        return copy
    }

    /// Set the font size in points.
    public func fontSize(_ size: CGFloat) -> MathView {
        var copy = self
        copy.fontSize = size
        return copy
    }

    /// Set the text color.
    public func textColor(_ color: Color) -> MathView {
        var copy = self
        copy.textColor = color
        return copy
    }

    /// Set the label mode (display or text).
    public func labelMode(_ mode: MathLabelMode) -> MathView {
        var copy = self
        copy.labelMode = mode
        return copy
    }

    /// Set the text alignment.
    public func textAlignment(_ alignment: MathTextAlignment) -> MathView {
        var copy = self
        copy.textAlignment = alignment
        return copy
    }

    /// Set content insets.
    public func contentInsets(_ insets: EdgeInsets) -> MathView {
        var copy = self
        copy.contentInsets = insets
        return copy
    }

    /// Set the maximum layout width for line wrapping.
    public func maxLayoutWidth(_ width: CGFloat?) -> MathView {
        var copy = self
        copy.maxLayoutWidth = width
        return copy
    }

    // MARK: - Rendering

    private struct RenderInfo {
        let displayList: MathListDisplay
        let size: CGSize
    }

    private var currentStyle: LineStyle {
        switch labelMode {
            case .display: return .display
            case .text: return .text
        }
    }

    private func render() -> Result<RenderInfo, Error> {
        let mathList: MathList
        do {
            mathList = try MathListBuilder.buildChecked(fromString: latex)
        } catch {
            return .failure(error)
        }

        let fontInst = font.fontInstance(size: fontSize)

        var maxWidth: CGFloat = 0
        if let maxLayoutWidth {
            maxWidth = maxLayoutWidth - contentInsets.leading - contentInsets.trailing
            maxWidth = max(0, maxWidth)
        }

        guard
            let displayList = Typesetter.makeLineDisplay(
                for: mathList, font: fontInst, style: currentStyle, maxWidth: maxWidth,
            )
        else {
            return .success(
                RenderInfo(
                    displayList: MathListDisplay(displays: [], range: 0 ..< 0),
                    size: .zero,
                ),
            )
        }

        // Resolve SwiftUI Color to MathColor (UIColor/NSColor)
        displayList.textColor = resolveMathColor(textColor)

        // Calculate size
        let width = displayList.width + contentInsets.leading + contentInsets.trailing
        let height = displayList.ascent + displayList.descent + contentInsets.top + contentInsets
            .bottom
        let size = CGSize(width: ceil(max(0, width)), height: ceil(max(0, height)))

        // Position the display list
        var textX: CGFloat = 0
        switch textAlignment {
            case .left: textX = contentInsets.leading
            case .center:
                textX =
                    (size.width - contentInsets.leading - contentInsets.trailing - displayList
                        .width) / 2
                    + contentInsets.leading
            case .right: textX = size.width - displayList.width - contentInsets.trailing
        }

        let availableHeight = size.height - contentInsets.bottom - contentInsets.top
        var contentHeight = displayList.ascent + displayList.descent
        if contentHeight < fontSize / 2 {
            contentHeight = fontSize / 2
        }
        let textY = (availableHeight - contentHeight) / 2 + displayList.descent + contentInsets
            .bottom

        displayList.position = CGPoint(x: textX, y: textY)

        return .success(RenderInfo(displayList: displayList, size: size))
    }

    private func resolveMathColor(_ color: Color) -> PlatformColor {
        #if os(iOS) || os(visionOS)
        return UIColor(color)
        #elseif os(macOS)
        return NSColor(color)
        #endif
    }
}
