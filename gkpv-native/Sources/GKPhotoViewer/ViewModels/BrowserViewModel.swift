import AppKit
import SwiftUI

@Observable
final class BrowserViewModel {
    var rootURL: URL?
    var currentPath: [String] = []
    var folders: [FolderEntry] = []
    var images: [ImageEntry] = []
    var sortOrder: SortOrder = .nameAsc
    var thumbnailSize: ThumbnailSize = .medium
    var layoutMode: LayoutMode = .grid
    var isLoading = false
    var statusText = ""
    private(set) var generation = 0

    // MARK: - History

    private struct HistoryEntry {
        let rootURL: URL
        let path: [String]
    }

    private var history: [HistoryEntry] = []
    private var historyIndex = -1
    private var isHistoryNavigation = false

    var canGoBack: Bool { historyIndex > 0 }
    var canGoForward: Bool { historyIndex < history.count - 1 }

    // MARK: - Search

    var searchText: String = "" {
        didSet { updateStatusText() }
    }
    var focusSearchRequested = false

    func requestSearchFocus() {
        focusSearchRequested = true
    }

    func clearSearch() {
        searchText = ""
    }

    // MARK: - Favorites

    var showFavoritesOnly: Bool = false {
        didSet { updateStatusText() }
    }

    func toggleFavorite(for entry: ImageEntry) {
        FavoritesManager.shared.toggle(entry.url.path)
    }

    func isFavorite(_ entry: ImageEntry) -> Bool {
        FavoritesManager.shared.isFavorite(entry.url.path)
    }

    // MARK: - Filtered Images

    var filteredImages: [ImageEntry] {
        var result = images

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }

        if showFavoritesOnly {
            result = result.filter { FavoritesManager.shared.isFavorite($0.url.path) }
        }

