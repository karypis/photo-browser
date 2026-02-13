import Foundation

enum FormatHelpers {
    static func formatSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1_048_576 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        if bytes < 1_073_741_824 { return String(format: "%.1f MB", Double(bytes) / 1_048_576) }
        return String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
    }

    static func formatShutter(_ value: Double?) -> String? {
        guard let v = value, v > 0 else { return nil }
        if v >= 1 { return "\(v)s" }
        return "1/\(Int(round(1.0 / v)))s"
    }

    static func formatAperture(_ value: Double?) -> String? {
        guard let v = value else { return nil }
        return String(format: "f/%.1f", v)
    }

    static func formatFocalLength(_ value: Double?) -> String? {
        guard let v = value else { return nil }
        return "\(Int(round(v)))mm"
    }
}

enum DropHelper {
    static func extractFolderURL(from providers: [NSItemProvider], completion: @escaping (URL?) -> Void) {
        guard let provider = providers.first else {
            completion(nil)
            return
        }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            var folderURL: URL?
            if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    folderURL = url
                }
            }
            DispatchQueue.main.async {
                completion(folderURL)
            }
        }
    }
}
