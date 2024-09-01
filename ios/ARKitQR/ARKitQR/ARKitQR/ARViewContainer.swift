import SwiftUI
import ARKit
import SceneKit
import Foundation
import Vision
import Kronos

struct ARKitARViewContainer: UIViewRepresentable {
    @Binding var distance: String
    @Binding var direction: String
    @Binding var anchorPoint: SCNVector3?
    @Binding var resetQRFlag: Bool
    @Binding var shouldResetCSV: Bool
    
    var arView = ARSCNView(frame: .zero)
    
    func makeUIView(context: Context) -> ARSCNView {
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        context.coordinator.resetCSVData()
        context.coordinator.initializeTimeSync()
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if shouldResetCSV {
            context.coordinator.resetCSVData()
            DispatchQueue.main.async {
                shouldResetCSV = false
            }
        }
        if anchorPoint == nil {
            context.coordinator.hasFoundQRCode = false
            uiView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if node.name == "anchorX" {
                    node.removeFromParentNode()
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        var parent: ARKitARViewContainer
        var hasFoundQRCode = false
        var timeOffset: Double = 0.0
        
        init(_ parent: ARKitARViewContainer) {
            self.parent = parent
            super.init()
        }
        
        func initializeTimeSync() {
            Clock.sync { [weak self] date, offset in
                guard let self = self else { return }
                let uptime = ProcessInfo.processInfo.systemUptime
                if let date = date {
                    let kronosTime = date.timeIntervalSince1970
                    self.timeOffset = kronosTime - uptime
                    print("Time source: Kronos")
                    print("Kronos UNIXTIME: \(kronosTime)")
                } else {
                    let fallbackTimestamp = Date().timeIntervalSince1970
                    self.timeOffset = fallbackTimestamp - uptime
                    print("Time source: Local (Please connect network if NTP sync is necessary)")
                    print("Local UNIXTIME: \(fallbackTimestamp)")
                }
                print("Device Uptime: \(uptime)")
                print("Calculated Offset: \(self.timeOffset)")
            }
        }
        
        func getCurrentTimestamp(from frame: ARFrame) -> Double {
            let frameTimestamp = frame.timestamp
            let unixTimestamp = frameTimestamp + timeOffset
            return unixTimestamp
        }

        func resetQRCodeFlag() {
            self.hasFoundQRCode = false
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            if hasFoundQRCode {
                return
            }
            
            let request = VNDetectBarcodesRequest { [weak self] (request, error) in
                if let results = request.results, let result = results.first as? VNBarcodeObservation, result.symbology == .QR {
                    if let qrData = result.payloadStringValue {
                        DispatchQueue.main.async {
                            self?.handleQRCode(data: qrData, frame: frame)
                            self?.hasFoundQRCode = true
                        }
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .right)
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform detection: \(error)")
            }
        }
        
        func handleQRCode(data: String, frame: ARFrame) {
            if let hitTestResult = frame.hitTest(CGPoint(x: 0.5, y: 0.5), types: .featurePoint).first {
                let transform = hitTestResult.worldTransform
                let qrPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                
                self.parent.anchorPoint = qrPosition
                self.parent.distance = "Set QR as origin"
                self.parent.direction = "Under tracking!!"
                
                let anchor = ARAnchor(transform: hitTestResult.worldTransform)
                parent.arView.session.add(anchor: anchor)
            }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let pointOfView = parent.arView.pointOfView else { return }
            let transform = pointOfView.transform
            let currentPosition = SCNVector3(transform.m41, transform.m42, transform.m43)
            
            if let anchor = self.parent.anchorPoint {
                let distance = sqrt(pow(currentPosition.x - anchor.x, 2) + pow(currentPosition.y - anchor.y, 2) + pow(currentPosition.z - anchor.z, 2))
                
                let directionVector = SCNVector3(currentPosition.x - anchor.x, currentPosition.y - anchor.y, currentPosition.z - anchor.z)

                let timestamp = getCurrentTimestamp(from: parent.arView.session.currentFrame!)
                let direction_x = currentPosition.x - anchor.x
                let direction_y = currentPosition.y - anchor.y
                let direction_z = currentPosition.z - anchor.z

                let distanceValue = Float(distance)
                saveToCSV(timestamp: timestamp, distance: distanceValue, direction: directionVector)
            }
        }
        
        func saveToCSV(timestamp: Double, distance: Float, direction: SCNVector3) {
            let fileName = "ARKitData.csv"
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)

            var csvText = ""

            if !FileManager.default.fileExists(atPath: path.path) {
                csvText = "Timestamp,Distance,DirectionX,DirectionY,DirectionZ\n"
            }

            let newLine = "\(timestamp),\(distance),\(direction.x),\(direction.y),\(direction.z)\n"
            csvText.append(newLine)

            do {
                if let fileHandle = FileHandle(forWritingAtPath: path.path) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(csvText.data(using: .utf8)!)
                    fileHandle.closeFile()
                } else {
                    try csvText.write(to: path, atomically: true, encoding: String.Encoding.utf8)
                }
            } catch {
                print("Failed to write to file")
                print("\(error)")
            }
        }
        
        func resetCSVData() {
            let fileName = "ARKitData.csv"
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
            let csvText = "Timestamp,Distance,DirectionX,DirectionY,DirectionZ\n"
            
            do {
                try csvText.write(to: path, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to reset CSV file")
                print("\(error)")
            }
        }
    }
}
