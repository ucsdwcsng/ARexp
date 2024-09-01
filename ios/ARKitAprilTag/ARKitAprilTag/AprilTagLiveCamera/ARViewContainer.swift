import SwiftUI
import ARKit
import SceneKit
import Foundation
import Vision
import Kronos

struct MarkerResult {
    var image: UIImage
    var tagNums: Int
    var tagsData: [TagData]

    struct TagData {
        var id: Int
        var x: Double
        var y: Double
        var z: Double
    }
}

extension SCNMatrix4 {
    func toSimd() -> simd_float4x4 {
        return simd_float4x4(self)
    }
}

struct ARKitARViewContainerARAnchor: UIViewRepresentable {
    @Binding var distance: String
    @Binding var direction: String
    @Binding var anchorPoint: SCNVector3?
    @Binding var resetARFlag: Bool
    @Binding var shouldResetCSV: Bool
    
    var arView = ARSCNView(frame: .zero)
    
    func makeUIView(context: Context) -> ARSCNView {
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        context.coordinator.startARMarkerDetection()
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
            context.coordinator.hasFoundARMarker = false
            uiView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if node.name == "anchorX" {
                    node.removeFromParentNode()
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, arView: self.arView)
    }
        
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        var parent: ARKitARViewContainerARAnchor
        var arView: ARSCNView
        var hasFoundARMarker = false
        var vispDetector = VispDetector()
        var timeOffset: Double = 0.0
        
        init(_ parent: ARKitARViewContainerARAnchor, arView: ARSCNView) {
            self.parent = parent
            self.arView = arView
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
        
        func startARMarkerDetection() {
            self.hasFoundARMarker = false
        }

        func resetARMarkerFlag() {
            self.hasFoundARMarker = false
        }
        
        func getCurrentTimestamp() -> Double {
            return Date().timeIntervalSince1970
        }
        
        func convertToMarkerResult(from dictionary: [AnyHashable: Any]) -> MarkerResult? {
            guard let image = dictionary["image"] as? UIImage,
                  let tagNums = dictionary["tagNums"] as? Int,
                  let tagsDataArray = dictionary["tagsData"] as? [[String: Any]] else {
                return nil
            }

            let tagsData = tagsDataArray.compactMap { tagDict -> MarkerResult.TagData? in
                guard let id = tagDict["id"] as? Int,
                      let x = tagDict["x"] as? Double,
                      let y = tagDict["y"] as? Double,
                      let z = tagDict["z"] as? Double else {
                    return nil
                }
                return MarkerResult.TagData(id: id, x: x, y: y, z: z)
            }

            return MarkerResult(image: image, tagNums: tagNums, tagsData: tagsData)
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            if hasFoundARMarker {
                return
            }

            // Acquire image from AR frame
            let imageBuffer = frame.capturedImage
            // Convert the acquired image buffer to CIImage
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            // Create a context for generating CGImage from CIImage
            let context = CIContext(options: nil)
            // Create CGImage from CIImage
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            // Create UIImage from CGImage (scale 1.0, orientation up)
            let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)

            // Attempt marker detection on UIImage using vispDetector
            if let dictionary = vispDetector.detectAprilTag(uiImage, px: 1515.0, py: 1515.0) as? [AnyHashable: Any] {
                
                if let tagNums = dictionary["tagNums"] as? Int, tagNums > 0 {
                    if let markerResult = convertToMarkerResult(from: dictionary) {
                        DispatchQueue.main.async {
                            self.parent.distance = "Detected AprilTag"
                            self.parent.direction = "Direction is being calculated"
                            self.handleARMarker(markerResult: markerResult, frame: frame)
                            self.hasFoundARMarker = true
                        }
                    }
                }
            }
        }

        func handleARMarker(markerResult: MarkerResult, frame: ARFrame) {
            // Assumption: Use the first tag data from MarkerResult
            guard let firstTag = markerResult.tagsData.first else { return }

            // Generate transformation matrix based on position information from VispDetector
            let markerPosition = SCNVector3(firstTag.x, firstTag.y, -firstTag.z)
            let markerTransform = SCNMatrix4MakeTranslation(markerPosition.x, markerPosition.y, markerPosition.z)

            // Save the marker position
            DispatchQueue.main.async {
                self.parent.anchorPoint = markerPosition
            }

            // Configure ARKit world tracking
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            self.arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

            // Add anchor based on the marker position
            let anchor = ARAnchor(transform: matrix_identity_float4x4 * markerTransform.toSimd())
            self.arView.session.add(anchor: anchor)
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard self.hasFoundARMarker else { return }
            
            guard let pointOfView = parent.arView.pointOfView else { return }
            let transform = pointOfView.transform
            let currentPosition = SCNVector3(transform.m41, transform.m42, transform.m43)
            
            if let anchor = self.parent.anchorPoint {
                let directionVector = SCNVector3(currentPosition.x - anchor.x, currentPosition.y - anchor.y, currentPosition.z - anchor.z)
                
                let distance = sqrt(pow(directionVector.x, 2) + pow(directionVector.y, 2) + pow(directionVector.z, 2))
                let direction_x = directionVector.x
                let direction_y = directionVector.y
                let direction_z = directionVector.z

                let timestamp = getCurrentTimestamp()
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
                print("Failed to write to file: \(error.localizedDescription)")
            }
        }
        
        func resetCSVData() {
            let fileName = "ARKitData.csv"
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
            let csvText = "Timestamp,Distance,DirectionX,DirectionY,DirectionZ\n"
            
            do {
                try csvText.write(to: path, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to reset CSV file: \(error.localizedDescription)")
            }
        }
    }
}
