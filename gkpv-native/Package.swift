// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "GKPhotoViewer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "GKPhotoViewer",
            path: "Sources/GKPhotoViewer",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ImageIO"),
                .linkedFramework("UniformTypeIdentifiers"),
            ]
        )
    ]
)
