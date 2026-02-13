import SwiftUI

@main
struct GKPhotoViewerApp: App {
    @State private var browser = BrowserViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(browser)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            AppCommands(browser: browser)
        }
    }
}
