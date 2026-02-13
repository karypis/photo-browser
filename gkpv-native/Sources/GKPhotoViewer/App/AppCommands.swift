import SwiftUI

struct AppCommands: Commands {
    let browser: BrowserViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open Folder...") {
                browser.openFolder()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandMenu("View") {
            Button("Grid Layout") {
                browser.layoutMode = .grid
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Justified Layout") {
                browser.layoutMode = .justified
            }
            .keyboardShortcut("2", modifiers: .command)

            Divider()

            Button("Small Thumbnails") {
                browser.thumbnailSize = .small
            }

            Button("Medium Thumbnails") {
                browser.thumbnailSize = .medium
            }

            Button("Large Thumbnails") {
                browser.thumbnailSize = .large
            }
        }
    }
}
