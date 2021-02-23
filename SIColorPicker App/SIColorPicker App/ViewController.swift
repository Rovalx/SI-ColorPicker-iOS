import UIKit
import SIColorPicker

class ViewController: UINavigationController, ColorPickerResultDelegate {
    var selectedColor: UIColor! {
        didSet {
            print("New color \(selectedColor)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

