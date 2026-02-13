import SwiftUI

struct FolderCardView: View {
    let folder: FolderEntry

    var body: some View {
        VStack(spacing: 0) {
            if folder.previewImages.isEmpty {
                // Folder icon
                Text("\u{1F4C1}")
                    .font(.system(size: 48))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if folder.previewImages.count == 1 {
                // Single image fills the card
                Image(nsImage: folder.previewImages[0])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                // 2x2 mosaic
                Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                    GridRow {
                        mosaicCell(0)
                        mosaicCell(1)
                    }
                    GridRow {
                        mosaicCell(2)
                        mosaicCell(3)
                    }
                }
            }

            // Folder name
            Text(folder.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func mosaicCell(_ index: Int) -> some View {
        if index < folder.previewImages.count {
            Image(nsImage: folder.previewImages[index])
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            Color(nsColor: .controlBackgroundColor)
        }
    }
}
