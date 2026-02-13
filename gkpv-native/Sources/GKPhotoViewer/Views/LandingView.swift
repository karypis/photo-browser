import SwiftUI

struct LandingView: View {
    @Environment(BrowserViewModel.self) private var browser

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
