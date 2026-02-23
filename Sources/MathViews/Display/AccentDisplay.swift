import CoreText
import Foundation
import QuartzCore

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Renders a mathematical accent above its base expression (e.g. `\hat{x}`, `\tilde{y}`).
///
/// The accent glyph is drawn relative to this display's origin, while the base expression
/// (``accentee``) is positioned at the same origin so the accent sits directly above it.
/// The typesetter may stretch the accent glyph horizontally to match the width of the base.
final class AccentDisplay: Display {
    /// The rendered base expression that the accent decorates.
    /// Positioned at the same origin as this display.
    var accentee: MathListDisplay?

    /// The accent glyph drawn above the base expression.
    /// Positioned relative to this display's origin.
    var accent: GlyphDisplay?

    init(accent glyph: GlyphDisplay?, accentee: MathListDisplay?, range: Range<Int>) {
        super.init()
        accent = glyph
        self.accentee = accentee
        self.accentee?.position = CGPoint.zero
        self.range = range
    }

    override var textColor: PlatformColor? {
        get { super.textColor }
        set {
            super.textColor = newValue
            accentee?.textColor = newValue
            accent?.textColor = newValue
        }
    }

    override var position: CGPoint {
        get { super.position }
        set {
            super.position = newValue
            updateAccenteePosition()
        }
    }

    func updateAccenteePosition() {
        accentee?.position = CGPoint(x: position.x, y: position.y)
    }

    override func draw(_ context: CGContext) {
        super.draw(context)
        accentee?.draw(context)

        context.saveGState()
        context.translateBy(x: position.x, y: position.y)
        context.textPosition = CGPoint.zero

        accent?.draw(context)

        context.restoreGState()
    }
}
