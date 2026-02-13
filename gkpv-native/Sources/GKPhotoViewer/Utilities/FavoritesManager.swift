import Foundation

@Observable
final class FavoritesManager {
    static let shared = FavoritesManager()

    private(set) var favorites: Set<String> = []
    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("GKPhotoViewer")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        fileURL = appDir.appendingPathComponent("favorites.json")
        load()
    }

    func isFavorite(_ path: String) -> Bool {
        favorites.contains(path)
    }

    func toggle(_ path: String) {
        if favorites.contains(path) {
            favorites.remove(path)
        } else {
            favorites.insert(path)
        }
        save()
    }

    func add(_ path: String) {
        favorites.insert(path)
        save()
    }

    func remove(_ path: String) {
        favorites.remove(path)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let paths = try? JSONDecoder().decode(Set<String>.self, from: data) else { return }
        favorites = paths
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
