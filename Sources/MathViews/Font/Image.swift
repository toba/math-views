public import CoreGraphics
import Foundation
public import SwiftUI

/// Renders a LaTeX string to a `CGImage` for use outside of a view hierarchy.
///
/// Use this when you need a rendered math image for SwiftUI (`Image(cgImage:)`),
/// image export, or any context where hosting a `MathView` isn't practical.
///
/// ```swift
/// var renderer = MathImage(
///     latex: "\\frac{1}{2}",
///     fontSize: 20,
///     textColor: CGColor(gray: 0, alpha: 1)
/// )
/// let (error, image, layout) = renderer.asImage()
/// ```
public struct MathImage {
  public var font: MathFont = .latinModern
  public var fontSize: CGFloat
  public var textColor: CGColor

  public var renderingStyle: RenderingStyle
  public var textAlignment: MathTextAlignment

  public var contentInsets = EdgeInsets()

  public let latex: String

  private(set) var intrinsicContentSize = CGSize.zero

  public init(
    latex: String,
    fontSize: CGFloat,
    textColor: CGColor,
    renderingStyle: RenderingStyle = .display,
    textAlignment: MathTextAlignment = .center,
  ) {
    self.latex = latex
    self.fontSize = fontSize
    self.textColor = textColor
    self.renderingStyle = renderingStyle
    self.textAlignment = textAlignment
  }
}

extension MathImage {
  public var currentStyle: LineStyle {
    switch renderingStyle {
    case .display: return .display
    case .text: return .text
    }
  }

  private func intrinsicContentSize(_ displayList: MathListDisplay) -> CGSize {
    CGSize(
      width: displayList.width + contentInsets.leading + contentInsets.trailing,
      height: displayList.ascent + displayList.descent + contentInsets.top
        + contentInsets
        .bottom,
    )
  }

  /// Baseline metrics from the rendered math display, useful for aligning
  /// the image with surrounding text.
  public struct LayoutInfo {
    /// Distance from the baseline to the top of the tallest glyph.
    public var ascent: CGFloat = 0
    /// Distance from the baseline to the bottom of the lowest glyph.
    public var descent: CGFloat = 0

    public init(ascent: CGFloat, descent: CGFloat) {
      self.ascent = ascent
      self.descent = descent
    }
  }

  public mutating func asImage() -> (ParseError?, CGImage?, LayoutInfo?) {
    func layoutImage(size: CGSize, displayList: MathListDisplay) {
      var textX = CGFloat(0)
      switch textAlignment {
      case .left: textX = contentInsets.leading
      case .center:
        textX =
          (size.width - contentInsets.leading - contentInsets.trailing
            - displayList
            .width) / 2
          + contentInsets.leading
      case .right: textX = size.width - displayList.width - contentInsets.trailing
      }
      let availableHeight = size.height - contentInsets.bottom - contentInsets.top

      // center things vertically
      var height = displayList.ascent + displayList.descent
      if height < fontSize / 2 {
        height = fontSize / 2  // set height to half the font size
      }
      let textY = (availableHeight - height) / 2 + displayList.descent + contentInsets.bottom
      displayList.position = CGPoint(x: textX, y: textY)
    }
    let fontInstance: FontInstance? = font.fontInstance(size: fontSize)

    let mathList: MathList
    do {
      mathList = try MathListBuilder.buildChecked(fromString: latex)
    } catch {
      return (error, nil, nil)
    }
    guard
      let displayList = Typesetter.makeLineDisplay(
        for: mathList, font: fontInstance, style: currentStyle,
      )
    else {
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
    guard
      let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
      )
    else {
      return (nil, nil, nil)
    }

    context.saveGState()
    context.textMatrix = .identity
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
