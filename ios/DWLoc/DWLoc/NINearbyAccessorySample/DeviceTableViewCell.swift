import UIKit

enum asset: UInt8 {
    // Index for each label.
    case actionButton = 1
    case scanning     = 2
    case miniLocation = 3
}

class DeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var accessoryButton: UIButton!
    @IBOutlet weak var miniLocation: UIView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var azimuthLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var scanning: UIImageView!
    
    var uniqueID: Int = 0
    
    func selectAsset(_ asset: asset) {
        miniLocation.isHidden = true
        actionButton.isHidden = true
        scanning.isHidden     = true
        
        scanning.stopAnimating()
        
        switch asset {
        case .actionButton:
            actionButton.isHidden = false
        case .scanning:
            scanning.startAnimating()
            scanning.isHidden     = false
        case .miniLocation:
            miniLocation.isHidden = false
        }
    }
}
