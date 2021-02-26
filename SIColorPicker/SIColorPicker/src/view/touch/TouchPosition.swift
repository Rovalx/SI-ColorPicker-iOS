import UIKit

enum TouchPosition {
    case controlCircle(mode: TouchControlMode)
    case colorCircle(angle: CGFloat)
    case hexField
    case previewCircle
    case none
}
