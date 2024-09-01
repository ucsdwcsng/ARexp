import UIKit
import os

public struct Settings {
    var audioHapticEnabled: Bool?
    
    init() {
        audioHapticEnabled = false;
    }
}

public var appSettings: Settings = Settings.init()

// UIButton extension which enables the caller to duplicate a UIButton
extension UIStackView {
    func copyStackView() -> UIStackView? {
        
        // Attempt to duplicate button by archiving and unarchiving the original UIButton
        guard let archived = try? NSKeyedArchiver.archivedData(withRootObject: self,
                                                               requiringSecureCoding: false)
        else {
            fatalError("archivedData failed")
        }
        
        guard let copy = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archived) as? UIStackView
        else {
            fatalError("unarchivedData failed")
        }
        
        return copy
    }
}

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var enableAudioHaptic: UIButton!
    @IBOutlet weak var accessorySample: UIStackView!
    @IBOutlet weak var accessoriesList: UIStackView!
    @IBOutlet weak var scanning: UIImageView!
    @IBOutlet weak var sendMailButton: UIButton!
    
    // Dictionary to co-relate BLE Device Unique ID with its UIStackViews hashValues
    var referenceDict = [Int:UIStackView]()
    
    let logger = os.Logger(subsystem: "com.example.apple-samplecode.NINearbyAccessorySample", category: "Settings")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.bringSubviewToFront(sendMailButton)
        
        // Initialize switches
        
        if appSettings.audioHapticEnabled! {
            enableAudioHaptic.setImage(UIImage(named: "switch_on.svg"), for: .normal)
        }
        else {
            enableAudioHaptic.setImage(UIImage(named: "switch_off.svg"), for: .normal)
        }
        
        updateDeviceList()
        
        // Start the Activity Indicator
        var imageArray = [UIImage]()
        let image = UIImage(named: "spinner.svg")!
        for i in 0...24 {
            imageArray.append(image.rotate(radians: Float(i) * .pi / 12)!)
        }
        scanning.animationImages = imageArray
        scanning.animationDuration = 1
        scanning.startAnimating()
        
        // Initialises the Timer used for update the device list
        _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
            .lightContent
    }
    
    @IBAction func backToMain(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func toggleAudioHaptic(_ sender: Any) {
        if appSettings.audioHapticEnabled! {
            enableAudioHaptic.setImage(UIImage(named: "switch_off.svg"), for: .normal)
            appSettings.audioHapticEnabled = false
        }
        else {
            enableAudioHaptic.setImage(UIImage(named: "switch_on.svg"), for: .normal)
            appSettings.audioHapticEnabled = true
        }
    }
    
    @objc func timerHandler() {
        updateDeviceList()
    }
    
    func updateDeviceList() {
        var removeFromDict: Bool
        
        // Add new devices, if any
        qorvoDevices.forEach { (qorvoDevice) in
            // Check if the device is already included
            if referenceDict[(qorvoDevice?.bleUniqueID)!] == nil {
                // Create a new StackView and add it to the main StackView
                let newDevice: UIStackView = accessorySample.copyStackView()!
                
                if let device = newDevice.arrangedSubviews.first as? UILabel {
                    device.text = qorvoDevice?.blePeripheralName
                }
                if let status = newDevice.arrangedSubviews.last as? UILabel {
                    status.text = qorvoDevice?.blePeripheralStatus
                }
                
                accessoriesList.addArrangedSubview(newDevice)
                UIView.animate(withDuration: 0.2) {
                    newDevice.isHidden =  false
                }

                // Add the new entry to the dictionary
                referenceDict[(qorvoDevice?.bleUniqueID)!] = newDevice
            }
        }
        
        // Remove devices, if they are no longer included
        for (key, value) in referenceDict {
            removeFromDict = true
            
            qorvoDevices.forEach { (qorvoDevice) in
                if key == qorvoDevice?.bleUniqueID {
                    removeFromDict = false
                }
            }

            if removeFromDict {
                referenceDict.removeValue(forKey: key)
                value.removeFromSuperview()
            }
        }
    }
}
