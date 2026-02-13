import AppKit
import ImageIO

final class ThumbnailManager: @unchecked Sendable {
    static let shared = ThumbnailManager()

    private let cacheDir: URL
    private let maxConcurrency = Constants.thumbConcurrency

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = caches.appendingPathComponent("GKPhotoViewer/thumbs", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Cache key

    private func cacheKey(for url: URL, modDate: Date, maxDim: Int) -> String {
        let raw = "\(url.path)_\(maxDim)_\(Int(modDate.timeIntervalSince1970))"
        let sanitized = raw.replacingOccurrences(of: "[^a-zA-Z0-9._-]", with: "_", options: .regularExpression)
        let prefix = String(sanitized.prefix(200))
        return prefix + ".jpg"
    }

    // MARK: - Generate thumbnail for a single image

    func generateThumbnail(for url: URL, modDate: Date, maxDim: Int = Constants.thumbMaxDimension, quality: CGFloat = Constants.thumbQuality) -> (image: NSImage, width: Int, height: Int)? {
        let key = cacheKey(for: url, modDate: modDate, maxDim: maxDim)
        let cachePath = cacheDir.appendingPathComponent(key)

        // Check disk cache
        if FileManager.default.fileExists(atPath: cachePath.path) {
            if let cached = NSImage(contentsOf: cachePath) {
                let dims = imageDimensions(url: url)
                return (cached, dims?.width ?? 0, dims?.height ?? 0)
            }
        }

        // Generate via CGImageSource
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDim,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        // Get original dimensions
        let dims = imageDimensions(url: url)

        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

        // Save to disk cache as JPEG
        if let tiff = nsImage.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) {
            try? jpegData.write(to: cachePath, options: .atomic)
        }

        return (nsImage, dims?.width ?? cgImage.width, dims?.height ?? cgImage.height)
    }

    // MARK: - Generate folder preview thumbnails

    func generateFolderPreviews(folderURL: URL, maxImages: Int = 4) -> [NSImage] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        var images: [NSImage] = []
        for fileURL in contents {
            if images.count >= maxImages { break }
            let ext = fileURL.pathExtension.lowercased()
            guard Constants.imageExtensions.contains(ext) else { continue }
            let modDate = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            if let result = generateThumbnail(for: fileURL, modDate: modDate, maxDim: Constants.folderThumbMax, quality: Constants.folderThumbQuality) {
                images.append(result.image)
            }
        }
        return images
    }

    // MARK: - Batch generate thumbnails

    func generateThumbnails(
        for entries: [(url: URL, modDate: Date, index: Int)],
        generation: Int,
        generationProvider: @escaping @Sendable () -> Int,
        onProgress: @escaping @Sendable (Int, NSImage, Int, Int) -> Void
    ) async {
        await withTaskGroup(of: Void.self) { group in
            var active = 0
            var iterator = entries.makeIterator()

            func addNext() -> Bool {
                guard let entry = iterator.next() else { return false }
                group.addTask {
                    guard generationProvider() == generation else { return }
                    if let result = self.generateThumbnail(for: entry.url, modDate: entry.modDate) {
                        onProgress(entry.index, result.image, result.width, result.height)
                    }
                }
                return true
            }

            // Seed initial workers
            for _ in 0..<maxConcurrency {
                guard addNext() else { break }
                active += 1
            }

            // Process results and feed more work
            for await _ in group {
                if generationProvider() != generation { break }
                active -= 1
                if addNext() { active += 1 }
            }
        }
    }

    // MARK: - Clear cache

    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Helpers

    private func imageDimensions(url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        // Check orientation — if rotated 90/270, swap dimensions
        if let orientation = props[kCGImagePropertyOrientation] as? Int,
           [5, 6, 7, 8].contains(orientation) {
            return (h, w)
        }
        return (w, h)
    }
}
