import SwiftUI

struct GalleryView: View {
    @Environment(BrowserViewModel.self) private var browser
    let lightbox: LightboxViewModel

    var body: some View {
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
                if !browser.images.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Images (\(browser.images.count))")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        if browser.layoutMode == .grid {
                            gridLayout
                        } else {
                            justifiedLayout
                        }
                    }
                }

                if browser.folders.isEmpty && browser.images.isEmpty {
                    Text("No images or subfolders found in this directory.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Grid

    private var gridLayout: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: browser.thumbnailSize.pointSize), spacing: 8)],
            spacing: 8
        ) {
            ForEach(Array(browser.images.enumerated()), id: \.element.id) { index, image in
                ImageCardView(entry: image, mode: .grid, size: browser.thumbnailSize)
                    .onTapGesture {
                        lightbox.open(images: browser.images, at: index)
                    }
            }
        }
    }

    // MARK: - Justified

    private var justifiedLayout: some View {
        JustifiedLayout(
            targetRowHeight: browser.thumbnailSize.targetRowHeight,
            spacing: 8
        ) {
            ForEach(Array(browser.images.enumerated()), id: \.element.id) { index, image in
                ImageCardView(entry: image, mode: .justified, size: browser.thumbnailSize)
                    .justifiedAspectRatio(image.aspectRatio)
                    .onTapGesture {
                        lightbox.open(images: browser.images, at: index)
                    }
            }
        }
    }
}
