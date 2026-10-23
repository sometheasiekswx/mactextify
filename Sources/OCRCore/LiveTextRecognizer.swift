import Foundation
import VisionKit
import ImageIO

/// Public VisionKit API. No private Apple APIs and no fabricated confidence/geometry.
public struct LiveTextRecognizer: Recognizer {
    public init() {}
    public func supportedLanguages(for configuration: Configuration = Configuration()) throws -> [String] {
        guard ImageAnalyzer.isSupported else {
            throw OCRFailure("Apple Live Text is unavailable on this hardware/OS. Use --engine vision explicitly for legacy OCR.")
        }
        return ImageAnalyzer.supportedTextRecognitionLanguages
    }
    public func recognize(_ data: Data, configuration: Configuration) async throws -> Recognition {
        _ = try supportedLanguages(for: configuration)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let original = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw OCRFailure("Image cannot be decoded as a supported image.")
        }
        let image = try scaledImage(original, factor: configuration.selectedScale)
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let raw = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: raw) ?? .up
        if configuration.selectedLayout == .automatic, orientation == .up,
           let visionLanguages = try? VisionRecognizer().supportedLanguages(for: configuration),
           configuration.languages.allSatisfy(visionLanguages.contains),
           let layout = TextPageLayout.detect(image),
           try AdaptiveOCR.containsAllRecognizedText(image, layout: layout, languages: configuration.languages) {
            return try await AdaptiveOCR.recognize(image, languages: configuration.languages, layout: layout)
        }
        var settings = ImageAnalyzer.Configuration([.text])
        settings.locales = configuration.languages
        let analysis = try await ImageAnalyzer().analyze(image, orientation: orientation, configuration: settings)
        let lines = analysis.transcript.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { TextLine($0, confidence: nil, x: nil, y: nil, width: nil, height: nil) }
        guard !lines.isEmpty else { throw OCRFailure("No text recognized; source left untouched.") }
        return Recognition(lines: lines, engine: "Apple VisionKit Live Text; \(ProcessInfo.processInfo.operatingSystemVersionString)")
    }
}

public struct LocalRecognizer: Recognizer {
    public init() {}
    public func supportedLanguages(for configuration: Configuration) throws -> [String] {
        switch configuration.selectedEngine {
        case .liveText: return try LiveTextRecognizer().supportedLanguages(for: configuration)
        case .vision: return try VisionRecognizer().supportedLanguages(for: configuration)
        }
    }
    public func recognize(_ data: Data, configuration: Configuration) async throws -> Recognition {
        switch configuration.selectedEngine {
        case .liveText: return try await LiveTextRecognizer().recognize(data, configuration: configuration)
        case .vision: return try VisionRecognizer().recognize(data, configuration: configuration)
        }
    }
}
