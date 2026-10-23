import Foundation
import OCRCore
import Darwin

let help = """
mactextify \(toolVersion) — local Apple Vision OCR for macOS

Usage:
  mactextify process --folder PATH [--archive] [--dry-run] [--output-folder PATH]
                         [--engine livetext|vision] [--format markdown|text] [--languages en-US,...]
                         [--layout auto|whole] [--image-scale 0.5..2] [--language-correction] [--review-threshold 0.8]
  mactextify status --folder PATH [--output-folder PATH]
  mactextify languages [--engine livetext|vision]
  mactextify --version

Defaults: keep originals, Markdown, English, Apple Live Text with automatic text-page layout.
Automatic layout uses local paragraph/row OCR passes; --layout whole disables it.
Live Text requires supported hardware and does not expose confidence scores.
Use --engine vision for legacy Vision OCR; language correction is Vision-only.
Only top-level PNG/JPEG regular files are processed. Default outputs: Extracted/.
--output-folder PATH keeps exports and independent state there; its parent must exist.
Custom output folders require keeping originals (--archive is unsupported).
--archive moves successful originals to Processed/; duplicates stay in place.
Rerun to resume interrupted work. Edited/missing outputs are never replaced.
A different configuration for a saved image is a conflict, not a reprocess.
Low confidence is a review warning, not proof of accuracy. No network or AI API.

Exit codes: 0 completed (may include warnings), 1 item failure, 2 preflight error.
"""
do {
    var args = Array(CommandLine.arguments.dropFirst())
    if args.isEmpty || args == ["--help"] || args == ["-h"] { print(help); exit(0) }
    if args == ["--version"] { print(toolVersion); exit(0) }
    if args.first == "languages" {
        var config = Configuration()
        if args.count != 1 {
            guard args.count == 3, args[1] == "--engine", let engine = OCREngine(rawValue: args[2]) else {
                throw OCRFailure("Usage: languages [--engine livetext|vision]")
            }
            config.engine = engine
        }
        print(try LocalRecognizer().supportedLanguages(for: config).joined(separator: "\n")); exit(0)
    }
    let command = args.removeFirst()
    guard ["process", "status"].contains(command) else { throw OCRFailure("Unknown command. Use --help.") }
    var configuration = Configuration()
    var folder: String?, outputFolder: String?, dryRun = false, seen = Set<String>()
    while !args.isEmpty {
        let option = args.removeFirst()
        guard seen.insert(option).inserted else { throw OCRFailure("Repeated option: \(option)") }
        func value() throws -> String {
            guard !args.isEmpty else { throw OCRFailure("Missing value for \(option).") }
            return args.removeFirst()
        }
        if command == "status" && option != "--folder" && option != "--output-folder" { throw OCRFailure("status accepts --folder and --output-folder.") }
        switch option {
        case "--output-folder": outputFolder = try value()
        case "--folder": folder = try value()
        case "--archive": configuration.archive = true
        case "--dry-run": dryRun = true
        case "--language-correction": configuration.correction = true
        case "--layout":
            guard let layout = OCRLayout(rawValue: try value()) else { throw OCRFailure("Layout must be auto or whole.") }
            configuration.layout = layout
        case "--image-scale":
            guard let scale = Double(try value()) else { throw OCRFailure("Invalid image scale.") }
            configuration.imageScale = scale
        case "--engine":
            guard let engine = OCREngine(rawValue: try value()) else { throw OCRFailure("Engine must be livetext or vision.") }
            configuration.engine = engine
        case "--format":
            guard let format = ExportFormat(rawValue: try value()) else { throw OCRFailure("Format must be markdown or text.") }
            configuration.format = format
        case "--languages": configuration.languages = try value().components(separatedBy: ",")
        case "--review-threshold":
            guard let threshold = Float(try value()) else { throw OCRFailure("Invalid review threshold.") }
            configuration.reviewThreshold = threshold
        default: throw OCRFailure("Unknown option: \(option). Use --help.")
        }
    }
    guard let folder, !folder.isEmpty else { throw OCRFailure("An explicit --folder PATH is required.") }
    if configuration.selectedEngine == .liveText && seen.contains("--review-threshold") {
        throw OCRFailure("--review-threshold requires --engine vision; Live Text has no confidence scores.")
    }
    if configuration.selectedEngine == .vision && seen.contains("--layout") && configuration.layout == .automatic {
        throw OCRFailure("--layout auto requires --engine livetext.")
    }
    if let outputFolder, outputFolder.isEmpty { throw OCRFailure("Output folder cannot be empty.") }
    let processor = try Processor(root: URL(fileURLWithPath: (folder as NSString).expandingTildeInPath),
        outputFolder: outputFolder.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) })
    if command == "status" { try processor.status() }
    else {
        let result = try await processor.process(configuration: configuration, dryRun: dryRun)
        print(result.description)
        exit(result.failed == 0 ? 0 : 1)
    }
} catch {
    FileHandle.standardError.write(Data("Error: \(error)\n".utf8)); exit(2)
}
