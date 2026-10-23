import Foundation
import Vision
import VisionKit
import ImageIO

/// Raster-only layout detection for broad, light-background text pages.
/// Unsupported/dense graphical/multi-column layouts keep the whole-image path.
struct TextPageLayout {
    let panel: Range<Int>
    let paragraphs: [Range<Int>]
    let rows: [Range<Int>]

    static func detect(_ image: CGImage) -> TextPageLayout? {
        let w = image.width, h = image.height
        guard w >= 400, h >= 200, w <= 6000, h <= 6000, w * h <= 16_000_000 else { return nil }
        var pixels = [UInt8](repeating: 255, count: w * h * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8,
                bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: w, height: h))
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h)); return true
        }
        guard drawn else { return nil }
        var white = [Int](repeating: 0, count: w)
        for y in 0..<h { for x in 0..<w {
            let p = (y * w + x) * 4
            if min(pixels[p], pixels[p+1], pixels[p+2]) > 235 { white[x] += 1 }
        } }
        guard let panel = runs(white.map { $0 > h / 2 }).max(by: { $0.count < $1.count }),
              panel.count * 10 >= w * 7 else { return nil }
        var density = [Int](repeating: 0, count: h), columns = [Int](repeating: 0, count: w)
        for y in 0..<h { for x in panel {
            let p = (y * w + x) * 4
            if min(pixels[p], pixels[p+1], pixels[p+2]) < 180 { density[y] += 1; columns[x] += 1 }
        } }
        // Avoid rules, tables and large graphical solids. Do not interpret columns as sentences.
        guard density.max() ?? 0 < panel.count * 4 / 5 else { return nil }
        if let left = panel.first(where: { columns[$0] > 3 }), let right = panel.last(where: { columns[$0] > 3 }), left < right {
            let gutters = runs((left...right).map { columns[$0] <= 3 })
            guard !gutters.contains(where: { $0.count > panel.count / 16 }) else { return nil }
        }
        let paragraphs = runs(density.map { $0 > 3 }).filter { $0.count >= 3 }
        guard (3...60).contains(paragraphs.count) else { return nil }
        let radius = max(4, w / 190)
        let active = (0..<h).map { y in
            density[y] > max(3, Int(Double(density[max(0,y-radius)...min(h-1,y+radius)].max() ?? 0) * 0.12))
        }
        let rows = runs(active).filter { $0.count >= max(5, w / 240) }
        guard rows.count >= paragraphs.count, rows.count <= 100 else { return nil }
        // Each paragraph must have row evidence; otherwise preserve the original layout.
        guard paragraphs.allSatisfy({ paragraph in rows.contains { paragraph.contains(($0.lowerBound + $0.upperBound) / 2) } }) else { return nil }
        return TextPageLayout(panel: panel, paragraphs: paragraphs, rows: rows)
    }
    static func runs(_ flags: [Bool]) -> [Range<Int>] {
        var result = [Range<Int>](), start: Int?
        for i in 0...flags.count {
            if i < flags.count && flags[i] { if start == nil { start = i } }
            else if let s = start { result.append(s..<i); start = nil }
        }
        return result
    }
}

