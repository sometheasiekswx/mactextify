import Foundation
import Vision
import ImageIO

public struct VisionRecognizer: Recognizer {
    public init() {}
    private func request() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        return request
    }
    public func supportedLanguages(for configuration: Configuration = Configuration()) throws -> [String] { try request().supportedRecognitionLanguages() }
    public func recognize(_ data: Data, configuration: Configuration) throws -> Recognition {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let original = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw OCRFailure("Image cannot be decoded as a supported image.")
        }
        let image = try scaledImage(original, factor: configuration.selectedScale)
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let raw = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: raw) ?? .up
        let request = request()
        request.recognitionLanguages = configuration.languages
        request.usesLanguageCorrection = configuration.correction
        try VNImageRequestHandler(cgImage: image, orientation: orientation).perform([request])
        // Vision's observation order preserves blocks better than a global Y/X sort.
        // Complex layouts remain unverified; don't invent semantic column structure.
        let lines = (request.results ?? []).compactMap { observation -> TextLine? in
            guard let candidate = observation.topCandidates(1).first,
                  !candidate.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            let box = observation.boundingBox
            return TextLine(candidate.string, confidence: candidate.confidence,
                            x: box.minX, y: box.minY, width: box.width, height: box.height)
        }
        guard !lines.isEmpty else { throw OCRFailure("No text recognized; source left untouched.") }
        return Recognition(lines: lines, engine: "Apple Vision revision \(request.revision); \(ProcessInfo.processInfo.operatingSystemVersionString)")
    }
}

/// Optional resampling for difficult screenshots; never changes the original bytes.
func scaledImage(_ image: CGImage, factor: Double) throws -> CGImage {
    guard factor.isFinite, (0.5...2).contains(factor) else {
        throw OCRFailure("Image scale must be between 0.5 and 2.")
    }
    if factor == 1 { return image }
    let width = max(1, Int(Double(image.width) * factor))
    let height = max(1, Int(Double(image.height) * factor))
    guard let context = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw OCRFailure("Cannot allocate resampled image; reduce --image-scale.")
    }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let result = context.makeImage() else { throw OCRFailure("Image resampling failed.") }
    return result
}
