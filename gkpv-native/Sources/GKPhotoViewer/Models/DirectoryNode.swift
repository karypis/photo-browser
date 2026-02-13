import Foundation

@Observable
final class DirectoryNode: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let depth: Int
    var children: [DirectoryNode]?  // nil = not yet scanned, [] = no subdirs
    var isExpanded = false
    var imageCount: Int = 0

    /// Path segments relative to the root
    let relativePath: [String]

    init(url: URL, name: String, depth: Int, relativePath: [String]) {
        self.url = url
        self.name = name
        self.depth = depth
        self.relativePath = relativePath
    }

    func scan() {
        guard children == nil else { return }
        let fm = FileManager.default
        var nodes: [DirectoryNode] = []
        var imgCount = 0

        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            children = []
            return
        }

        for itemURL in contents {
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                let childName = itemURL.lastPathComponent
                nodes.append(DirectoryNode(
                    url: itemURL,
                    name: childName,
                    depth: depth + 1,
                    relativePath: relativePath + [childName]
                ))
            } else {
                let ext = itemURL.pathExtension.lowercased()
                if Constants.imageExtensions.contains(ext) {
                    imgCount += 1
                }
            }
        }

        nodes.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        children = nodes
        imageCount = imgCount
    }

    func toggle() {
        if children == nil { scan() }
        isExpanded.toggle()
    }

    /// Expand all ancestors for a given path
    func expandTo(path: [String]) {
        guard !path.isEmpty else { return }
        if children == nil { scan() }
        isExpanded = true
        let next = path[0]
        if let child = children?.first(where: { $0.name == next }) {
            child.expandTo(path: Array(path.dropFirst()))
        }
    }
}
