import SwiftUI

struct LightboxView: View {
    @Bindable var lightbox: LightboxViewModel
    @Environment(BrowserViewModel.self) private var browser
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.92)
                .ignoresSafeArea()
                .onTapGesture {
                    lightbox.close()
                }

            // Main image
            if let image = lightbox.currentImage {
                LightboxImageView(
                    image: image,
                    scale: $lightbox.scale,
                    offset: $lightbox.offset,
                    rotation: lightbox.rotation,
                    onZoomChanged: { lightbox.flashZoomIndicator() }
                )
            }

            // Navigation buttons
            HStack {
                Button(action: { lightbox.showPrevious() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)

                Spacer()

                Button(action: { lightbox.showNext() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24, weight: .medium))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }

            // Top-right controls
            HStack(spacing: 8) {
                Spacer()

                // Favorite button
                if let entry = lightbox.currentEntry {
                    Button(action: { browser.toggleFavorite(for: entry) }) {
                        Image(systemName: browser.isFavorite(entry) ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundStyle(browser.isFavorite(entry) ? .yellow : .white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Toggle favorite (F)")
                }

                // Info button
                Button(action: { lightbox.toggleEXIF() }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .frame(width: 40, height: 40)
                        .background(lightbox.showEXIF ? Color.blue : .white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Close button
                Button(action: { lightbox.close() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // EXIF panel
            if lightbox.showEXIF {
                EXIFPanelView(lightbox: lightbox)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 64)
                    .padding(.trailing, 16)
            }

            // Bottom bar: info + zoom slider
            VStack(spacing: 8) {
                Spacer()

                // Filename and position
                Text(lightbox.positionText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Zoom slider
                HStack(spacing: 10) {
                    Button(action: {
                        lightbox.scale = max(0.5, lightbox.scale / 1.15)
                        lightbox.flashZoomIndicator()
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)

                    Slider(
                        value: Binding(
                            get: { log2(lightbox.scale) },
                            set: { lightbox.scale = pow(2, $0); lightbox.flashZoomIndicator() }
                        ),
                        in: log2(0.5)...log2(20.0)
                    )
                    .frame(width: 200)
                    .controlSize(.small)

                    Button(action: {
                        lightbox.scale = min(20, lightbox.scale * 1.15)
                        lightbox.flashZoomIndicator()
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(round(lightbox.scale * 100)))%")
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .leading)

                    Divider()
                        .frame(height: 16)
                        .opacity(0.3)

                    Button(action: { lightbox.rotateCCW() }) {
                        Image(systemName: "rotate.left")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help("Rotate left (L)")

                    Button(action: { lightbox.rotateCW() }) {
                        Image(systemName: "rotate.right")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help("Rotate right (R)")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.7))
                .clipShape(Capsule())
            }
            .padding(.bottom, 16)
        }
        .foregroundStyle(.white)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear { isFocused = true }
        .onKeyPress(.escape) { lightbox.close(); return .handled }
        .onKeyPress(.leftArrow) { lightbox.showPrevious(); return .handled }
        .onKeyPress(.rightArrow) { lightbox.showNext(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "+=")) { _ in
            let step: CGFloat = 1.15
            lightbox.scale = min(20, lightbox.scale * step)
            lightbox.flashZoomIndicator()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "-")) { _ in
            let step: CGFloat = 1.15
            lightbox.scale = max(0.5, lightbox.scale / step)
            lightbox.flashZoomIndicator()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "0")) { _ in
            lightbox.resetZoom()
            lightbox.flashZoomIndicator()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "iI")) { _ in
            lightbox.toggleEXIF()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "rR")) { _ in
            lightbox.rotateCW()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "lL")) { _ in
            lightbox.rotateCCW()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "fF")) { _ in
            if let entry = lightbox.currentEntry {
                browser.toggleFavorite(for: entry)
            }
            return .handled
        }
    }
}
