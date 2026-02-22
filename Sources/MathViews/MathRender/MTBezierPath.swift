import Foundation

#if os(macOS)

extension MathBezierPath {
    func addLine(to point: CGPoint) {
        self.line(to: point)
    }
}

extension MathView {
    
    var backgroundColor:MathColor? {
        get {
            MathColor(cgColor: self.layer?.backgroundColor ?? MathColor.clear.cgColor)
        }
        set {
            self.layer?.backgroundColor = MathColor.clear.cgColor
            self.wantsLayer = true
        }
    }
    
}

#endif

