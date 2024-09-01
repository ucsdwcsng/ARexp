import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = context.coordinator

        mailController.setToRecipients([""]) // Please input an e-mail address to which you send the data.
        mailController.setSubject("ARKit Data")
        mailController.setMessageBody("Here is the ARKit data.", isHTML: false)

        let fileName = "ARKitData.csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
        if let csvData = try? Data(contentsOf: path) {
            mailController.addAttachmentData(csvData, mimeType: "text/csv", fileName: "ARKitData.csv")
        }

        return mailController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing, result: $result)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?
        
        init(isShowing: Binding<Bool>, result: Binding<Result<MFMailComposeResult, Error>?>) {
            _isShowing = isShowing
            _result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                isShowing = false
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }
}
