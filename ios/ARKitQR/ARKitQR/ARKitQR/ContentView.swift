import SwiftUI
import MessageUI
import SceneKit

struct ContentView: View {
    @State private var isShowingMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var distance: String = "Searching QR"
    @State private var direction: String = "---"
    @State private var anchorPoint: SCNVector3?
    @State private var resetQRFlag = false
    @State private var shouldResetCSV = false
    
    var body: some View {
        VStack {
            ARKitARViewContainer(distance: $distance, direction: $direction, anchorPoint: $anchorPoint, resetQRFlag: $resetQRFlag, shouldResetCSV: $shouldResetCSV)
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
