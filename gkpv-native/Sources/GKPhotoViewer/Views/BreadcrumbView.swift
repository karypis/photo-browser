import SwiftUI

struct BreadcrumbView: View {
    @Environment(BrowserViewModel.self) private var browser

    var body: some View {
        HStack(spacing: 4) {
            Button(browser.rootName) {
                browser.navigateTo(path: [])
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .font(.system(size: 13))

            ForEach(Array(browser.currentPath.enumerated()), id: \.offset) { index, segment in
                Text("/")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))

                Button(segment) {
                    browser.navigateTo(path: Array(browser.currentPath.prefix(index + 1)))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .font(.system(size: 13))
            }

            Spacer()
        }
        .frame(minWidth: 100)
    }
}
