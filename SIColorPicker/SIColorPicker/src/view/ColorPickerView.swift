import UIKit
import CoreGraphics

public class ColorPickerView: UIView {
    
    // MARK: - fixed values
    private let imagePointSize: CGFloat = 300
    private let circleGradientWidth: CGFloat = 17
    
    // MARK: - ui elements
    // MARK: color preview
    internal var colorPreviewView = UIView()
    internal var colorPreviewLayer = CAShapeLayer()
//    internal var magnificationImage = UIImageView(image: Icon.ic_search.image)
    internal var magnificationImage = UIImageView(image: UIImage(named: "test"))
    
    // MARK: color selection circle
    internal var colorGradientImageView = UIImageView(image: UIImage(named: "hsv_radial_gradient",
                                                                     in: Bundle(for: ColorPickerView.self),
                                                                     compatibleWith: nil))
    internal var colorSelectionThumbView = UIView()
    internal var colorSelectionThumbColorLayer = CAShapeLayer()
    
    // MARK: saturation control
    internal var saturationLayer = CAGradientLayer()
    internal var saturationMaskLayer = CAShapeLayer()
    internal var saturationThumbView = UIView()
    
    // MARK: brightness control
    internal var brightnessLayer = CAGradientLayer()
    internal var brightnessMaskLayer = CAShapeLayer()
    internal var brightnessThumbView = UIView()
    
    // MARK: labels
    internal var hueLabel = UILabel()
    internal var saturationLabel = UILabel()
    internal var lightnessLabel = UILabel()

    // MARK: touch control
    internal var touchProcessor: ColorPickerTouchProcessor! = nil
    
    internal var colorCircleRadius: CGFloat = 0
    internal var controlCircleRadius: CGFloat = 0
    
    internal var actualGradientWidth: CGFloat {
        let scale = colorGradientImageView.bounds.width / imagePointSize
        return circleGradientWidth * scale
    }
    
    internal var circleGradientMid: CGFloat {
        return actualGradientWidth / 2.0
    }
    
    @IBInspectable
    var lineColor: UIColor = UIColor.white {
        didSet {
            colorSelectionThumbColorLayer.strokeColor = lineColor.cgColor
            colorPreviewLayer.strokeColor = lineColor.cgColor
        }
    }
    
    // MARK: - color values
    internal var hsbColor: HSLColor = HSLColor()
    
    public var color: UIColor {
        get {
            return hsbColor.uiColor
        }
        set {
            hsbColor.uiColor = newValue
            hsbColor.alpha = 1
            
            updateColor(false)
            
            let colorPositionAngle = calculateColorAngle(hsbColor.hue)
            positionColorControl(colorPositionAngle, false)
            
            let saturationPositionAngle = calculateSaturationAngle(hsbColor.saturation)
            positionSaturationControl(hsbColor.saturation, saturationPositionAngle, false)
            
            let brightnessPositionAngle = calculateBrightnessAngle(hsbColor.lightness)
            positionBrightnessControl(hsbColor.lightness, brightnessPositionAngle, false)
        }
    }
    
    public var colorUpdated: ((UIColor, Bool) -> Void)?
    public var defaultPreview: Bool = false
    
    // MARK: - ui flags
    internal var animating: Bool = false
    internal var preview: Bool = false
    
    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        initTouchProcessor()
        config()
        addSubViews()
        updateColor(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initTouchProcessor()
        config()
        addSubViews()
        updateColor(false)
    }
    
    deinit {
        colorUpdated = nil
    }
    
    private func initTouchProcessor() {
        touchProcessor = ColorPickerTouchProcessor(view: self)
        touchProcessor.saturationCallback = saturationSelection(_:_:_:_:)
        touchProcessor.colorSelectionCallback = colorSelection(_:_:_:)
        touchProcessor.brightnessCallback = brightnessSelection(_:_:_:_:)
    }
    
    private func config() {
        initColorThumbControlView()
        initColorPreviewView()
        initMagnificationIcon()
        initSaturationControl()
        initBrightnessControl()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let connectionLine = UIBezierPath()
        connectionLine.move(to: bounds.center)
        connectionLine.addLine(to: colorSelectionThumbView.center)
        connectionLine.lineWidth = 2
        lineColor.setStroke()
        connectionLine.stroke()
    }
    
