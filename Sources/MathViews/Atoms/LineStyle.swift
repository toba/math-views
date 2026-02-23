/// The TeX math style that controls sizing and layout of math content.
///
/// Despite the name, this is *not* about visual line styling (solid, dashed, etc.) — it's
/// TeX's concept of "math style" which determines how large atoms render. Each level
/// renders progressively smaller. The typesetter automatically steps down one level for
/// fraction numerators/denominators and for sub/superscripts.
public enum LineStyle: Int, Comparable, Sendable {
    /// Display style — the largest, used for standalone equations (`$$...$$`).
    /// Large operators render at full size with limits above/below.
    case display
    /// Text style — used for inline math (`$...$`).
    /// Large operators render smaller with limits as sub/superscripts.
    case text
    /// Script style — used for first-level sub/superscripts.
    /// Content renders at roughly 70% of text size.
    case script
    /// Script-of-script style — used for nested scripts (e.g. superscript of a superscript).
    /// The smallest level, roughly 50% of text size.
    case scriptOfScript

    public func incremented() -> LineStyle {
        let raw = rawValue + 1
        if let style = LineStyle(rawValue: raw) { return style }
        return .display
    }

    public var isAboveScript: Bool { self < .script }
    public static func < (lhs: LineStyle, rhs: LineStyle) -> Bool { lhs.rawValue < rhs.rawValue }
}
