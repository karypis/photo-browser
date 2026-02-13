import SwiftUI

struct ContentView: View {
    @Environment(BrowserViewModel.self) private var browser

    var body: some View {
        Group {
            if browser.isOpen {
                BrowserView()
            } else {
                LandingView()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
