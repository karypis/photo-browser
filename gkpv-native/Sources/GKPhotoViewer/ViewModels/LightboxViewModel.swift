import AppKit
import SwiftUI

@Observable
final class LightboxViewModel {
    var isOpen = false
    var currentIndex = 0
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    var rotation: Int = 0  // 0, 90, 180, 270
    var showEXIF = false
    var exifData: EXIFData?
    var zoomPercent: Int = 100
    var showZoomIndicator = false

    private var preloadCache: [Int: NSImage] = [:]
    private var images: [ImageEntry] = []
    private var zoomHideTask: Task<Void, Never>?

    var currentImage: NSImage? {
        if let cached = preloadCache[currentIndex] { return cached }
        return nil
    }

    var currentEntry: ImageEntry? {
        guard currentIndex >= 0, currentIndex < images.count else { return nil }
        return images[currentIndex]
    }

    var positionText: String {
        guard !images.isEmpty else { return "" }
        let entry = images[currentIndex]
        return "\(entry.name)  (\(currentIndex + 1) / \(images.count))"
    }

    // MARK: - Open / Close

    func open(images: [ImageEntry], at index: Int) {
        self.images = images
        self.currentIndex = index
        self.isOpen = true
        resetZoom()
        loadCurrentImage()
        preloadAdjacent()
    }

    func close() {
        isOpen = false
        showEXIF = false
        exifData = nil
        preloadCache.removeAll()
    }

    // MARK: - Navigation

    func showPrevious() {
        guard !images.isEmpty else { return }
        currentIndex = (currentIndex - 1 + images.count) % images.count
        resetZoom()
        loadCurrentImage()
        preloadAdjacent()
        if showEXIF { loadEXIF() }
    }

    func showNext() {
        guard !images.isEmpty else { return }
        currentIndex = (currentIndex + 1) % images.count
        resetZoom()
        loadCurrentImage()
        preloadAdjacent()
        if showEXIF { loadEXIF() }
    }

    // MARK: - Zoom

    func resetZoom() {
        scale = 1.0
        offset = .zero
        rotation = 0
        zoomPercent = 100
    }

    // MARK: - Rotation

    func rotateCW() {
        rotation = (rotation + 90) % 360
    }

    func rotateCCW() {
        rotation = (rotation - 90 + 360) % 360
    }

    func flashZoomIndicator() {
        zoomPercent = Int(round(scale * 100))
        showZoomIndicator = true
        zoomHideTask?.cancel()
        zoomHideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            showZoomIndicator = false
        }
    }

    // MARK: - EXIF

    func toggleEXIF() {
        showEXIF.toggle()
        if showEXIF { loadEXIF() }
    }

    func loadEXIF() {
        guard let entry = currentEntry else { exifData = nil; return }
        exifData = EXIFParser.parse(url: entry.url)
    }

    // MARK: - Image Loading

    private func loadCurrentImage() {
        if preloadCache[currentIndex] == nil {
            if let entry = currentEntry {
                preloadCache[currentIndex] = NSImage(contentsOf: entry.url)
            }
        }
    }

    private func preloadAdjacent() {
        guard images.count > 1 else { return }
        let prev = (currentIndex - 1 + images.count) % images.count
        let next = (currentIndex + 1) % images.count
        let needed: Set<Int> = [currentIndex, prev, next]

        // Evict entries not needed
        for key in preloadCache.keys where !needed.contains(key) {
            preloadCache.removeValue(forKey: key)
        }

        // Preload
        for idx in [prev, next] where preloadCache[idx] == nil {
            if idx >= 0, idx < images.count {
                let url = images[idx].url
                let capturedIdx = idx
                Task.detached(priority: .utility) {
                    let image = NSImage(contentsOf: url)
                    await MainActor.run { [weak self] in
                        self?.preloadCache[capturedIdx] = image
                    }
                }
            }
        }
    }
}
