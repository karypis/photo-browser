import SwiftUI

struct ImageCardView: View {
    let entry: ImageEntry
    let mode: LayoutMode
    let size: ThumbnailSize
    @Environment(BrowserViewModel.self) private var browser

    var body: some View {
        ZStack(alignment: .bottom) {
            // Image layer: Color.clear accepts the proposed size exactly,
            // then the image fills it and clips — prevents overflow
            if let thumb = entry.thumbnailImage {
                Color.clear
                    .overlay {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .clipped()
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            } else {
                shimmerPlaceholder
            }

            // Favorite star overlay (top-right)
            if browser.isFavorite(entry) {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                            .padding(6)
                    }
                    Spacer()
                }
            }

            // Filename label
            Text(entry.name)
                .font(.system(size: 11))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .if(mode == .grid) { view in
            view.aspectRatio(1, contentMode: .fit)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .help(tooltipText)
        .contextMenu {
            if browser.isFavorite(entry) {
                Button("Remove from Favorites") {
                    browser.toggleFavorite(for: entry)
                }
            } else {
                Button("Add to Favorites") {
                    browser.toggleFavorite(for: entry)
                }
            }
        }
    }

    private var tooltipText: String {
        let dims = entry.hasDimensions ? "\(entry.pixelWidth) x \(entry.pixelHeight)" : "-"
        let size = FormatHelpers.formatSize(entry.fileSize)
        let date = entry.modificationDate.formatted(date: .abbreviated, time: .omitted)
        return "\(entry.name)\n\(dims) \u{00B7} \(size) \u{00B7} \(date)"
    }

    @ViewBuilder
    private var shimmerPlaceholder: some View {
        Rectangle()
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay {
                ProgressView()
                    .controlSize(.small)
            }
    }
}

// MARK: - Conditional modifier

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
