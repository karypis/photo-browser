import SwiftUI
import AppKit

struct BrowserView: View {
    @Environment(BrowserViewModel.self) private var browser
    @State private var lightbox = LightboxViewModel()
    @State private var rootNode: DirectoryNode?
    @State private var sidebarWidth: CGFloat = 220
    @State private var showSidebar = true

    var body: some View {
        HStack(spacing: 0) {
            if showSidebar {
                // Sidebar
                SidebarView(rootNode: $rootNode)
                    .frame(width: sidebarWidth)

                // Draggable divider with grip handle
                PanelDivider(position: $sidebarWidth, minPos: 140, maxPos: 400)
            }

            // Main content
            VStack(spacing: 0) {
                ToolbarView(showSidebar: $showSidebar)
                ScrollView {
                    GalleryView(lightbox: lightbox)
                        .padding(16)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .overlay {
            if lightbox.isOpen {
                LightboxView(lightbox: lightbox)
            }
        }
    }
}

// MARK: - Draggable panel divider with grip handle

struct PanelDivider: View {
    @Binding var position: CGFloat
    let minPos: CGFloat
    let maxPos: CGFloat
    @State private var isDragging = false
    @State private var isHovering = false

    var body: some View {
        ZStack {
            // Background line
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1)

            // Grip handle (3 vertical dots)
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color(nsColor: .tertiaryLabelColor))
                        .frame(width: 4, height: 4)
                }
            }
            .opacity(isDragging || isHovering ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            .animation(.easeInOut(duration: 0.15), value: isDragging)

            // Highlight on drag
            if isDragging {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 9)
            }
        }
        .frame(width: 9)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
            if hovering { NSCursor.resizeLeftRight.push() }
            else { NSCursor.pop() }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    isDragging = true
                    position = max(minPos, min(maxPos, value.location.x))
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}
