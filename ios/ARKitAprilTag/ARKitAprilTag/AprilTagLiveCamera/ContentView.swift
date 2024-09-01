import SwiftUI
import MessageUI
import SceneKit

struct ContentView: View {
    @State private var isShowingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var distance: String = "Searching AprilTag"
    @State private var direction: String = "Direction not set"
    @State private var anchorPoint: SCNVector3?
    @State private var resetARFlag = false
    @State private var shouldResetCSV = false
    
    var body: some View {
        VStack {
            ARKitARViewContainerARAnchor(distance: $distance, direction: $direction, anchorPoint: $anchorPoint, resetARFlag: $resetARFlag, shouldResetCSV: $shouldResetCSV)
            Text(distance)
            Text(direction)
            Button("Reset Anchor Point") {
                anchorPoint = nil
                shouldResetCSV = true
            }
            Button("Send Email") {
                self.isShowingMailView.toggle()
            }
            .disabled(!MFMailComposeViewController.canSendMail())
            .sheet(isPresented: $isShowingMailView) {
                MailView(isShowing: self.$isShowingMailView, result: self.$mailResult)
            }
        }
    }
}