struct AdaptiveOCR {
    static func containsAllRecognizedText(_ image: CGImage, layout: TextPageLayout, languages: [String]) throws -> Bool {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate; request.recognitionLanguages = languages
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).allSatisfy { observation in
            let box = observation.boundingBox
            // Vision uses a bottom-left origin; raster bands/crops use a top-left origin.
            let top = (1 - box.maxY) * Double(image.height)
            let bottom = (1 - box.minY) * Double(image.height)
            let padding = max(1, image.width / 1434)
            // Vision boxes include whitespace around glyphs (and skew), whereas the
            // raster bands bound ink. Allow a capped one-third line-height margin for that
            // difference; it must not bridge a missing paragraph in a band gap.
            let margin = max(3.0, min(20.0, (bottom - top) / 3))
            // Horizontal coverage alone misses low-contrast text between ink bands.
            guard box.minX * Double(image.width) >= Double(layout.panel.lowerBound - 3),
                  box.maxX * Double(image.width) <= Double(layout.panel.upperBound + 3) else { return false }
            // A box may span adjacent bands. Check their union, not just its midpoint
            // or endpoints: an uncovered interval must trigger whole-image fallback.
            var coveredThrough = top
            for band in layout.paragraphs.sorted(by: { $0.lowerBound < $1.lowerBound }) {
                let start = Double(max(0, band.lowerBound - padding)) - margin
                let end = Double(min(image.height, band.upperBound + padding)) + margin
                if end < coveredThrough { continue }
                if start > coveredThrough { return false }
                coveredThrough = max(coveredThrough, end)
                if coveredThrough >= bottom { return true }
            }
            return false
        }
    }
    static let factors = [1.0, 1.5, 2.0, 1.25, 1.75, 2.25]
    static func recognize(_ image: CGImage, languages: [String], layout: TextPageLayout) async throws -> Recognition {
        var settings = ImageAnalyzer.Configuration([.text]); settings.locales = languages
        let analyzer = ImageAnalyzer()
        var candidates = [[String]]()
        for paragraph in layout.paragraphs {
            var passes = [String]()
            for factor in factors {
                let crop = try canvas(image, panel: layout.panel, band: paragraph, padding: max(1, image.width / 1434), verticalScale: factor)
                passes.append(try await analyzer.analyze(crop, orientation: .up, configuration: settings).transcript)
            }
            candidates.append(passes)
        }
        for (i, paragraph) in layout.paragraphs.enumerated() {
            var live = [String](), vision = [String]()
            for row in layout.rows where paragraph.contains((row.lowerBound + row.upperBound) / 2) {
                let liveCrop = try canvas(image, panel: layout.panel, band: row, padding: max(2, image.width / 358), verticalScale: 1)
                live.append(try await analyzer.analyze(liveCrop, orientation: .up, configuration: settings).transcript)
                let crop = try canvas(image, panel: layout.panel, band: row, padding: max(1, image.width / 956), verticalScale: 1)
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate; request.usesLanguageCorrection = true; request.recognitionLanguages = languages
                try VNImageRequestHandler(cgImage: crop).perform([request])
                vision.append((request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " "))
            }
            candidates[i].append(live.joined(separator: " "))
            candidates[i].append(vision.joined(separator: " "))
        }
        let selected = OCRConsensus.resolve(candidates)
        guard selected.allSatisfy({ !$0.isEmpty }) else { throw OCRFailure("Adaptive OCR found an empty text region; source left untouched. Try --layout whole.") }
        let evidence = candidates.enumerated().map { i, passes in
            RecognitionEvidence(region: i + 1, candidates: passes.map(OCRConsensus.normalize), selected: selected[i])
        }
        return Recognition(lines: selected.map { TextLine($0, confidence: nil, x: nil, y: nil, width: nil, height: nil) },
            engine: "Apple Live Text + Vision; adaptive paragraphs/rows v2; \(ProcessInfo.processInfo.operatingSystemVersionString)", evidence: evidence)
    }
    static func canvas(_ image: CGImage, panel: Range<Int>, band: Range<Int>, padding: Int, verticalScale: Double) throws -> CGImage {
        let top = max(0, band.lowerBound - padding), bottom = min(image.height, band.upperBound + padding)
        guard let crop = image.cropping(to: CGRect(x: panel.lowerBound, y: top, width: panel.count, height: bottom-top)) else {
            throw OCRFailure("Cannot crop detected text region.")
        }
        let border = max(10, image.width / 143)
        let height = Int(Double(crop.height) * verticalScale)
        guard let context = CGContext(data: nil, width: crop.width, height: height + border * 2, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw OCRFailure("Cannot allocate text-region canvas.")
        }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
        context.draw(crop, in: CGRect(x: 0, y: border, width: crop.width, height: height))
        guard let result = context.makeImage() else { throw OCRFailure("Text-region rendering failed.") }
        return result
    }
}
