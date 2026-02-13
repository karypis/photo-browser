import SwiftUI

struct ToolbarView: View {
    @Environment(BrowserViewModel.self) private var browser
    @Binding var showSidebar: Bool
    @FocusState private var isSearchFocused: Bool

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

            // Back/Forward
            Button(action: { browser.goBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(browser.canGoBack ? .primary : .quaternary)
            .disabled(!browser.canGoBack)
            .help("Back (⌘[)")

            Button(action: { browser.goForward() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(browser.canGoForward ? .primary : .quaternary)
            .disabled(!browser.canGoForward)
            .help("Forward (⌘])")

            Text("gkpv")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.blue)

            Button("Open") {
                browser.openFolder()
            }
            .controlSize(.small)

            BreadcrumbView()

            // Search field
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                TextField("Search", text: $b.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(width: 100)
                    .focused($isSearchFocused)

                if !browser.searchText.isEmpty {
                    Button(action: { browser.clearSearch() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSearchFocused ? Color.blue.opacity(0.5) : Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .onChange(of: browser.focusSearchRequested) {
                if browser.focusSearchRequested {
                    isSearchFocused = true
                    browser.focusSearchRequested = false
                }
            }

            // Favorites toggle
            Button(action: { browser.showFavoritesOnly.toggle() }) {
                Image(systemName: browser.showFavoritesOnly ? "star.fill" : "star")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundStyle(browser.showFavoritesOnly ? .yellow : .secondary)
            .help(browser.showFavoritesOnly ? "Show all images" : "Show favorites only")

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
