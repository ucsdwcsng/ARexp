import SwiftUI
import ARKit

struct ContentView: View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    typealias UIViewControllerType = PointCloudViewController

    func makeUIViewController(context: Context) -> PointCloudViewController {
        return PointCloudViewController()
    }
    
    func updateUIViewController(_ uiViewController: PointCloudViewController, context: Context) {
    }
}
