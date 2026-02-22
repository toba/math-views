import Foundation

#if os(iOS) || os(visionOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public struct MathImage {
    public var font: MathFont = .latinModernFont
    public var fontSize: CGFloat
    public var textColor: MathColor

    public var labelMode: MathUILabelMode
    public var textAlignment: MathTextAlignment

    public var contentInsets: MathEdgeInsets = MathEdgeInsetsZero
    
    public let latex: String
    
    private(set) var intrinsicContentSize = CGSize.zero

    public init(latex: String, fontSize: CGFloat, textColor: MathColor, labelMode: MathUILabelMode = .display, textAlignment: MathTextAlignment = .center) {
        self.latex = latex
        self.fontSize = fontSize
        self.textColor = textColor
        self.labelMode = labelMode
        self.textAlignment = textAlignment
    }
}
extension MathImage {
    public var currentStyle: LineStyle {
        switch labelMode {
            case .display: return .display
            case .text: return .text
        }
    }
    private func intrinsicContentSize(_ displayList: MathListDisplay) -> CGSize {
        CGSize(width: displayList.width + contentInsets.left + contentInsets.right,
               height: displayList.ascent + displayList.descent + contentInsets.top + contentInsets.bottom)
    }
    public struct LayoutInfo {
        public var ascent: CGFloat = 0
        public var descent: CGFloat = 0

        public init(ascent: CGFloat, descent: CGFloat) {
            self.ascent = ascent
            self.descent = descent
        }
    }
    public mutating func asImage() -> (NSError?, PlatformImage?, LayoutInfo?) {
        func layoutImage(size: CGSize, displayList: MathListDisplay) {
            var textX = CGFloat(0)
            switch self.textAlignment {
                case .left:   textX = contentInsets.left
                case .center: textX = (size.width - contentInsets.left - contentInsets.right - displayList.width) / 2 + contentInsets.left
                case .right:  textX = size.width - displayList.width - contentInsets.right
            }
            let availableHeight = size.height - contentInsets.bottom - contentInsets.top
            
            // center things vertically
            var height = displayList.ascent + displayList.descent
            if height < fontSize/2 {
                height = fontSize/2  // set height to half the font size
            }
            let textY = (availableHeight - height) / 2 + displayList.descent + contentInsets.bottom
            displayList.position = CGPoint(x: textX, y: textY)
        }
        var error: NSError?
        let mtfont: MTFont? = font.mtfont(size: fontSize)

        guard let mathList = MathListBuilder.build(fromString: latex, error: &error), error == nil,
              let displayList = Typesetter.createLineForMathList(mathList, font: mtfont, style: currentStyle) else {
            return (error, nil, nil)
        }

        intrinsicContentSize = intrinsicContentSize(displayList)
        displayList.textColor = textColor

        let size = intrinsicContentSize.regularized
        layoutImage(size: size, displayList: displayList)
        
        #if os(iOS) || os(visionOS)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { rendererContext in
                rendererContext.cgContext.saveGState()
                rendererContext.cgContext.concatenate(.flippedVertically(size.height))
                displayList.draw(rendererContext.cgContext)
                rendererContext.cgContext.restoreGState()
            }
            return (nil, image, LayoutInfo(ascent: displayList.ascent, descent: displayList.descent))
        #endif
        #if os(macOS)
            let image = NSImage(size: size, flipped: false) { bounds in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }
                context.saveGState()
                displayList.draw(context)
                context.restoreGState()
                return true
            }
            return (nil, image, LayoutInfo(ascent: displayList.ascent, descent: displayList.descent))
        #endif
    }
}
private extension CGAffineTransform {
    static func flippedVertically(_ height: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -height)
        return transform
    }
}
extension CGSize {
    fileprivate var regularized: CGSize {
        CGSize(width: ceil(width), height: ceil(height))
    }
}
