import ImageIO
import Foundation

enum EXIFParser {
    static func parse(url: URL) -> EXIFData? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }

        var data = EXIFData()

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            data.make = tiff[kCGImagePropertyTIFFMake] as? String
            data.model = tiff[kCGImagePropertyTIFFModel] as? String
        }

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            data.exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double
            data.fNumber = exif[kCGImagePropertyExifFNumber] as? Double
            if let isoArray = exif[kCGImagePropertyExifISOSpeedRatings] as? [Int], let first = isoArray.first {
                data.iso = first
            }
            data.dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal] as? String
            data.focalLength = exif[kCGImagePropertyExifFocalLength] as? Double
            data.lensModel = exif[kCGImagePropertyExifLensModel] as? String
            data.pixelWidth = exif[kCGImagePropertyExifPixelXDimension] as? Int
            data.pixelHeight = exif[kCGImagePropertyExifPixelYDimension] as? Int
        }

        return data
    }
}
