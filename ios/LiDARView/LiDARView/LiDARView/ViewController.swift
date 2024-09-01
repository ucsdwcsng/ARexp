import UIKit
import ARKit
import SceneKit

class PointCloudViewController: UIViewController, ARSessionDelegate {
    var session: ARSession!
    var sceneView: SCNView!
    var lastUpdateTime = Date()
    var pointNodesPool: [SCNNode] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = SCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
        
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black
        
        setupARSession()
    }

    func setupARSession() {
        session = ARSession()
        session.delegate = self

        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics.insert(.sceneDepth)
        session.run(configuration)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if Date().timeIntervalSince(lastUpdateTime) >= 1 {
            guard let sceneDepth = frame.sceneDepth else { return }
            let depthPoints = sceneDepth.depthMap
            DispatchQueue.main.async {
                self.processDepthPoints(depthPoints, frame: frame)
            }
            lastUpdateTime = Date()
        }
    }

    func processDepthPoints(_ depthPoints: CVPixelBuffer, frame: ARFrame) {
        let width = CVPixelBufferGetWidth(depthPoints)
        let height = CVPixelBufferGetHeight(depthPoints)
        
        CVPixelBufferLockBaseAddress(depthPoints, .readOnly)
        let depthDataPointer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthPoints), to: UnsafeMutablePointer<Float32>.self)

        let samplingInterval = 3
        var pointsNeeded = 0
        
        for y in stride(from: 0, to: height, by: samplingInterval) {
            for x in stride(from: 0, to: width, by: samplingInterval) {
                pointsNeeded += 1
            }
        }

        while pointNodesPool.count < pointsNeeded {
            let pointNode = SCNNode(geometry: SCNSphere(radius: 0.001))
            pointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            pointNodesPool.append(pointNode)
        }
        
        var pointIndex = 0
        for y in stride(from: 0, to: height, by: samplingInterval) {
            for x in stride(from: 0, to: width, by: samplingInterval) {
                let depthAtPixel = depthDataPointer[y * width + x]
                if depthAtPixel > 0, pointIndex < pointsNeeded {
                    let pointNode = pointNodesPool[pointIndex]
                    let adjustedX = -Float(x - width / 2) * 0.001
                    let adjustedY = -Float(y - height / 2) * 0.001
                    pointNode.position = SCNVector3(x: adjustedY, y: adjustedX, z: -depthAtPixel)
                    if pointNode.parent == nil {
                        self.sceneView.scene?.rootNode.addChildNode(pointNode)
                    }
                    pointIndex += 1
                }
            }
        }

        for index in pointIndex..<pointNodesPool.count {
            pointNodesPool[index].removeFromParentNode()
        }

        CVPixelBufferUnlockBaseAddress(depthPoints, .readOnly)
    }
}

