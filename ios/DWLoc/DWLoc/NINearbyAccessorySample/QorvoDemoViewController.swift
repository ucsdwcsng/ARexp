import UIKit
import NearbyInteraction
import CoreHaptics
import CoreMotion
import os.log
import MessageUI
import Kronos

enum MessageId: UInt8 {
    // Messages from the accessory.
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3
    
    // Messages to the accessory.
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC
    
    // User defined/notification messages
    case getReserved = 0x20
    case setReserved = 0x21

    case iOSNotify = 0x2F
}

class AccessoryDemoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var infoLabel:      UILabel!
    @IBOutlet weak var deviceLabel:    UILabel!
    @IBOutlet weak var distanceLabel:  UILabel!
    @IBOutlet weak var azimuthLabel:   UILabel!
    @IBOutlet weak var elevationLabel: UILabel!
    
    @IBOutlet weak var accessoriesTable: UITableView!
    
    // Swipe gesture
    @IBOutlet weak var deviceView: UIView!
    @IBOutlet weak var locationView:  UIView!
    @IBOutlet weak var separatorView: UIView!
    
    let qorvoGray = UIColor(red: 249/255, green: 249/255, blue: 249/255, alpha: 1.00)
    let qorvoBlue = UIColor(red: 0.00,    green: 159/255, blue: 1.00,    alpha: 1.00)
    let qorvoRed  = UIColor(red: 1.00,    green: 123/255, blue: 123/255, alpha: 1.00)
    
    var dataChannel = DataCommunicationChannel()
    var configuration: NINearbyAccessoryConfiguration?
    var selectedAccessory = -1
    var selectExpand = true
    
    // Used to animate scanning images
    var imageScanning      = [UIImage]()
    var imageScanningSmall = [UIImage]()
    // Dictionary to associate each NI Session to the qorvoDevice using the uniqueID
    var referenceDict = [Int:NISession]()
    // A mapping from a discovery token to a name.
    var accessoryMap = [NIDiscoveryToken: String]()
    
    var unixTime: TimeInterval?
    var localTimeOffset: TimeInterval = 0
    var systemUptimeOffset: TimeInterval = 0
    
    let logger = os.Logger(subsystem: "com.example.apple-samplecode.NINearbyAccessorySample", category: "AccessoryDemoViewController")
    
    let btnDisabled = "Disabled"
    let btnConnect = "Connect"
    let btnDisconnect = "Disconnect"
    let devNotConnected = "NO ACCESSORY CONNECTED"
    
    var csvFileURL: URL?
    
    @IBOutlet weak var sendMailButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.setTitle("Send Mail", for: .normal)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.red.cgColor
        button.addTarget(self, action: #selector(sendMailButtonTapped), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        dataChannel.accessoryDataHandler = accessorySharedData
        
        // Prepare the data communication channel.
        dataChannel.accessoryDiscoveryHandler = accessoryInclude
        dataChannel.accessoryTimeoutHandler = accessoryRemove
        dataChannel.accessoryConnectedHandler = accessoryConnected
        dataChannel.accessoryDisconnectedHandler = accessoryDisconnected
        dataChannel.accessoryDataHandler = accessorySharedData
        dataChannel.start()
        
        infoLabel.backgroundColor = UIColor.clear
        
        // Start the Activity Indicators
        let image = UIImage(named: "spinner.svg")!
        for i in 0...24 {
            imageScanning.append(image.rotate(radians: Float(i) * .pi / 12)!)
        }
        
        let imageSmall = UIImage(named: "spinner_small.svg")!
        for i in 0...24 {
            imageScanningSmall.append(imageSmall.rotate(radians: Float(i) * .pi / 12)!)
        }

        // Initialises table to stack devices from qorvoDevices
        accessoriesTable.delegate   = self
        accessoriesTable.dataSource = self
        
        createCSVFile()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    
    func createCSVFile() {
        let fileName = "localization.csv"
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let documentURL = URL(fileURLWithPath: documentDirectoryPath)
        csvFileURL = documentURL.appendingPathComponent(fileName)
        
        let columnTitles = "Timestamp,Distance,Azimuth,Elevation,AccX,AccY,AccZ,GyroX,GyroY,GyroZ,GeoX,GeoY,GeoZ\n"
        do {
            try columnTitles.write(to: csvFileURL!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Error creating CSV file: \(error)")
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SettingsViewController {
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return qorvoDevices.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let disconnect = UIContextualAction(style: .normal, title: "") { [self] (action, view, completion) in
            // Send the disconnection message to the device
            let cell = accessoriesTable.cellForRow(at: indexPath) as! DeviceTableViewCell
            let deviceID = cell.uniqueID
            let qorvoDevice = dataChannel.getDeviceFromUniqueID(deviceID)
            
            if qorvoDevice?.blePeripheralStatus != statusDiscovered {
                sendDataToAccessory(Data([MessageId.stop.rawValue]), deviceID)
            }
            completion(true)
        }
        // Set the Contextual action parameters
        disconnect.image = UIImage(named: "trash_bin")
        disconnect.backgroundColor = qorvoRed
        
        let swipeActions = UISwipeActionsConfiguration(actions: [disconnect])
        swipeActions.performsFirstActionWithFullSwipe = false
        
        return swipeActions
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = accessoriesTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DeviceTableViewCell
        
        let qorvoDevice = qorvoDevices[indexPath.row]
        
        cell.uniqueID = (qorvoDevice?.bleUniqueID)!
        
        // Initialize the new cell assets
        cell.tag = indexPath.row
        cell.accessoryButton.tag = indexPath.row
        cell.accessoryButton.setTitle(qorvoDevice?.blePeripheralName, for: .normal)
        cell.accessoryButton.addTarget(self,
                                       action: #selector(buttonSelect),
                                       for: .touchUpInside)
        cell.actionButton.tag = indexPath.row
        cell.actionButton.addTarget(self,
                                    action: #selector(buttonAction),
                                    for: .touchUpInside)
        cell.scanning.animationImages = imageScanningSmall
        cell.scanning.animationDuration = 1
        
        logger.info("New device included at row \(indexPath.row)")
        
        return cell
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        
        if let qorvoDevice = qorvoDevices[sender.tag] {
            let deviceID = qorvoDevice.bleUniqueID
            
            // Connect to the accessory
            if qorvoDevice.blePeripheralStatus == statusDiscovered {
                connectToAccessory(deviceID)
            }
            else {
                return
            }
            
            // Edit cell for this sender
            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.tag == sender.tag {
                    cell.selectAsset(.scanning)
                }
            }
            
            logger.info("Action Button pressed for device \(deviceID)")
        }
    }
    
    @IBAction func buttonSelect(_ sender: UIButton) {
        
        if let qorvoDevice = qorvoDevices[sender.tag] {
            let deviceID = qorvoDevice.bleUniqueID
            
            selectDevice(deviceID)
            logger.info("Select Button pressed for device \(deviceID)")
        }
    }
    
    func selectDevice(_ deviceID: Int) {
        // If an accessory was selected, clear highlight
        if selectedAccessory != -1 {
            
            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.uniqueID == selectedAccessory {
                    cell.accessoryButton.backgroundColor = .white
                }
            }
        }
        
        // Set the new selected accessory
        selectedAccessory = deviceID
        
        // If no accessory is selected, reset location fields
        if deviceID == -1 {
            clearLocationFields()
            
            // Disables Location assets when Qorvo device is not ranging
            enableLocation(false)
            
            deviceLabel.text = "NOT CONNECTED"
            
            return
        }
        
        // If a new accessory is selected initialise location
        if let chosenDevice = dataChannel.getDeviceFromUniqueID(deviceID) {
            
            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.uniqueID == deviceID {
                    cell.accessoryButton.backgroundColor = qorvoGray
                }
            }
            
            logger.info("Selecting device \(deviceID)")
            deviceLabel.text = chosenDevice.blePeripheralName
            
            if chosenDevice.blePeripheralStatus == statusDiscovered {
                // Clear location values
                clearLocationFields()
                // Disables Location assets when Qorvo device is not ranging
                enableLocation(false)
            }
            else {
                // Update location values
                updateLocationFields(deviceID)
                // Enables Location assets when Qorvo device is ranging
                enableLocation(true)
            }
        }
    }
    
    // MARK: - Data channel methods
    func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
        // The accessory begins each message with an identifier byte.
        // Ensure the message length is within a valid range.
        if data.count < 1 {
            infoLabelUpdate(with: "Accessory shared data length was less than 1.")
            return
        }
        
        // Assign the first byte which is the message identifier.
        guard let messageId = MessageId(rawValue: data.first!) else {
            fatalError("\(data.first!) is not a valid MessageId.")
        }
        
        // Handle the data portion of the message based on the message identifier.
        switch messageId {
        case .accessoryConfigurationData:
            // Access the message data by skipping the message identifier.
            assert(data.count > 1)
            let message = data.advanced(by: 1)
            setupAccessory(message, name: accessoryName, deviceID: deviceID)
        case .accessoryUwbDidStart:
            handleAccessoryUwbDidStart(deviceID)
        case .accessoryUwbDidStop:
            handleAccessoryUwbDidStop(deviceID)
        case .configureAndStart:
            fatalError("Accessory should not send 'configureAndStart'.")
        case .initialize:
            fatalError("Accessory should not send 'initialize'.")
        case .stop:
            fatalError("Accessory should not send 'stop'.")
            // User defined/notification messages
        case .getReserved:
            print("Get not implemented in this version")
        case .setReserved:
            print("Set not implemented in this version")
        case .iOSNotify:
            print("Notification not implemented in this version")
        }
    }
    
    func accessoryInclude(index: Int) {
        accessoriesTable.beginUpdates()
        accessoriesTable.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        accessoriesTable.endUpdates()
    }
    
    func accessoryRemove(deviceID: Int) {
        var index = 0
        
        for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
            if cell.uniqueID == deviceID {
                break
            }
            index += 1
        }
        
        accessoriesTable.beginUpdates()
        accessoriesTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        accessoriesTable.endUpdates()
    }
    
    func accessoryUpdate() {
        // Update devices
        qorvoDevices.forEach { (qorvoDevice) in
            for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
                if cell.uniqueID == qorvoDevice?.bleUniqueID {
                    // Update cell based on status
                    if qorvoDevice?.blePeripheralStatus == statusDiscovered {
                        cell.selectAsset(.actionButton)
                    }
                }
            }
        }
    }
    
    func accessoryConnected(deviceID: Int) {
        // If no device is selected, select the new device
        if selectedAccessory == -1 {
            selectDevice(deviceID)
        }
        
        // Create a NISession for the new device
        referenceDict[deviceID] = NISession()
        referenceDict[deviceID]?.delegate = self
        
        infoLabelUpdate(with: "Requesting configuration data from accessory")
        let msg = Data([MessageId.initialize.rawValue])
        
        sendDataToAccessory(msg, deviceID)
    }
    
    func accessoryDisconnected(deviceID: Int) {
        
        referenceDict[deviceID]?.invalidate()
        // Remove the NI Session and Location values related to the device ID
        referenceDict.removeValue(forKey: deviceID)
        
        if selectedAccessory == deviceID {
            selectDevice(-1)
        }
        
        accessoryUpdate()
        
        // Update device list and take other actions depending on the amount of devices
        let deviceCount = qorvoDevices.count
        
        if deviceCount == 0 {
            selectDevice(-1)
        }
    }
    
    // MARK: - Accessory messages handling
    func setupAccessory(_ configData: Data, name: String, deviceID: Int) {
        infoLabelUpdate(with: "Received configuration data from '\(name)'. Running session.")
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
            configuration?.isCameraAssistanceEnabled = true
        }
        catch {
            // Stop and display the issue because the incoming data is invalid.
            // In your app, debug the accessory data to ensure an expected
            // format.
            infoLabelUpdate(with: "Failed to create NINearbyAccessoryConfiguration for '\(name)'. Error: \(error)")
            return
        }
        
        // Cache the token to correlate updates with this accessory.
        cacheToken(configuration!.accessoryDiscoveryToken, accessoryName: name)
        
        referenceDict[deviceID]?.run(configuration!)
        infoLabelUpdate(with: "Accessory Session configured.")
        
    }
    
    func handleAccessoryUwbDidStart(_ deviceID: Int) {
        
        // Update the device Status
        if let startedDevice = dataChannel.getDeviceFromUniqueID(deviceID) {
            startedDevice.blePeripheralStatus = statusRanging
        }
        
        for case let cell as DeviceTableViewCell in accessoriesTable.visibleCells {
            if cell.uniqueID == deviceID {
            }
        }
        
        // Enables Location assets when Qorvo device starts ranging
        // TODO: Check if this is still necessary
        enableLocation(true)
    }
    
    func handleAccessoryUwbDidStop(_ deviceID: Int) {
        infoLabelUpdate(with: "Accessory Session stopped.")
        
        // Disconnect from device
        disconnectFromAccessory(deviceID)
    }
    
    func clearLocationFields() {
        distanceLabel.text  = "-"
        azimuthLabel.text   = "-"
        elevationLabel.text = "-"
        
        azimuthLabel.textColor   = .black
        elevationLabel.textColor = .black
    }
    
    func enableLocation(_ enable: Bool) {
        infoLabel.isHidden =  enable
    }
    
    let motionManager = CMMotionManager()
    func startIMUUpdates() {
        let updateInterval = 1.0 / 60.0 // 60Hz
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval
        motionManager.magnetometerUpdateInterval = updateInterval

        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let accelerometerData = data else { return }
                self?.processAccelerometerData(accelerometerData)
            }
        }

        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: .main) { [weak self] (data, error) in
                guard let gyroData = data else { return }
                self?.processGyroData(gyroData)
            }
        }

        if motionManager.isMagnetometerAvailable {
            motionManager.startMagnetometerUpdates(to: .main) { [weak self] (data, error) in
                guard let magnetometerData = data else { return }
                self?.processMagnetometerData(magnetometerData)
            }
        }
    }

    func processAccelerometerData(_ accelerometerData: CMAccelerometerData) {
        let systemUptime = ProcessInfo.processInfo.systemUptime
        let ntpTimestamp = accelerometerData.timestamp
        let csvLine = "\(ntpTimestamp),\"acc\",\(accelerometerData.acceleration.x),\(accelerometerData.acceleration.y),\(accelerometerData.acceleration.z)\n"
        appendToCSVFile(csvLine)
    }

    func processGyroData(_ gyroData: CMGyroData) {
        let systemUptime = ProcessInfo.processInfo.systemUptime
        let ntpTimestamp = gyroData.timestamp
        let csvLine = "\(ntpTimestamp),\"gyro\",\(gyroData.rotationRate.x),\(gyroData.rotationRate.y),\(gyroData.rotationRate.z)\n"
        appendToCSVFile(csvLine)
    }

    func processMagnetometerData(_ magnetometerData: CMMagnetometerData) {
        let systemUptime = ProcessInfo.processInfo.systemUptime
        let ntpTimestamp = magnetometerData.timestamp
        let csvLine = "\(ntpTimestamp),\"mag\",\(magnetometerData.magneticField.x),\(magnetometerData.magneticField.y),\(magnetometerData.magneticField.z)\n"
        appendToCSVFile(csvLine)
    }

    func updateLocationFields(_ deviceID: Int) {
        if selectedAccessory == deviceID {
            guard let currentDevice = dataChannel.getDeviceFromUniqueID(deviceID) else { return }
            
            guard let distance = currentDevice.uwbLocation?.distance,
                  let direction = currentDevice.uwbLocation?.direction else { return }
            
            let azimuthValue = 90 * azimuth(direction)
            let elevationValue = 90 * elevation(direction)
            
            let systemUptime = ProcessInfo.processInfo.systemUptime
            let adjustedTimestamp = systemUptime
            
            let csvLine = "\(adjustedTimestamp),\"uwb\",\(distance),\(azimuthValue),\(elevationValue)\n"
            appendToCSVFile(csvLine)

            startIMUUpdates()
        }
    }
    
    func getUnixTime() -> TimeInterval {
        if unixTime == nil {
            Clock.sync { date, _ in
                if let ntpDate = date {
                    let localTime = Date().timeIntervalSince1970
                    let systemUptime = ProcessInfo.processInfo.systemUptime

                    self.localTimeOffset = ntpDate.timeIntervalSince1970 - localTime
                    self.systemUptimeOffset = ntpDate.timeIntervalSince1970 - systemUptime
                    print(ntpDate.timeIntervalSince1970)
                    print(systemUptime)

                    self.unixTime = ntpDate.timeIntervalSince1970
                } else {
                    self.unixTime = Date().timeIntervalSince1970
                    self.localTimeOffset = 0
                    self.systemUptimeOffset = 0
                    exit(0)
                }
            }
        } else {
            let systemUptime = ProcessInfo.processInfo.systemUptime
            unixTime = systemUptime + systemUptimeOffset
        }
        return unixTime ?? 0
    }

    func appendToCSVFile(_ data: String) {
        if let fileHandle = FileHandle(forWritingAtPath: csvFileURL!.path) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data.data(using: .utf8)!)
            fileHandle.closeFile()
        } else {
            print("Error: Can't open file to append")
        }
    }
    
    @IBAction func sendMailButtonTapped(_ sender: Any) {
        sendMail()
    }
    
    func sendMail() {
        guard MFMailComposeViewController.canSendMail() else {
            print("Mail services are not available")
            return
        }

        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self

        mailComposerVC.setToRecipients([""]) // Please input an e-mail address to which you send the data
        mailComposerVC.setSubject("CSV Data File")
        mailComposerVC.setMessageBody("Here is the CSV file.", isHTML: false)

        if let fileData = NSData(contentsOf: self.csvFileURL!) {
            mailComposerVC.addAttachmentData(fileData as Data, mimeType: "text/csv", fileName: "localization.csv")
        }

        self.present(mailComposerVC, animated: true, completion: nil)
    }
    @IBAction func Send(_ sender: UIButton) {
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - `NISessionDelegate`.
extension AccessoryDemoViewController: NISessionDelegate {

    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        guard object.discoveryToken == configuration?.accessoryDiscoveryToken else { return }
        
        // Prepare to send a message to the accessory.
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)
        
        let str = msg.map { String(format: "0x%02x, ", $0) }.joined()
        logger.info("Sending shareable configuration bytes: \(str)")
        
        // Send the message to the correspondent accessory.
        sendDataToAccessory(msg, deviceIDFromSession(session))
        infoLabelUpdate(with: "Sent shareable configuration data.")
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first else { return }
        guard let distance  = accessory.distance else { return }
        
        let deviceID = deviceIDFromSession(session)
        
        if let updatedDevice = dataChannel.getDeviceFromUniqueID(deviceID) {
            // set updated values
            updatedDevice.uwbLocation?.distance = distance
    
            if let direction = accessory.direction {
                updatedDevice.uwbLocation?.direction = direction
                updatedDevice.uwbLocation?.noUpdate  = false
            }
            else {
                updatedDevice.uwbLocation?.noUpdate  = true
            }
    
            updatedDevice.blePeripheralStatus = statusRanging
        }
        
        updateLocationFields(deviceID)
        
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        
        // Retry the session only if the peer timed out.
        guard reason == .timeout else { return }
        infoLabelUpdate(with: "Session timed out.")
        
        // The session runs with one accessory.
        guard let accessory = nearbyObjects.first else { return }
        
        // Clear the app's accessory state.
        accessoryMap.removeValue(forKey: accessory.discoveryToken)
        
        // Get the deviceID associated to the NISession
        let deviceID = deviceIDFromSession(session)
        
        // Consult helper function to decide whether or not to retry.
        if shouldRetry(deviceID) {
            sendDataToAccessory(Data([MessageId.stop.rawValue]), deviceID)
            sendDataToAccessory(Data([MessageId.initialize.rawValue]), deviceID)
        }
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        let deviceID = deviceIDFromSession(session)
        
        switch error {
        case NIError.invalidConfiguration:
            // Debug the accessory data to ensure an expected format.
            infoLabelUpdate(with: "The accessory configuration data is invalid. Please debug it and try again.")
        case NIError.userDidNotAllow:
            handleUserDidNotAllow()
        case NIError.invalidConfiguration:
            print("Check the ARConfiguration used to run the ARSession")
        default:
            print("invalidated: \(error)")
            handleSessionInvalidation(deviceID)
        }
    }
}

