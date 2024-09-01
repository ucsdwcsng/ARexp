import UIKit
import ARKit
import MessageUI

var num = 0

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, MFMailComposeViewControllerDelegate {
    var sceneView: ARSCNView!
    private var featurePoints: [SCNNode] = []
    private var lastFeaturePointCount: Int = 0
    
    private lazy var sphereNode: SCNNode = {
        let node = SCNNode()
        let geometry = SCNSphere(radius: 0.005)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        node.geometry = geometry
        return node
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        let buttonSize: CGFloat = 70
        let buttonX = (self.view.frame.width - buttonSize) / 2
        let buttonY = self.view.frame.height - buttonSize - 30
        let shutterButton = UIButton(frame: CGRect(x: buttonX, y: buttonY, width: buttonSize, height: buttonSize))
        
        shutterButton.backgroundColor = .blue
        shutterButton.layer.cornerRadius = buttonSize / 2
        shutterButton.layer.masksToBounds = true
        shutterButton.addTarget(self, action: #selector(takeScreenshotAndEmail), for: .touchUpInside)
        
        self.view.addSubview(shutterButton)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func convertToUIImage(from pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation = .right) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }

    func drawFeaturePointsOnImage(from frame: ARFrame) -> UIImage? {
        guard let featurePoints = frame.rawFeaturePoints else { return nil }
        guard let currentFrameImage = convertToUIImage(from: frame.capturedImage) else { return nil }

        let imageSize = currentFrameImage.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, currentFrameImage.scale)
        currentFrameImage.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setStrokeColor(UIColor.yellow.cgColor)
        
        let fixedSize: CGFloat = 10.0
        
        for point in featurePoints.points {
            let screenPoint = frame.camera.projectPoint(point, orientation: .portrait, viewportSize: imageSize)
            let rect = CGRect(x: CGFloat(screenPoint.x) - fixedSize / 2, y: CGFloat(screenPoint.y) - fixedSize / 2, width: fixedSize, height: fixedSize)
            context.addEllipse(in: rect)
        }
        
        context.strokePath()
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage
    }

    func drawFeaturePoints(on image: UIImage?, from frame: ARFrame) -> UIImage? {
        guard let image = image else { return nil }
        let imageSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
        image.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.red.cgColor)

        let fixedSize: CGFloat = 30.0
        
        frame.rawFeaturePoints?.points.forEach { point in
            let screenPoint = frame.camera.projectPoint(point, orientation: .portrait, viewportSize: imageSize)
            let rect = CGRect(x: CGFloat(screenPoint.x) - fixedSize / 2, y: CGFloat(screenPoint.y) - fixedSize / 2, width: fixedSize, height: fixedSize)
            context.fillEllipse(in: rect)
        }

        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resultImage
    }

    @objc func takeScreenshotAndEmail() {
        guard let frame = sceneView.session.currentFrame else {
            print("Failed to get AR frame image.")
            return
        }

        guard let rawCameraImage = convertToUIImage(from: frame.capturedImage) else {
            print("Failed to convert image.")
            return
        }

        guard let imageWithFeaturePoints = drawFeaturePoints(on: rawCameraImage, from: frame) else {
            print("Failed to draw feature points.")
            return
        }

        sendEmail(screenshotWithFeaturePoints: imageWithFeaturePoints, rawCameraImage: rawCameraImage)
    }

    func sendEmail(screenshotWithFeaturePoints: UIImage, rawCameraImage: UIImage) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setSubject("Screenshot of AR Scene")
            
            mailComposer.setToRecipients([""]) // Please input an e-mail address to which you send the data.
            
            let emailBody = "Number of feature points at the time of capture: \(self.lastFeaturePointCount)"
            mailComposer.setMessageBody(emailBody, isHTML: false)

            if let imageDataWithFeaturePoints = screenshotWithFeaturePoints.jpegData(compressionQuality: 1.0) {
                mailComposer.addAttachmentData(imageDataWithFeaturePoints, mimeType: "image/jpeg", fileName: "screenshotWithFeaturePoints.jpg")
            }

            if let imageDataRawCamera = rawCameraImage.jpegData(compressionQuality: 1.0) {
                mailComposer.addAttachmentData(imageDataRawCamera, mimeType: "image/jpeg", fileName: "rawCameraImage.jpg")
            }

            self.present(mailComposer, animated: true, completion: nil)
        } else {
            print("Cannot send email")
        }
    }

    func takeScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(sceneView.bounds.size, false, 0.0)
        sceneView.drawHierarchy(in: sceneView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let pointPositions = frame.rawFeaturePoints?.points else {
            return
        }

        let numberOfFeaturePoints = pointPositions.count
        print("Number of Feature Points: \(numberOfFeaturePoints)")
        
        self.featurePoints.forEach { $0.removeFromParentNode() }
        
        let featurePointNodes: [SCNNode] = pointPositions.map { position in
            let node = sphereNode.clone()
            node.position = SCNVector3(position.x, position.y, position.z)
            return node
        }
        
        featurePointNodes.forEach { sceneView.scene.rootNode.addChildNode($0) }
        
        self.featurePoints = featurePointNodes
        
        lastFeaturePointCount = pointPositions.count
    }

}
