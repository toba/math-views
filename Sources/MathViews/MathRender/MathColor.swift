public import Foundation
#if os(iOS) || os(visionOS)
public import UIKit
#elseif os(macOS)
public import AppKit
#endif

extension MathColor {
    
    public convenience init?(fromHexString hexString:String) {
        if hexString.isEmpty { return nil }
        if !hexString.hasPrefix("#") { return nil }
        
        var rgbValue = UInt64(0)
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        scanner.scanHexInt64(&rgbValue)
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0,
                  green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0,
                  blue: CGFloat((rgbValue & 0xFF))/255.0,
                  alpha: 1.0)
    }
    
}
