import AppKit

struct FolderEntry: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    var previewImages: [NSImage] = []
}
