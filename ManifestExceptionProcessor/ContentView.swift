import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ManifestExceptionView()
                .tabItem {
                    Label("SwiftUI Demo", systemImage: "doc.text")
                }
            
            UIKitWrapperView()
                .tabItem {
                    Label("UIKit Demo", systemImage: "rectangle.stack")
                }
        }
    }
}

struct UIKitWrapperView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UINavigationController(rootViewController: ManifestExceptionViewController())
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    ContentView()
}