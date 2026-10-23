import XCTest
import AppKit
import VisionKit
@testable import OCRCore

final class AdaptiveOCRTests: XCTestCase {
    func testConsensusKeepsLiteralIdentifiersAndNegation() {
        let blocks = [["Keep X7 and X8 separate. Do not delete 17 files.",
                       "Keep X7 and X8 separate. Do not delete 17 files.",
                       "Keep X7 and X8 separate. Do not delete 17 files."]]
        XCTAssertEqual(OCRConsensus.resolve(blocks), [blocks[0][0]])
    }
    func testConsensusLocalMajoritySurvivesUnrelatedIdentifierFrequency() {
        let expected = "Keep X7 separate from the remaining workers."
        let candidates = Array(repeating: expected, count: 6) +
            Array(repeating: "Keep X8 separate from the remaining workers.", count: 2)
        XCTAssertEqual(OCRConsensus.resolve([candidates]), [expected])
        let unrelated = Array(repeating: String(repeating: "X8 ", count: 10), count: 8)
        XCTAssertEqual(OCRConsensus.resolve([candidates, unrelated])[0], expected)
        XCTAssertEqual(OCRConsensus.resolve([unrelated, candidates])[1], expected)
    }
    func testConsensusFrequencyOnlyBreaksLocalTies() {
        let first = "Keep X7 separate from the remaining workers."
        let second = "Keep X8 separate from the remaining workers."
        let tied = Array(repeating: first, count: 4) + Array(repeating: second, count: 4)
        XCTAssertEqual(OCRConsensus.resolve([tied])[0], first)
        XCTAssertEqual(OCRConsensus.resolve([tied, ["X8 X8 X8"]])[0], second)
    }
    func testMixedContrastPageFallsBackWithoutLosingGreyParagraph() async throws {
        guard ImageAnalyzer.isSupported else { throw XCTSkip("Live Text unavailable on this runner") }
        for greyIndex in [0, 2, 3] {
            let width = 1600, height = 900
            let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
            NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            NSColor.white.setFill(); NSRect(x: 0, y: 0, width: width, height: height).fill()
            var lines = ["First paragraph with black text.", "Second paragraph with black text.",
                         "Third paragraph with black text."]
            lines.insert("Do not delete the original files.", at: greyIndex)
            for (i, line) in lines.enumerated() {
                (line as NSString).draw(at: NSPoint(x: 180, y: 740-i*180), withAttributes: [
                    .font: NSFont.systemFont(ofSize: 36),
                    .foregroundColor: i == greyIndex ? NSColor(calibratedWhite: 0.77, alpha: 1) : NSColor.black])
            }
            NSGraphicsContext.restoreGraphicsState()
            let data = bitmap.representation(using: .png, properties: [:])!
            XCTAssertNotNil(TextPageLayout.detect(bitmap.cgImage!), "Fixture must reach crop safety check")
            var configuration = Configuration(); configuration.layout = .whole
            let whole = try await LiveTextRecognizer().recognize(data, configuration: configuration)
            configuration.layout = .automatic
            let automatic = try await LiveTextRecognizer().recognize(data, configuration: configuration)
            let text = OCRConsensus.normalize(automatic.lines.map(\.text).joined(separator: " "))
            XCTAssertEqual(text, OCRConsensus.normalize(whole.lines.map(\.text).joined(separator: " ")))
            for line in lines { XCTAssertTrue(text.contains(line), "Missing: \(line)") }
            XCTAssertNil(automatic.evidence, "Uncovered text must retain whole-image recognition")
        }
    }
    func testConsensusRepairsObservedTypoAndRejectsGarbledPass() {
        let blocks = [["Distribute requests across replicas.", "Distribute requests across replicas.",
                       "Distribute requests across replicas.", "Disiribute requests across replicas.", "rpl df"]]
        XCTAssertEqual(OCRConsensus.resolve(blocks), [blocks[0][0]])
    }
    func testAlignmentRetainsMissingWordFromOtherPasses() {
        let aligned = OCRConsensus.align(["the", "location"], ["the", "user's", "location"])
        XCTAssertEqual(aligned.words, ["the", "location"])
        XCTAssertEqual(aligned.insertions, ["", "user's", ""])
        XCTAssertEqual(OCRConsensus.align([], ["a"]).insertions, ["a"])
        XCTAssertEqual(OCRConsensus.align(["a"], []).words, [""])
    }
    func testConsensusDoesNotInventCorrectionWithoutPixelCandidate() {
        XCTAssertEqual(OCRConsensus.resolve([["A massage arrived.", "A massage arrived."]]), ["A massage arrived."])
        XCTAssertEqual(OCRConsensus.resolve([[]]), [""])
        let long = String(repeating: "sample ", count: 500)
        XCTAssertEqual(OCRConsensus.resolve([[long]]), [OCRConsensus.normalize(long)])
    }
    func testConsensusTiePrefersMostRepresentativePass() {
        let candidates = ["QZ alpha beta gamma delta error", "QZ alpha beta gamma typo epsilon",
                          "XYZ alpha beta wrong delta epsilon", "Q2 alpha beta gamma delta epsilon",
                          "QZ typo beta gamma delta epsilon", "Q2 alpha beta gamma delta epsilon",
                          "Q2 alpha beta gamma delta epsilon"]
        XCTAssertEqual(OCRConsensus.resolve([candidates]), ["Q2 alpha beta gamma delta epsilon"])
    }
    func testWholeLayoutDecodesForLegacyConfiguration() throws {
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(Configuration())) as! [String: Any]
        json.removeValue(forKey: "layout")
        let old = try JSONDecoder().decode(Configuration.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(old.selectedLayout, .whole)
        XCTAssertNotEqual(old, Configuration())
    }
    func testDetectorRejectsBlankAndMultiColumnPages() throws {
        let fixture = VisionTests()
        for data in [try fixture.image([]), try fixture.image(["Left alpha", "Left beta", "Right gamma", "Right delta"], columns: true)] {
            let source = CGImageSourceCreateWithData(data as CFData, nil)!
            XCTAssertNil(TextPageLayout.detect(CGImageSourceCreateImageAtIndex(source, 0, nil)!))
        }
    }
    func testSafetyCheckRejectsCropThatWouldLoseRecognizedText() throws {
        let data = try VisionTests().image(["Left label must remain", "Another visible label", "Final visible label"])
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        XCTAssertFalse(try AdaptiveOCR.containsAllRecognizedText(image, layout: TextPageLayout(panel: 500..<1600, paragraphs: [0..<image.height], rows: []), languages: ["en-US"]))
        XCTAssertTrue(try AdaptiveOCR.containsAllRecognizedText(image, layout: TextPageLayout(panel: 0..<1600, paragraphs: [0..<image.height], rows: []), languages: ["en-US"]))
    }
    func testSafetyCheckRejectsVerticalExclusionAndEmptyBands() throws {
        let data = try VisionTests().image(["Left label must remain", "Another visible label", "Final visible label"])
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
        for bands in [[0..<20], [(image.height-20)..<image.height], []] {
            XCTAssertFalse(try AdaptiveOCR.containsAllRecognizedText(image,
                layout: TextPageLayout(panel: 0..<image.width, paragraphs: bands, rows: []), languages: ["en-US"]))
        }
    }
    func testEvidenceMustMatchExportedLines() throws {
        let id = digest(Data("fixture".utf8))
        var record = Receipt(id: id, originalName: "sample.png", configuration: Configuration(),
                             created: "", engine: "fixture", version: toolVersion, lines: [TextLine("literal")])
        record.evidence = [RecognitionEvidence(region: 1, candidates: ["literal"], selected: "literal")]
        XCTAssertNoThrow(try record.validate(fileID: id))
        record.evidence = [RecognitionEvidence(region: 1, candidates: ["literal"], selected: "changed")]
        XCTAssertThrowsError(try record.validate(fileID: id))
    }
    func testDenseSyntheticSlidePreservesEveryParagraphAndEvidence() async throws {
        guard ImageAnalyzer.isSupported else { throw XCTSkip("Live Text unavailable on this runner") }
        let width = 2400, height = 1000
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSColor.white.setFill(); NSRect(x: 0, y: 0, width: width, height: height).fill()
        let groups = [
            ["Research protocol 47", "Measure the baseline before changing the experiment."],
            ["A. Distribute requests across three independent workers.", "Record every result and preserve the original sample."],
            ["B. Keep the control group separate from the treatment group.", "Do not discard negative results or alter the observations."],
            ["C. Repeat the experiment with 17 samples and 42 checks.", "Publish the uncertainty alongside the measured values."]]
        for (block, lines) in groups.enumerated() {
            for (row, line) in lines.enumerated() {
                let color = block == 1 ? NSColor(red: 0, green: 0.65, blue: 0.1, alpha: 1) : NSColor.black
                (line as NSString).draw(at: NSPoint(x: 180, y: 850-block*190-row*40), withAttributes: [
                    .font: NSFont.systemFont(ofSize: 42), .foregroundColor: color])
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        let result = try await LiveTextRecognizer().recognize(bitmap.representation(using: .png, properties: [:])!, configuration: Configuration())
        XCTAssertNotNil(result.evidence, "Synthetic slide must exercise the new path")
        let text = OCRConsensus.normalize(result.lines.map(\.text).joined(separator: " "))
        for line in groups.flatMap({ $0 }) { XCTAssertTrue(text.contains(line), "Missing: \(line)\n\(text)") }
        XCTAssertEqual(result.evidence?.map(\.selected), result.lines.map(\.text))
        XCTAssertTrue(result.evidence?.allSatisfy { $0.candidates.count == 8 } == true)
        XCTAssertTrue(result.lines.allSatisfy { $0.confidence == nil })
    }
}
