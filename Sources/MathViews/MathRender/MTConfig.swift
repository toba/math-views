import Foundation

//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by 安志钢.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#if os(iOS) || os(visionOS)

import UIKit

public typealias MathView = UIView
public typealias MathColor = UIColor
public typealias MathBezierPath = UIBezierPath
public typealias MathLabel = UILabel
public typealias MathEdgeInsets = UIEdgeInsets
public typealias MathRect = CGRect
public typealias PlatformImage = UIImage

let MathEdgeInsetsZero = UIEdgeInsets.zero
func MTGraphicsGetCurrentContext() -> CGContext? { UIGraphicsGetCurrentContext() }

#else

import AppKit

public typealias MathView = NSView
public typealias MathColor = NSColor
public typealias MathBezierPath = NSBezierPath
public typealias MathEdgeInsets = NSEdgeInsets
public typealias MathRect = NSRect
public typealias PlatformImage = NSImage

let MathEdgeInsetsZero = NSEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
func MTGraphicsGetCurrentContext() -> CGContext? { NSGraphicsContext.current?.cgContext }

#endif
