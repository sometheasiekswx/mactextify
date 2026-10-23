import XCTest
import AppKit
import ImageIO
import VisionKit
import UniformTypeIdentifiers
@testable import OCRCore

/// All image data is generated from original synthetic text at test time.
final class VisionTests: XCTestCase {
    func image(_ lines: [String], columns: Bool = false, orientation: UInt32 = 1) throws -> Data {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1600, pixelsHigh: 800,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSColor.white.setFill(); NSRect(x: 0, y: 0, width: 1600, height: 800).fill()
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 38, weight: .regular), .foregroundColor: NSColor.black]
        for (i, line) in lines.enumerated() {
            let x = columns && i >= lines.count / 2 ? 820 : 50
            let row = columns ? i % (lines.count / 2) : i
            (line as NSString).draw(at: NSPoint(x: x, y: 700 - row * 90), withAttributes: attributes)
        }
        NSGraphicsContext.restoreGraphicsState()
        let result = NSMutableData()
        let destination = CGImageDestinationCreateWithData(result, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, bitmap.cgImage!, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return result as Data
    }
    func testResearchNotesAndNumbers() throws {
        let lines = ["Research notes", "Sample count: 42", "Duration: 130 minutes", "Result: repeat the experiment"]
        let result = try VisionRecognizer().recognize(image(lines), configuration: Configuration())
        let text = result.lines.map(\.text).joined(separator: "\n")
        for line in lines { XCTAssertTrue(text.contains(line), text) }
        XCTAssertTrue(result.lines.allSatisfy { (0...1).contains($0.confidence!) })
        XCTAssertLessThan(text.range(of: "Research notes")!.lowerBound, text.range(of: "Sample count")!.lowerBound)
    }
    func testTechnicalIdentifiersCorrectionOnAndOff() throws {
        let data = try image(["Technical notes", "HTTP 503 retry", "S3 EC2 IAM VPC", "A. Use a queue", "B. Add a replica"])
        for correction in [false, true] {
            var config = Configuration(); config.correction = correction
            let text = try VisionRecognizer().recognize(data, configuration: config).lines.map(\.text).joined(separator: "\n")
            for expected in ["503", "S3", "EC2", "IAM", "VPC", "A.", "B."] { XCTAssertTrue(text.contains(expected), text) }
        }
    }
    func testTwoColumnsRetainAllContentWithoutClaimingSemanticOrder() throws {
        let data = try image(["Left alpha", "Left beta", "Right gamma", "Right delta"], columns: true)
        let text = try VisionRecognizer().recognize(data, configuration: Configuration()).lines.map(\.text).joined(separator: "\n")
        for expected in ["Left alpha", "Left beta", "Right gamma", "Right delta"] { XCTAssertTrue(text.contains(expected), text) }
    }
    func testSupportedLanguageSelection() throws {
        let engine = VisionRecognizer()
        XCTAssertTrue(try engine.supportedLanguages().contains("en-US"))
        var config = Configuration(); config.languages = ["fr-FR"]
        let result = try engine.recognize(image(["Bonjour le monde", "Recherche scientifique"]), configuration: config)
        XCTAssertTrue(result.lines.map(\.text).joined().contains("Bonjour"))
    }
    func testCorruptAndBlankImagesFail() throws {
        XCTAssertThrowsError(try VisionRecognizer().recognize(Data("broken".utf8), configuration: Configuration()))
        XCTAssertThrowsError(try VisionRecognizer().recognize(image([]), configuration: Configuration()))
    }
    func testExifOrientationRestoresRotatedPixels() throws {
        let upright = try image(["Orientation check 42"])
        let source = CGImageSourceCreateWithData(upright as CFData, nil)!
        let original = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        let context = CGContext(data: nil, width: original.height, height: original.width,
                                bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.translateBy(x: 0, y: CGFloat(original.width))
        context.rotate(by: -.pi / 2)
        context.draw(original, in: CGRect(x: 0, y: 0, width: original.width, height: original.height))
        let bytes = NSMutableData()
        let destination = CGImageDestinationCreateWithData(bytes, UTType.jpeg.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, [kCGImagePropertyOrientation: 8] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let text = try VisionRecognizer().recognize(bytes as Data, configuration: Configuration()).lines.map(\.text).joined()
        XCTAssertTrue(text.contains("Orientation check 42"), text)
    }

    func testLiveTextPreservesSyntheticParagraphWithoutFabricatedConfidence() async throws {
        guard ImageAnalyzer.isSupported else { throw XCTSkip("Live Text unavailable on this runner") }
        let data = try image(["Research notes", "Distribute website traffic equally", "Address global demand with low latency"])
        let result = try await LiveTextRecognizer().recognize(data, configuration: Configuration())
        let text = result.lines.map(\.text).joined(separator: " ")
        for expected in ["Research notes", "Distribute website traffic equally", "Address global demand with low latency"] {
            XCTAssertTrue(text.contains(expected), text)
        }
        XCTAssertTrue(result.lines.allSatisfy { $0.confidence == nil && $0.x == nil })
        XCTAssertTrue(result.engine.contains("Live Text"))
    }
    func testLiveTextRejectsBlankAndCorruptImages() async throws {
        guard ImageAnalyzer.isSupported else { throw XCTSkip("Live Text unavailable on this runner") }
        for data in [Data("corrupt".utf8), try image([])] {
            do {
                _ = try await LiveTextRecognizer().recognize(data, configuration: Configuration())
                XCTFail("Expected no-text/decode failure")
            } catch { }
        }
    }

    func testLiveTextResamplingRetainsSyntheticText() async throws {
        guard ImageAnalyzer.isSupported else { throw XCTSkip("Live Text unavailable on this runner") }
        let data = try image(["Research sample 42", "Distribute website traffic equally"])
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        for invalid in [Double.nan, Double.infinity, -1, 0, 3] {
            XCTAssertThrowsError(try scaledImage(decoded, factor: invalid))
        }
        for scale in [0.5, 1.5] {
            var config = Configuration(); config.imageScale = scale
            let result = try await LiveTextRecognizer().recognize(data, configuration: config)
            let text = result.lines.map(\.text).joined(separator: " ")
            XCTAssertTrue(text.contains("Research sample 42"), text)
            XCTAssertTrue(text.contains("Distribute website traffic equally"), text)
        }
    }

}
