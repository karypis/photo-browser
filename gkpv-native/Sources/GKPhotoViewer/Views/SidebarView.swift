import SwiftUI

struct SidebarView: View {
    @Environment(BrowserViewModel.self) private var browser
    @Binding var rootNode: DirectoryNode?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                Text("Folders")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Tree — flattened into a list for rendering
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let root = rootNode {
                        ForEach(flattenTree(root)) { node in
                            SidebarRowView(
                                node: node,
                                selectedPath: browser.currentPath,
                                onNavigate: { path in
                                    browser.navigateTo(path: path)
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .onChange(of: browser.rootURL) {
            rebuildRoot()
        }
        .onChange(of: browser.currentPath) {
            rootNode?.expandTo(path: browser.currentPath)
        }
        .onAppear {
            if rootNode == nil { rebuildRoot() }
        }
    }

    /// Walk the tree and collect all visible nodes in order
    private func flattenTree(_ node: DirectoryNode) -> [DirectoryNode] {
        var result = [node]
        if node.isExpanded, let children = node.children {
            for child in children {
                result.append(contentsOf: flattenTree(child))
            }
        }
        return result
    }

    private func rebuildRoot() {
        guard let url = browser.rootURL else { rootNode = nil; return }
        let node = DirectoryNode(url: url, name: url.lastPathComponent, depth: 0, relativePath: [])
        node.scan()
        node.isExpanded = true
        rootNode = node
    }
}

// MARK: - Single row

private struct SidebarRowView: View {
    @Bindable var node: DirectoryNode
    let selectedPath: [String]
    let onNavigate: ([String]) -> Void

    private var isSelected: Bool {
        node.relativePath == selectedPath
    }

    private var hasChildren: Bool {
        if let children = node.children { return !children.isEmpty }
        return true  // not scanned yet, assume it might have children
    }

    var body: some View {
        HStack(spacing: 4) {
            // Disclosure triangle
            Button(action: { node.toggle() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(node.isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.15), value: node.isExpanded)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .opacity(hasChildren ? 1 : 0)

            // Folder icon + name
            Image(systemName: node.isExpanded ? "folder.fill" : "folder")
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? .white : .blue)

            Text(node.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(isSelected ? .white : .primary)

            Spacer()

            // Image count badge
            if node.imageCount > 0 {
                Text("\(node.imageCount)")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.leading, CGFloat(node.depth) * 16 + 8)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected ? Color.accentColor : Color.clear)
                .padding(.horizontal, 4)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if node.children == nil { node.scan() }
            if !node.isExpanded { node.isExpanded = true }
            onNavigate(node.relativePath)
        }
    }
}
