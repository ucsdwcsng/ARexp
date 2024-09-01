import SwiftUI
import ARKit

struct ARViewContainer: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}

struct ContentView: View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

@main
struct ARKitDisplayFeature: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
