import SwiftUI

@main
struct GKPhotoViewerApp: App {
    @State private var browser = BrowserViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(browser)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        browser.openFolder(url: url)
                    }
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            AppCommands(browser: browser)
        }
    }
}