    private func updateColor(_ animate: Bool, finished: Bool = false) {
        let color = hsbColor.uiColor
        let baseColor = hsbColor.baseColor
        
        CATransaction.begin()
        CATransaction.setDisableActions(animate)
        CATransaction.setAnimationDuration(0.3)
        
        colorSelectionThumbColorLayer.fillColor = baseColor.cgColor
        colorPreviewLayer.fillColor = color.cgColor
        magnificationImage.tintColor = color.contrastFontColor
        
        saturationLayer.colors?[0] = hsbColor.saturated(0).cgColor
        saturationLayer.colors?[1] = hsbColor.saturated(1).cgColor
        brightnessLayer.colors?[1] = hsbColor.lightness(0.5).cgColor
        
        CATransaction.commit()
        
        colorUpdated?(color, finished)
        
        hueLabel.text = "H: \(Int(hsbColor.hue * 360))"
        saturationLabel.text = "S: \(Int(hsbColor.saturation * 100))"
        lightnessLabel.text = "L: \(Int(hsbColor.lightness * 100))"
    }
}

// MARK: - touch processing
extension ColorPickerView {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        touchProcessor.touchBegin(touch)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        touchProcessor.touchMoved(touch)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        touchProcessor.touchEnd(touch)
    }
    
    internal func colorSelection(_ value: CGFloat, _ moving: Bool, _ finished: Bool) {
        guard !self.preview else {
            return
        }
        
        self.hsbColor.hue = 1 - degrees(from: value) / 360.0
        updateColor(moving, finished: finished)
        positionColorControl(value, moving)
    }
    
    internal func saturationSelection(_ saturation: CGFloat, _ angle: CGFloat, _ moving: Bool, _ finished: Bool) {
        self.hsbColor.saturation = saturation
        updateColor(moving, finished: finished)
        positionSaturationControl(saturation, angle, moving)
    }
    
    internal func brightnessSelection(_ brightness: CGFloat, _ angle: CGFloat, _ moving: Bool, _ finished: Bool) {
        if brightness <= 0 {
            hsbColor.lightness = 0
        } else if brightness >= 1 {
            hsbColor.lightness = 1
        } else {
            hsbColor.lightness = brightness
        }
        
        updateColor(moving, finished: finished)
        positionBrightnessControl(hsbColor.lightness, angle, moving)
    }
}

// MARK: - angle calculations
extension ColorPickerView {
    internal func calculateColorAngle(_ hue: CGFloat) -> CGFloat {
        let radians = 2 * .pi - rad(from: hue * 360)
        return radians
    }
    
    internal func calculateSaturationAngle(_ saturation: CGFloat) -> CGFloat {
        let baseAngle = saturation * piHalf
        let actualAngle = piThreeQuarter - baseAngle
        
        return actualAngle
    }
    
    internal func calculateBrightnessAngle(_ brightness: CGFloat) -> CGFloat {
        let baseAngle = brightness * piHalf
        let actualAngle = .pi + piQuarter + baseAngle
        
        return actualAngle
    }
}

// MARK: - user input control update
extension ColorPickerView {
    internal func positionSaturationControl(_ saturation: CGFloat, _ angle: CGFloat, _ moving: Bool) {
        var actualAngle = angle
        
        if saturation <= 0 {
            actualAngle = piThreeQuarter
        } else if saturation >= 1 {
            actualAngle = piQuarter
        }
        
        let thumbX = self.bounds.centerX + controlCircleRadius * cos(actualAngle * -1)
        let thumbY = self.bounds.centerY + controlCircleRadius * sin(actualAngle * -1)
        
        self.saturationThumbView.center = CGPoint(x: thumbX, y: thumbY)
    }
    
    internal func positionColorControl(_ angle: CGFloat, _ moving: Bool) {
        let actualAngle = angle + piHalf
        let thumbX = self.bounds.centerX + colorCircleRadius * cos(actualAngle * -1)
        let thumbY = self.bounds.centerY + colorCircleRadius * sin(actualAngle * -1)
        
        if moving {
            self.colorSelectionThumbView.center = CGPoint(x: thumbX, y: thumbY)
        } else {
            UIView.animate(withDuration: 0.25) {
                self.colorSelectionThumbView.center = CGPoint(x: thumbX, y: thumbY)
                self.colorSelectionThumbColorLayer.fillColor = self.hsbColor.baseColor.cgColor
            }
        }
        
        self.setNeedsDisplay()
    }
    
    internal func positionBrightnessControl(_ brightness: CGFloat, _ angle: CGFloat, _ moving: Bool) {
        var actualAngle = angle
        
        if brightness <= 0 {
            actualAngle = -piThreeQuarter
        } else if brightness >= 1 {
            actualAngle = -piQuarter
        }
        
        let thumbX = self.bounds.centerX + controlCircleRadius * cos(actualAngle * -1)
        let thumbY = self.bounds.centerY + controlCircleRadius * sin(actualAngle * -1)
        
        self.brightnessThumbView.center = CGPoint(x: thumbX, y: thumbY)
    }
}

// MARK: - layer delegate override
extension ColorPickerView {
    public override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        return nil
    }
}
