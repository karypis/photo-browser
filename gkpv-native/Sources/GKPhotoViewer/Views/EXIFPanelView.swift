import SwiftUI

struct EXIFPanelView: View {
    let lightbox: LightboxViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File section
            sectionHeader("FILE")

            if let entry = lightbox.currentEntry {
                infoRow("Name", entry.name)
                infoRow("Size", FormatHelpers.formatSize(entry.fileSize))
                infoRow("Type", entry.url.pathExtension.uppercased())
                if entry.hasDimensions {
                    infoRow("Dimensions", "\(entry.pixelWidth) \u{00D7} \(entry.pixelHeight)")
                }
                infoRow("Modified", entry.modificationDate.formatted(date: .abbreviated, time: .shortened))
            }

            // Camera section
            if let exif = lightbox.exifData {
                sectionHeader("CAMERA")

                if let camera = exif.cameraDescription {
                    infoRow("Camera", camera)
                }
                if let lens = exif.lensModel {
                    infoRow("Lens", lens)
                }
                if let settings = exif.settingsDescription {
                    infoRow("Settings", settings)
                }
                if let taken = exif.dateTimeOriginal {
                    infoRow("Taken", taken)
                }
                if let w = exif.pixelWidth, let h = exif.pixelHeight {
                    infoRow("EXIF Size", "\(w) \u{00D7} \(h)")
                }
            } else if lightbox.currentEntry != nil {
                Text("No EXIF data")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .padding(.top, 10)
            }
        }
        .padding(16)
        .frame(width: 280, alignment: .leading)
        .background(.black.opacity(0.85))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .tracking(0.5)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.2)
        }
    }
}
