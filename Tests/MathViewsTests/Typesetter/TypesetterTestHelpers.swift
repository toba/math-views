import CoreGraphics

extension CGPoint {
    func isEqual(to p: CGPoint, accuracy: CGFloat) -> Bool {
        abs(x - p.x) < accuracy && abs(y - p.y) < accuracy
    }
}