// MARK: - Helpers.
extension AccessoryDemoViewController {
    
    func infoLabelUpdate(with text: String) {
        infoLabel.text = text
        infoLabel.sizeToFit()
        
        logger.info("\(text)")
    }
    
    func connectToAccessory(_ deviceID: Int) {
         do {
             try dataChannel.connectPeripheral(deviceID)
         } catch {
             infoLabelUpdate(with: "Failed to connect to accessory: \(error)")
         }
    }
    
    func disconnectFromAccessory(_ deviceID: Int) {
         do {
             try dataChannel.disconnectPeripheral(deviceID)
         } catch {
             infoLabelUpdate(with: "Failed to disconnect from accessory: \(error)")
         }
     }
    
    func sendDataToAccessory(_ data: Data,_ deviceID: Int) {
         do {
             try dataChannel.sendData(data, deviceID)
         } catch {
             infoLabelUpdate(with: "Failed to send data to accessory: \(error)")
         }
     }
    
    func handleSessionInvalidation(_ deviceID: Int) {
        infoLabelUpdate(with: "Session invalidated. Restarting.")
        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.stop.rawValue]), deviceID)

        // Replace the invalidated session with a new one.
        referenceDict[deviceID] = NISession()
        referenceDict[deviceID]?.delegate = self

        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.initialize.rawValue]), deviceID)
    }
    
    func shouldRetry(_ deviceID: Int) -> Bool {
        // Need to use the dictionary here, to know which device failed and check its connection state
        let qorvoDevice = dataChannel.getDeviceFromUniqueID(deviceID)
        
        if qorvoDevice?.blePeripheralStatus != statusDiscovered {
            return true
        }
        
        return false
    }
    
    func deviceIDFromSession(_ session: NISession)-> Int {
        var deviceID = -1
        
        for (key, value) in referenceDict {
            if value == session {
                deviceID = key
            }
        }
        
        return deviceID
    }
    
    func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryMap[token] = accessoryName
    }
    
    func handleUserDidNotAllow() {
        // Beginning in iOS 15, persistent access state in Settings.
        infoLabelUpdate(with: "Nearby Interactions access required. You can change access for NIAccessory in Settings.")
        
        // Create an alert to request the user go to Settings.
        let accessAlert = UIAlertController(title: "Access Required",
                                            message: """
                                            NIAccessory requires access to Nearby Interactions for this sample app.
                                            Use this string to explain to users which functionality will be enabled if they change
                                            Nearby Interactions access in Settings.
                                            """,
                                            preferredStyle: .alert)
        accessAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        accessAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: {_ in
            // Navigate the user to the app's settings.
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }))

        // Preset the access alert.
        present(accessAlert, animated: true, completion: nil)
    }
}

// MARK: - Utils.
// Provides the azimuth from an argument 3D directional.
func azimuth(_ direction: simd_float3) -> Float {
    return asin(direction.x)
}

// Provides the elevation from the argument 3D directional.
func elevation(_ direction: simd_float3) -> Float {
    return atan2(direction.z, direction.y) + .pi / 2
}
