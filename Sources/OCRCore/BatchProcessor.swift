import Foundation

public struct BatchSelection {
    public var files: [URL] = []
    public var excluded: [String] = []
    public init() {}
    public static func scan(_ urls: [URL], recursive: Bool) throws -> Self {
        var result = Self(), seen = Set<String>()
        let explicitPaths = Set(urls.map { $0.standardizedFileURL.path })
        func visit(_ url: URL, descend: Bool) throws {
            try Task.checkCancellation()
            let u = url.standardizedFileURL
            guard seen.insert(u.path).inserted else { return }
            let info: URLResourceValues
            do { info = try u.resourceValues(forKeys: [.isSymbolicLinkKey,.isDirectoryKey,.isRegularFileKey,.isPackageKey,.isHiddenKey]) }
            catch { result.excluded.append("\(u.lastPathComponent): \(error.localizedDescription)"); return }
            guard info.isSymbolicLink != true, info.isHidden != true, info.isPackage != true else { result.excluded.append("\(u.lastPathComponent): hidden, package or symbolic link"); return }
            if info.isDirectory == true {
                if !descend && !explicitPaths.contains(u.path) { result.excluded.append("\(u.lastPathComponent): subfolder excluded"); return }
                if FileManager.default.fileExists(atPath: u.appendingPathComponent(".ocr-state").path) && !explicitPaths.contains(u.path) { result.excluded.append("\(u.lastPathComponent): managed output folder"); return }
                do { for child in try FileManager.default.contentsOfDirectory(at: u, includingPropertiesForKeys: nil).sorted(by: { $0.path < $1.path }) { try visit(child, descend: recursive) } }
                catch is CancellationError { throw CancellationError() }
                catch { result.excluded.append("\(u.lastPathComponent): \(error.localizedDescription)") }
            } else if info.isRegularFile == true && ["png","jpg","jpeg"].contains(u.pathExtension.lowercased()) { result.files.append(u) }
            else { result.excluded.append("\(u.lastPathComponent): unsupported file") }
        }
        for url in urls { try visit(url, descend: true) }
        return result
    }
}

public enum BatchItemState: String { case extracting, exported, skipped, needsReview = "Needs review", failed, cancelled }
public struct BatchEvent {
    public let source: URL
    public let state: BatchItemState
    public let detail: String
    public let output: URL?
}
private struct BatchEntry: Codable { var receipt: Receipt; let source: URL }
private struct BatchOwner: Codable { let schema: Int }

public enum BatchDestination {
    public static func resolve(parent: URL, folderName: String?) throws -> URL {
        let parent = parent.standardizedFileURL
        if let folderName {
            guard !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !folderName.contains("/"), !folderName.contains("\\"), !folderName.contains("\0"),
                  ![".","..",".ocr-state"].contains(folderName), !folderName.hasPrefix(".") else { throw OCRFailure("Enter a folder name without slashes or leading dots.") }
            return parent.appendingPathComponent(folderName, isDirectory: true)
        }
        return parent
    }
}

