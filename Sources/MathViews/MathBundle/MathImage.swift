public import Foundation
public import CoreGraphics
public import SwiftUI

public struct MathImage {
    public var font: MathFont = .latinModernFont
    public var fontSize: CGFloat
    public var textColor: CGColor

    public var labelMode: MathLabelMode
    public var textAlignment: MathTextAlignment

    public var contentInsets: EdgeInsets = EdgeInsets()

    public let latex: String

    private(set) var intrinsicContentSize = CGSize.zero

    public init(latex: String, fontSize: CGFloat, textColor: CGColor, labelMode: MathLabelMode = .display, textAlignment: MathTextAlignment = .center) {
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
        CGSize(width: displayList.width + contentInsets.leading + contentInsets.trailing,
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
    public mutating func asImage() -> (ParseError?, CGImage?, LayoutInfo?) {
        func layoutImage(size: CGSize, displayList: MathListDisplay) {
            var textX = CGFloat(0)
            switch self.textAlignment {
                case .left:   textX = contentInsets.leading
                case .center: textX = (size.width - contentInsets.leading - contentInsets.trailing - displayList.width) / 2 + contentInsets.leading
                case .right:  textX = size.width - displayList.width - contentInsets.trailing
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
        let fontInst: FontInstance? = font.fontInstance(size: fontSize)

        let mathList: MathList
        do {
            mathList = try MathListBuilder.buildChecked(fromString: latex)
        } catch {
            return (error, nil, nil)
        }
        guard let displayList = Typesetter.createLineForMathList(mathList, font: fontInst, style: currentStyle) else {
            return (nil, nil, nil)
        }

        intrinsicContentSize = intrinsicContentSize(displayList)
        #if os(iOS) || os(visionOS)
        displayList.textColor = UIColor(cgColor: textColor)
        #elseif os(macOS)
        displayList.textColor = NSColor(cgColor: textColor) ?? .black
        #endif

        let size = intrinsicContentSize.regularized
        layoutImage(size: size, displayList: displayList)

        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return (nil, nil, nil) }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (nil, nil, nil)
        }

        context.saveGState()
        displayList.draw(context)
        context.restoreGState()

        guard let image = context.makeImage() else {
            return (nil, nil, nil)
        }

        return (nil, image, LayoutInfo(ascent: displayList.ascent, descent: displayList.descent))
    }
}
extension CGSize {
    fileprivate var regularized: CGSize {
        CGSize(width: ceil(width), height: ceil(height))
    }
}
