# gk Photo Viewer — Native macOS App

A native macOS photo browser built with SwiftUI. Zero dependencies, no Xcode project — just `swift build`.

## Features

- **Local folder browsing** — open any directory via NSOpenPanel, navigate subdirectories with breadcrumbs or the sidebar tree
- **Directory sidebar** — collapsible folder tree with image count badges, resizable via drag handle
- **Thumbnail grid** — responsive grid with three size options (S / M / L) and auto-fill columns
- **Justified layout** — magazine-style rows that fill to a target height using natural aspect ratios
- **Hardware-accelerated thumbnails** — generated via CGImageSource with EXIF orientation support, cached to `~/Library/Caches/GKPhotoViewer/thumbs/`
- **Folder preview mosaics** — folder cards show a 2x2 grid of the first four images
- **Lightbox viewer** — click any thumbnail to view full-size with left/right arrow key navigation
- **Zoom & pan** — scroll wheel zoom toward cursor, click to toggle fit/100%, drag to pan when zoomed; trackpad pinch zoom supported
- **Magnification slider** — bottom bar with logarithmic zoom slider, +/- buttons, and percentage readout
- **Image rotation** — rotate 90 degrees clockwise (R) or counterclockwise (L) in the lightbox
- **EXIF info panel** — press I to see file details and camera metadata (works for JPEG, HEIC, and all ImageIO-supported formats)
- **Image info tooltips** — hover thumbnails to see filename, dimensions, file size, and date
- **Image preloading** — previous and next images are preloaded in the background for instant navigation
- **Sorting** — sort by name or date (ascending/descending)
- **Cache management** — Clear Cache button to force thumbnail regeneration
- **Keyboard shortcuts** — arrow keys, Esc, +/-/0, I (EXIF), R/L (rotate), Cmd+O (open), Cmd+1/2 (layout)

## Requirements

- macOS 14 (Sonoma) or later
- Swift 5.10+

## Build & Run

```bash
swift build              # debug build
swift build -c release   # optimized build
swift run                # build and launch
```

## Install

Build a `.dmg` installer with the included script:

```bash
./build-dmg.sh
```

This creates `GKPhotoViewer.dmg` — open it and drag **GK Photo Viewer** to **Applications**.

> **Note:** The app is unsigned. On first launch, right-click the app and select **Open** to bypass Gatekeeper.

## Tech Stack

- **SwiftUI** with `@Observable` macro
- **Swift Package Manager** — no Xcode project needed
- **ImageIO** for thumbnail generation and EXIF parsing
- **CGImageSource** for hardware-accelerated image decoding
- **NSViewRepresentable** for lightbox zoom/pan (scroll wheel + drag)
- Zero external dependencies

## Project Structure

```
Package.swift
Sources/GKPhotoViewer/
  App/           — @main app, menu commands
  Models/        — ImageEntry, FolderEntry, DirectoryNode, enums
  ViewModels/    — BrowserViewModel, LightboxViewModel, ThumbnailManager, EXIFParser
  Views/         — all SwiftUI views (landing, browser, gallery, lightbox, sidebar, etc.)
  Layout/        — JustifiedLayout (custom SwiftUI Layout protocol)
  Utilities/     — FormatHelpers, Constants
```

## License

MIT
