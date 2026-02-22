import Foundation

public class FontManager {
    
    static public private(set) var manager: FontManager = {
        FontManager()
    }()
    
    let kDefaultFontSize = CGFloat(20)
    
    static var fontManager : FontManager {
        return manager
    }

    public init() { }

    @RWLocked
    var nameToFontMap = [String: FontInstance]()

    public func font(withName name:String, size:CGFloat) -> FontInstance? {
        var f = self.nameToFontMap[name]
        if f == nil {
            f = FontInstance(fontWithName: name, size: size)
            self.nameToFontMap[name] = f
        }
        
        if f!.fontSize == size { return f }
        else { return f!.copy(withSize: size) }
    }
    
    public func latinModernFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "latinmodern-math", size: size)
    }
    
    public func kpMathLightFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "KpMath-Light", size: size)
    }
    
    public func kpMathSansFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "KpMath-Sans", size: size)
    }
    
    public func xitsFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "xits-math", size: size)
    }
    
    public func termesFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "texgyretermes-math", size: size)
    }
    
    public func asanaFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "Asana-Math", size: size)
    }
    
    public func eulerFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "Euler-Math", size: size)
    }
    
    public func firaRegularFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "FiraMath-Regular", size: size)
    }
    
    public func notoSansRegularFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "NotoSansMath-Regular", size: size)
    }
    
    public func libertinusRegularFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "LibertinusMath-Regular", size: size)
    }
    
    public func garamondMathFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "Garamond-Math", size: size)
    }
    
    public func leteSansFont(withSize size:CGFloat) -> FontInstance? {
        FontManager.fontManager.font(withName: "LeteSansMath", size: size)
    }
    
    public var defaultFont: FontInstance? {
        FontManager.fontManager.latinModernFont(withSize: kDefaultFontSize)
    }


}
