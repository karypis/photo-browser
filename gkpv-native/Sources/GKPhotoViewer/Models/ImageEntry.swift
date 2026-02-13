import AppKit

struct ImageEntry: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let fileSize: Int64
    let modificationDate: Date
    var pixelWidth: Int = 0
    var pixelHeight: Int = 0
    var aspectRatio: CGFloat = 1.0
    var thumbnailImage: NSImage?

    var hasDimensions: Bool { pixelWidth > 0 && pixelHeight > 0 }
}