        return result
    }

    // MARK: - Computed

    var isOpen: Bool { rootURL != nil }

    var rootName: String { rootURL?.lastPathComponent ?? "" }

    var currentDirectoryURL: URL? {
        guard let root = rootURL else { return nil }
        var url = root
        for segment in currentPath {
            url = url.appendingPathComponent(segment)
        }
        return url
    }

    // MARK: - Open Folder

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a photo folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openFolder(url: url)
    }

    func openFolder(url: URL) {
        rootURL = url
        currentPath = []
        searchText = ""
        showFavoritesOnly = false

        // Reset history for new root
        history = [HistoryEntry(rootURL: url, path: [])]
        historyIndex = 0

        RecentFoldersManager.shared.addRecent(url: url)
        scanDirectory()
    }

    // MARK: - History Navigation

    func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        let entry = history[historyIndex]
        isHistoryNavigation = true
        rootURL = entry.rootURL
        currentPath = entry.path
        searchText = ""
        scanDirectory()
        isHistoryNavigation = false
    }

    func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        let entry = history[historyIndex]
        isHistoryNavigation = true
        rootURL = entry.rootURL
        currentPath = entry.path
        searchText = ""
        scanDirectory()
        isHistoryNavigation = false
    }

    // MARK: - Navigation

    func navigateTo(path: [String]) {
        currentPath = path
        searchText = ""

        if !isHistoryNavigation, let root = rootURL {
            // Trim forward history
            if historyIndex < history.count - 1 {
                history = Array(history.prefix(historyIndex + 1))
            }
            history.append(HistoryEntry(rootURL: root, path: path))
            historyIndex = history.count - 1
        }

        scanDirectory()
    }

    // MARK: - Scanning

    func scanDirectory() {
        generation += 1
        let gen = generation
        guard let dirURL = currentDirectoryURL else { return }

        isLoading = true
        folders = []
        images = []
        statusText = "Scanning..."

        Task { @MainActor in
            let fm = FileManager.default
            var scannedFolders: [FolderEntry] = []
            var scannedImages: [ImageEntry] = []

            do {
                let contents = try fm.contentsOfDirectory(
                    at: dirURL,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                )

                for itemURL in contents {
                    let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    if values.isDirectory == true {
                        scannedFolders.append(FolderEntry(url: itemURL, name: itemURL.lastPathComponent))
                    } else {
                        let ext = itemURL.pathExtension.lowercased()
                        guard Constants.imageExtensions.contains(ext) else { continue }
                        let size = Int64(values.fileSize ?? 0)
                        let date = values.contentModificationDate ?? Date.distantPast
                        scannedImages.append(ImageEntry(
                            url: itemURL,
                            name: itemURL.lastPathComponent,
                            fileSize: size,
                            modificationDate: date
                        ))
                    }
                }
            } catch {
                statusText = "Error: \(error.localizedDescription)"
                isLoading = false
                return
            }

            guard gen == generation else { return }

            folders = sortFolders(scannedFolders)
            images = sortImages(scannedImages)
            isLoading = false
            updateStatusText()

            // Generate thumbnails
            loadThumbnails(gen: gen)

            // Generate folder previews
            loadFolderPreviews(gen: gen)
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnails(gen: Int) {
        let entries = images.enumerated().map { (index: $0.offset, url: $0.element.url, modDate: $0.element.modificationDate) }

        Task {
            await ThumbnailManager.shared.generateThumbnails(
                for: entries.map { (url: $0.url, modDate: $0.modDate, index: $0.index) },
                generation: gen,
                generationProvider: { [weak self] in self?.generation ?? -1 },
                onProgress: { [weak self] index, image, width, height in
                    Task { @MainActor in
                        guard let self, self.generation == gen, index < self.images.count else { return }
                        self.images[index].thumbnailImage = image
                        self.images[index].pixelWidth = width
                        self.images[index].pixelHeight = height
                        if width > 0 && height > 0 {
                            self.images[index].aspectRatio = CGFloat(width) / CGFloat(height)
                        }
                        self.updateStatusText()
                    }
                }
            )
        }
    }

    private func loadFolderPreviews(gen: Int) {
        let foldersCopy = folders
        Task {
            for (index, folder) in foldersCopy.enumerated() {
                guard generation == gen else { return }
                let previews = ThumbnailManager.shared.generateFolderPreviews(folderURL: folder.url)
                await MainActor.run {
                    guard generation == gen, index < folders.count else { return }
                    folders[index].previewImages = previews
                }
            }
        }
    }

    // MARK: - Sorting

    private func sortFolders(_ items: [FolderEntry]) -> [FolderEntry] {
        switch sortOrder {
        case .nameAsc: items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .nameDesc: items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        case .dateNew, .dateOld: items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    private func sortImages(_ items: [ImageEntry]) -> [ImageEntry] {
        switch sortOrder {
        case .nameAsc: items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .nameDesc: items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        case .dateNew: items.sorted { $0.modificationDate > $1.modificationDate }
        case .dateOld: items.sorted { $0.modificationDate < $1.modificationDate }
        }
    }

    func resort() {
        folders = sortFolders(folders)
        images = sortImages(images)
    }

    // MARK: - Status

    private func updateStatusText() {
        let thumbsDone = images.filter { $0.thumbnailImage != nil }.count
        let total = images.count
        let folderCount = folders.count

        if thumbsDone < total {
            statusText = "Generating thumbnails (\(thumbsDone)/\(total))..."
        } else {
            let filtered = filteredImages.count
            let isFiltering = !searchText.isEmpty || showFavoritesOnly
            if isFiltering {
                statusText = "\(filtered) of \(total) image\(total != 1 ? "s" : ""), \(folderCount) folder\(folderCount != 1 ? "s" : "")"
            } else {
                statusText = "\(total) image\(total != 1 ? "s" : ""), \(folderCount) folder\(folderCount != 1 ? "s" : "")"
            }
        }
    }

    // MARK: - Clear Cache

    func clearCache() {
        Task {
            ThumbnailManager.shared.clearCache()
            await MainActor.run {
                for i in images.indices {
                    images[i].thumbnailImage = nil
                }
                for i in folders.indices {
                    folders[i].previewImages = []
                }
                scanDirectory()
            }
        }
    }
}