public final class BatchProcessor {
    private let recognizer: Recognizer
    public init(recognizer: Recognizer = LocalRecognizer()) { self.recognizer = recognizer }
    public func process(files: [URL], destination: URL, configuration: Configuration,
                        checkpoint: (Checkpoint) throws -> Void = { _ in },
                        event: (BatchEvent) async -> Void) async throws {
        try configuration.validate()
        guard !configuration.archive else { throw OCRFailure("Batch processing keeps originals in place.") }
        let supported = try recognizer.supportedLanguages(for: configuration)
        guard configuration.languages.allSatisfy(supported.contains) else { throw OCRFailure("Unsupported OCR language.") }
        let dest = destination.standardizedFileURL
        guard !files.contains(where: { $0.standardizedFileURL.deletingLastPathComponent() == dest || $0.standardizedFileURL.path.hasPrefix(dest.path + "/") }) else { throw OCRFailure("Choose an output folder separate from the selected images.") }
        let store = try Storage(batchDestination: dest)
        let marker = store.state.appendingPathComponent("batch-owner.json")
        func validateOwner() throws {
            if store.exists(marker) {
                guard try JSONDecoder().decode(BatchOwner.self, from: store.read(marker)).schema == 1 else { throw OCRFailure("Unsupported batch state version.") }
            } else if store.exists(store.state) {
                let names = try FileManager.default.contentsOfDirectory(atPath: store.state.path)
                guard names.allSatisfy({ ["records","lock"].contains($0) }),
                      (try !store.exists(store.records) || FileManager.default.contentsOfDirectory(atPath: store.records.path).isEmpty) else { throw OCRFailure("This destination contains CLI or unknown state. Choose a different output folder.") }
            }
        }
        try validateOwner()
        try Task.checkCancellation()
        try store.prepare()
        let lock = try FolderLock(store.state.appendingPathComponent("lock"))
        defer { withExtendedLifetime(lock) {} }
        try validateOwner()
        try store.validateIndexOwnership()
        if !store.exists(marker) { try store.write(JSONEncoder().encode(BatchOwner(schema: 1)), to: marker) }
        let entriesDir = store.state.appendingPathComponent("batch-records", isDirectory: true)
        if !store.exists(entriesDir) { try FileManager.default.createDirectory(at: entriesDir, withIntermediateDirectories: false) }
        try store.requireDirectory(entriesDir)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
        var entries = [String: BatchEntry]()
        func outputData(_ entry: BatchEntry) -> Data {
            let from = dest.pathComponents, to = entry.source.pathComponents
            var i = 0
            while i < min(from.count,to.count) && from[i] == to[i] { i += 1 }
            return render(entry.receipt, archived: false, sourceLink: (Array(repeating: "..", count: from.count-i) + to.dropFirst(i).map(linkComponent)).joined(separator: "/"))
        }
        func persist(_ entry: BatchEntry) throws {
            let file = entriesDir.appendingPathComponent(entry.receipt.id + ".json")
            try store.write(encoder.encode(entry), to: file, replace: store.exists(file))
        }
        func publish(_ entry: inout BatchEntry) throws {
            let output = dest.appendingPathComponent(entry.receipt.outputName)
            if store.exists(output) {
                guard try store.read(output) == outputData(entry) else { throw OCRFailure("An existing export was edited; it will not be replaced.") }
            } else {
                guard entry.receipt.stage == .prepared else { throw OCRFailure("An existing export is missing; automatic replacement is disabled.") }
                try store.write(outputData(entry), to: output)
            }
            try checkpoint(.outputPublished)
            if entry.receipt.stage == .prepared { entry.receipt.stage = .exported; try persist(entry) }
        }
        for url in try FileManager.default.contentsOfDirectory(at: entriesDir, includingPropertiesForKeys: nil).filter({ $0.pathExtension == "json" }) {
            var entry = try JSONDecoder().decode(BatchEntry.self, from: store.read(url))
            try entry.receipt.validate(fileID: url.deletingPathExtension().lastPathComponent)
            guard !entry.receipt.configuration.archive, entry.source.isFileURL, entry.source.path.hasPrefix("/") else { throw OCRFailure("Invalid batch source or archive policy.") }
            try publish(&entry)
            entries[entry.receipt.id] = entry
        }
        defer { try? store.rebuildIndex(entries.values.map(\.receipt)) }
        for (index, source) in files.enumerated() {
            if Task.isCancelled {
                for pending in files[index...] { await event(BatchEvent(source: pending, state: .cancelled, detail: "Stopped before extraction", output: nil)) }
                break
            }
            await event(BatchEvent(source: source, state: .extracting, detail: "Reading text on your Mac…", output: nil))
            var publishing = false
            do {
                let data = try store.read(source), id = digest(data)
                if let entry = entries[id] {
                    guard entry.receipt.configuration == configuration else { throw OCRFailure("Saved settings differ. Choose a new destination for different settings.") }
                    await event(BatchEvent(source: source, state: .skipped, detail: "Already extracted or duplicate content", output: dest.appendingPathComponent(entry.receipt.outputName)))
                    continue
                }
                let result: Recognition
                do { result = try await recognizer.recognize(data, configuration: configuration) }
                catch is CancellationError { throw CancellationError() }
                catch let error as OCRFailure { throw error }
                catch { throw OCRFailure("The OCR engine could not read this image. Try Vision OCR in settings or use a clearer PNG/JPEG image.") }
                guard !result.lines.isEmpty, result.lines.contains(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw OCRFailure("No text detected.") }
                guard digest(try store.read(source)) == id else { throw OCRFailure("Image changed during extraction. Retry when stable.") }
                var receipt = Receipt(id: id, originalName: source.lastPathComponent, configuration: configuration, created: ISO8601DateFormatter().string(from: Date()), engine: result.engine, version: toolVersion, lines: result.lines)
                receipt.evidence = result.evidence
                var entry = BatchEntry(receipt: receipt, source: source.standardizedFileURL)
                guard !store.exists(dest.appendingPathComponent(receipt.outputName)) else { throw OCRFailure("An unowned export already exists. Choose a different destination.") }
                publishing = true
                try persist(entry)
                entries[id] = entry
                try checkpoint(.prepared)
                try publish(&entry)
                entries[id] = entry
                await event(BatchEvent(source: source, state: receipt.reviewNeeded ? .needsReview : .exported, detail: receipt.reviewNeeded ? "Extracted • review text accuracy" : "Extracted", output: dest.appendingPathComponent(receipt.outputName)))
            } catch {
                await event(BatchEvent(source: source, state: Task.isCancelled && !publishing ? .cancelled : .failed, detail: String(describing: error), output: nil))
                // Stop on publication errors; a persisted pending record must recover first.
                if publishing || entries.values.contains(where: { $0.receipt.stage == .prepared }) { throw error }
            }
        }
        try store.rebuildIndex(entries.values.map(\.receipt))
    }
}
