import SwiftUI
import UniformTypeIdentifiers

struct LandingView: View {
    @Environment(BrowserViewModel.self) private var browser
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            Text("gk Photo Viewer")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.blue)

            Text("Browse your local photo library in a native macOS app.")
                .foregroundStyle(.secondary)
                .font(.system(size: 15))
                .frame(maxWidth: 420)
                .multilineTextAlignment(.center)

            Button("Open Folder") {
                browser.openFolder()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            // Recent folders
            let recents = RecentFoldersManager.shared.recentFolders
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Folders")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") {
                            RecentFoldersManager.shared.clearRecents()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    }

                    ForEach(recents) { folder in
                        Button(action: { browser.openFolder(url: folder.url) }) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.blue)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(folder.name)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(folder.path)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 400)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .foregroundStyle(.blue)
                    .padding(8)
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            DropHelper.extractFolderURL(from: providers) { url in
                if let url { browser.openFolder(url: url) }
            }
            return true
        }
    }
}
