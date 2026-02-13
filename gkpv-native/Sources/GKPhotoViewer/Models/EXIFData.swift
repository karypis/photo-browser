import Foundation

struct EXIFData {
    var make: String?
    var model: String?
    var lensModel: String?
    var exposureTime: Double?
    var fNumber: Double?
    var iso: Int?
    var dateTimeOriginal: String?
    var focalLength: Double?
    var pixelWidth: Int?
    var pixelHeight: Int?

    var cameraDescription: String? {
        let parts = [make, model].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    var settingsDescription: String? {
        let parts = [
            FormatHelpers.formatFocalLength(focalLength),
            FormatHelpers.formatAperture(fNumber),
            FormatHelpers.formatShutter(exposureTime),
            iso.map { "ISO \($0)" },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "  ")
    }
}
