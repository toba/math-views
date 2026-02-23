import Foundation
import CoreGraphics

#if os(iOS) || os(visionOS)

public import UIKit

public typealias PlatformColor = UIColor

#else

public import AppKit

public typealias PlatformColor = NSColor

#endif
