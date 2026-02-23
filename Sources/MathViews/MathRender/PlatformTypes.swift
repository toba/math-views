public import Foundation
public import CoreGraphics

#if os(iOS) || os(visionOS)

public import UIKit
public typealias MathColor = UIColor

#else

public import AppKit
public typealias MathColor = NSColor

#endif
