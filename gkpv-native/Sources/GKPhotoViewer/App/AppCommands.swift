import SwiftUI

struct AppCommands: Commands {
    let browser: BrowserViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open Folder...") {
                browser.openFolder()
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            // Recent Folders submenu
            let recents = RecentFoldersManager.shared.recentFolders
            Menu("Recent Folders") {
                if recents.isEmpty {
                    Text("No Recent Folders")
                } else {
                    ForEach(recents) { folder in
                        Button(folder.name) {
                            browser.openFolder(url: folder.url)
                        }
                    }
                    Divider()
                    Button("Clear Recents") {
                        RecentFoldersManager.shared.clearRecents()
                    }
                }
            }
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

        CommandGroup(after: .toolbar) {
            Button("Find...") {
                browser.requestSearchFocus()
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("Back") {
                browser.goBack()
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!browser.canGoBack)

            Button("Forward") {
                browser.goForward()
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(!browser.canGoForward)
        }
    }
}
