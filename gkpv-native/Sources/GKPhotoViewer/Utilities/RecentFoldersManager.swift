import Foundation

struct RecentFolder: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let path: String
}

@Observable
final class RecentFoldersManager {
    static let shared = RecentFoldersManager()

    private(set) var recentFolders: [RecentFolder] = []
    private let maxRecents = 10
    private let defaultsKey = "recentFolderBookmarks"

    private init() {
        load()
    }

    func addRecent(url: URL) {
        // Remove existing entry for same path
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { resolveBookmark($0)?.path == url.path }

        // Create security-scoped bookmark
        guard let bookmark = try? url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        bookmarks.insert(bookmark, at: 0)
        if bookmarks.count > maxRecents {
            bookmarks = Array(bookmarks.prefix(maxRecents))
        }

        UserDefaults.standard.set(bookmarks, forKey: defaultsKey)
        load()
    }

    func clearRecents() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        recentFolders = []
    }

    func resolveURL(for folder: RecentFolder) -> URL? {
        let bookmarks = loadBookmarks()
        for bookmark in bookmarks {
            if let url = resolveBookmark(bookmark), url.path == folder.url.path {
                return url
            }
        }
        return folder.url
    }

    private func load() {
        let bookmarks = loadBookmarks()
        var folders: [RecentFolder] = []
        for bookmark in bookmarks {
            if let url = resolveBookmark(bookmark) {
                folders.append(RecentFolder(
                    url: url,
                    name: url.lastPathComponent,
                    path: url.path
                ))
            }
        }
        recentFolders = folders
    }

    private func loadBookmarks() -> [Data] {
        UserDefaults.standard.array(forKey: defaultsKey) as? [Data] ?? []
    }

    private func resolveBookmark(_ data: Data) -> URL? {
        var isStale = false
        return try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }
}
