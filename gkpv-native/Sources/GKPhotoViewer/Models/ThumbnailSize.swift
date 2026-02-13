import Foundation

enum ThumbnailSize: String, CaseIterable {
    case small = "S"
    case medium = "M"
    case large = "L"

    var pointSize: CGFloat {
        switch self {
        case .small: 120
        case .medium: 200
        case .large: 320
        }
    }

    var targetRowHeight: CGFloat {
        switch self {
        case .small: 150
        case .medium: 220
        case .large: 320
        }
    }
}
