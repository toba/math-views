import Foundation
import SwiftUI

#if os(macOS)

public class MathLabel : NSTextField {
    
    init() {
        super.init(frame: .zero)
        self.stringValue = ""
        self.isBezeled = false
        self.drawsBackground = false
        self.isEditable = false
        self.isSelectable = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Customized getter and setter methods for property text.
    var text:String? {
        get { super.stringValue }
        set { super.stringValue = newValue! }
    }
    
}

#endif
