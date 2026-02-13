import SwiftUI

struct ToolbarView: View {
    @Environment(BrowserViewModel.self) private var browser
    @Binding var showSidebar: Bool

    var body: some View {
        @Bindable var b = browser

        HStack(spacing: 10) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showSidebar.toggle() } }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundStyle(showSidebar ? .blue : .secondary)
            .help("Toggle sidebar")

            Text("gkpv")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.blue)

            Button("Open") {
                browser.openFolder()
            }
            .controlSize(.small)

            BreadcrumbView()

            Picker("", selection: $b.layoutMode) {
                ForEach(LayoutMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)

            Picker("", selection: $b.thumbnailSize) {
                ForEach(ThumbnailSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)

            Picker("", selection: $b.sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .frame(width: 110)
            .onChange(of: browser.sortOrder) {
                browser.resort()
            }

            Button("Clear Cache") {
                browser.clearCache()
            }
            .controlSize(.small)

            Spacer()

            Text(browser.statusText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
