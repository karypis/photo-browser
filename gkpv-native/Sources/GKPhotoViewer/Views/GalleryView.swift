import SwiftUI

struct GalleryView: View {
    @Environment(BrowserViewModel.self) private var browser
    let lightbox: LightboxViewModel

    var body: some View {
        let displayImages = browser.filteredImages

        VStack(alignment: .leading, spacing: 24) {
            if browser.isLoading {
                ProgressView("Scanning directory...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Folders section
                if !browser.folders.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Folders (\(browser.folders.count))")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: browser.thumbnailSize.pointSize), spacing: 8)],
                            spacing: 8
                        ) {
                            ForEach(browser.folders) { folder in
                                FolderCardView(folder: folder)
                                    .onTapGesture {
                                        browser.navigateTo(path: browser.currentPath + [folder.name])
                                    }
                            }
                        }

                        Divider()
                    }
                }

                // Images section
                if !displayImages.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Images (\(displayImages.count))")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        if browser.layoutMode == .grid {
                            gridLayout(displayImages)
                        } else {
                            justifiedLayout(displayImages)
                        }
                    }
                }

                if browser.folders.isEmpty && displayImages.isEmpty {
                    emptyStateMessage
                }
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateMessage: some View {
        let isFiltering = !browser.searchText.isEmpty || browser.showFavoritesOnly
        if isFiltering {
            VStack(spacing: 8) {
                if browser.showFavoritesOnly && browser.searchText.isEmpty {
                    Text("No favorites in this directory.")
                } else if !browser.searchText.isEmpty {
                    Text("No images matching \"\(browser.searchText)\".")
                } else {
                    Text("No matching images found.")
                }
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 200)
            .multilineTextAlignment(.center)
        } else {
            Text("No images or subfolders found in this directory.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 200)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Grid

    private func gridLayout(_ displayImages: [ImageEntry]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: browser.thumbnailSize.pointSize), spacing: 8)],
            spacing: 8
        ) {
            ForEach(Array(displayImages.enumerated()), id: \.element.id) { index, image in
                ImageCardView(entry: image, mode: .grid, size: browser.thumbnailSize)
                    .onTapGesture {
                        lightbox.open(images: displayImages, at: index)
                    }
            }
        }
    }

    // MARK: - Justified

    private func justifiedLayout(_ displayImages: [ImageEntry]) -> some View {
        JustifiedLayout(
            targetRowHeight: browser.thumbnailSize.targetRowHeight,
            spacing: 8
        ) {
            ForEach(Array(displayImages.enumerated()), id: \.element.id) { index, image in
                ImageCardView(entry: image, mode: .justified, size: browser.thumbnailSize)
                    .justifiedAspectRatio(image.aspectRatio)
                    .onTapGesture {
                        lightbox.open(images: displayImages, at: index)
                    }
            }
        }
    }
}
