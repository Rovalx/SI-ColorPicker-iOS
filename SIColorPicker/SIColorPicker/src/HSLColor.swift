import UIKit

struct HSLColor {
    var hue: CGFloat = 0
    var saturation: CGFloat = 1
    var lightness: CGFloat = 0.5
    var alpha: CGFloat = 1
    
    var uiColor: UIColor {
        get {
            return UIColor(
                UIColor.HSL(
                    hue: hue,
                    saturation: saturation,
                    lightness: lightness
                ),
                alpha: alpha
            )
        }
        mutating set {
            let hsl = newValue.hsl
            saturation = hsl.saturation
            lightness = hsl.lightness
            hue = hsl.hue
            
            if saturation > 1 {
                saturation = 1
            } else if saturation < 0 {
                saturation = 0
            }
            
            if lightness > 1 {
                lightness = 1
            } else if lightness < 0 {
                lightness = 0
            }
            
            alpha = 1
        }
    }
    
    var baseColor: UIColor {
        return UIColor(
            UIColor.HSL(
                hue: hue,
                saturation: 1,
                lightness: 0.5
            ), alpha: 1)
    }
    
    func lightness(_ value: CGFloat) -> UIColor {
        return UIColor(
            UIColor.HSL(
                hue: hue,
                saturation: saturation,
                lightness: value
            ), alpha: 1)
    }
    
    func saturated(_ value: CGFloat) -> UIColor {
        return UIColor(
            UIColor.HSL(
                hue: hue,
                saturation: value,
                lightness: lightness
            ), alpha: 1)
    }
}

/// An extension to provide conversion to and from HSL (hue, saturation, lightness) colors.
extension UIColor {
    
    /// The HSL (hue, saturation, lightness) components of a color.
    struct HSL: Hashable {
        
        /// The hue component of the color, in the range [0, 360°].
        var hue: CGFloat
        /// The saturation component of the color, in the range [0, 100%].
        var saturation: CGFloat
        /// The lightness component of the color, in the range [0, 100%].
        var lightness: CGFloat
        
    }
    
    /// The HSL (hue, saturation, lightness) components of the color.
    var hsl: HSL {
        var (h, s, b) = (CGFloat(), CGFloat(), CGFloat())
        getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        
        let l = ((2.0 - s) * b) / 2.0
        
        switch l {
        case 0.0, 1.0:
            s = 0.0
        case 0.0..<0.5:
            s = (s * b) / (l * 2.0)
        default:
            s = (s * b) / (2.0 - l * 2.0)
        }
        
        return HSL(hue: h,
                   saturation: s,
                   lightness: l)
    }
    
    /// Initializes a color from HSL (hue, saturation, lightness) components.
    /// - parameter hsl: The components used to initialize the color.
    /// - parameter alpha: The alpha value of the color.
    convenience init(_ hsl: HSL, alpha: CGFloat = 1.0) {
        let h = hsl.hue
        var s = hsl.saturation
        let l = hsl.lightness
        
        let t = s * ((l < 0.5) ? l : (1.0 - l))
        let b = l + t
        s = (l > 0.0) ? (2.0 * t / b) : 0.0
        
        self.init(hue: h, saturation: s, brightness: b, alpha: alpha)
    }
    
}
