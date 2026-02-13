import Foundation

enum Constants {
    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "bmp", "webp", "avif",
        "svg", "ico", "tiff", "tif", "heic", "heif",
    ]

    static let thumbMaxDimension: Int = 640
    static let thumbQuality: CGFloat = 0.8
    static let thumbConcurrency: Int = 4
    static let folderThumbMax: Int = 160
    static let folderThumbQuality: CGFloat = 0.6
}
