import Foundation

public enum Checkpoint: String, CaseIterable {
    case prepared, outputPublished, exported, archiveMoved, archived, linkUpdated
}
public struct RunSummary {
    public var exported = 0, resumed = 0, skipped = 0, reviewNeeded = 0, failed = 0
    public init() {}
    public var description: String {
        "Exported: \(exported); resumed: \(resumed); skipped/duplicates: \(skipped); needs review: \(reviewNeeded); failed: \(failed)."
    }
}
public final class Processor {
    private let storage: Storage
    private let recognizer: Recognizer
    private let checkpoint: (Checkpoint) throws -> Void
    private let report: (String) -> Void
    public init(root: URL, recognizer: Recognizer = LocalRecognizer(),
                checkpoint: @escaping (Checkpoint) throws -> Void = { _ in },
                report: @escaping (String) -> Void = { print($0) }) throws {
        storage = try Storage(root: root); self.recognizer = recognizer
        self.checkpoint = checkpoint; self.report = report
    }
    public func status() throws {
        let records = try storage.loadReceipts()
        for receipt in records {
            report("\(displayName(receipt.originalName)): \(receipt.stage.rawValue)\(receipt.reviewNeeded ? ", needs-review" : ", unverified")")
        }
        report("\(records.count) recorded images; \(try storage.inputs().count) candidate inputs. Status is a read-only snapshot; process validates files.")
    }
    public func process(configuration: Configuration, dryRun: Bool = false) async throws -> RunSummary {
        try configuration.validate()
        let supported = try recognizer.supportedLanguages(for: configuration)
        guard configuration.languages.allSatisfy(supported.contains) else {
            throw OCRFailure("Unsupported recognition language; run mactextify languages.")
        }
        var summary = RunSummary()
        if dryRun {
            let records = try storage.loadReceipts()
            do { try storage.validateIndexOwnership() }
            catch { summary.failed += 1; report("ERROR: \(error)") }
            for receipt in records {
                do { try validateExisting(receipt); report("Recorded: \(displayName(receipt.originalName)) (\(receipt.stage.rawValue))") }
                catch { summary.failed += 1; report("ERROR: \(error)") }
            }
            for input in try storage.inputs() {
                do {
                    let id = digest(try storage.read(input))
                    if let prior = records.first(where: { $0.id == id }) {
                        if prior.configuration != configuration { throw OCRFailure("Configuration conflict: \(displayName(input.lastPathComponent)).") }
                        report("Skip/resume: \(displayName(input.lastPathComponent))")
                    } else {
                        let prospective = Receipt(id: id, originalName: input.lastPathComponent,
                                                  configuration: configuration, created: "", engine: "", version: toolVersion, lines: [])
                        guard !storage.exists(storage.outputs.appendingPathComponent(prospective.outputName)),
                              !storage.exists(storage.archives.appendingPathComponent(prospective.archiveName)) else {
                            throw OCRFailure("Unowned output/archive collision: \(displayName(input.lastPathComponent)).")
                        }
                        report("Would export\(configuration.archive ? " and archive" : ""): \(displayName(input.lastPathComponent))")
                    }
                } catch { summary.failed += 1; report("ERROR: \(error)") }
            }
            report("Dry run: no OCR or filesystem changes.")
            return summary
        }
        try storage.prepare()
        let lock = try FolderLock(storage.state.appendingPathComponent("lock"))
        defer { withExtendedLifetime(lock) {} }
        var records = try storage.loadReceipts()
        // Failures in one record do not cause the same image to be re-OCR'd below.
        for i in records.indices {
            do {
                let before = records[i].stage
                try reconcile(&records[i])
                if before != records[i].stage { summary.resumed += 1 }
            } catch { summary.failed += 1; report("ERROR \(displayName(records[i].originalName)): \(error)") }
        }
        for input in try storage.inputs() {
            do {
                let data = try storage.read(input)
                let id = digest(data)
                if let prior = records.first(where: { $0.id == id }) {
                    guard prior.configuration == configuration else {
                        throw OCRFailure("Configuration differs from saved extraction; existing files were not changed.")
                    }
                    summary.skipped += 1
                    report("Skipped existing/duplicate: \(displayName(input.lastPathComponent))")
                    continue
                }
                let result = try await recognizer.recognize(data, configuration: configuration)
                guard !result.lines.isEmpty, result.lines.contains(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                    throw OCRFailure("No text recognized; source untouched.")
                }
                var receipt = Receipt(id: id, originalName: input.lastPathComponent,
                                      configuration: configuration, created: ISO8601DateFormatter().string(from: Date()),
                                      engine: result.engine, version: toolVersion, lines: result.lines)
                receipt.evidence = result.evidence
                guard digest(try storage.read(input)) == id else { throw OCRFailure("Source changed during recognition; retry when stable.") }
                let output = storage.outputs.appendingPathComponent(receipt.outputName)
                let archive = storage.archives.appendingPathComponent(receipt.archiveName)
                guard !storage.exists(output), !storage.exists(archive) else { throw OCRFailure("Unowned output/archive collision; no changes made to source.") }
                try storage.save(receipt, new: true)
                records.append(receipt)
                try checkpoint(.prepared)
                try reconcile(&receipt)
                records[records.count - 1] = receipt
                summary.exported += 1
                if receipt.reviewNeeded { summary.reviewNeeded += 1 }
                report("Exported\(receipt.reviewNeeded ? " (needs-review)" : ""): \(displayName(input.lastPathComponent))")
            } catch { summary.failed += 1; report("ERROR \(displayName(input.lastPathComponent)): \(error)") }
        }
        do { try storage.rebuildIndex(storage.loadReceipts()) }
        catch { summary.failed += 1; report("ERROR index: \(error)") }
        return summary
    }
    private func validateExisting(_ receipt: Receipt) throws {
        let output = storage.outputs.appendingPathComponent(receipt.outputName)
        if storage.exists(output) {
            let data = try storage.read(output)
            guard data == render(receipt, archived: false) ||
                    (receipt.configuration.archive && data == render(receipt, archived: true)) else {
                throw OCRFailure("Export edited or corrupt; refusing to replace it.")
            }
        } else if receipt.stage != .prepared { throw OCRFailure("Saved export is missing; refusing automatic regeneration.") }
        let source = storage.root.appendingPathComponent(receipt.originalName)
        let archive = storage.archives.appendingPathComponent(receipt.archiveName)
        if receipt.configuration.archive && storage.exists(archive) {
            guard digest(try storage.read(archive)) == receipt.id else { throw OCRFailure("Archive collision or changed archived bytes.") }
        } else {
            guard digest(try storage.read(source)) == receipt.id else { throw OCRFailure("Source changed; cannot resume.") }
        }
    }
    private func reconcile(_ receipt: inout Receipt) throws {
        try validateExisting(receipt)
        let output = storage.outputs.appendingPathComponent(receipt.outputName)
        let source = storage.root.appendingPathComponent(receipt.originalName)
        let archive = storage.archives.appendingPathComponent(receipt.archiveName)
        if receipt.stage == .prepared {
            if !storage.exists(output) { try storage.write(render(receipt, archived: false), to: output) }
            try checkpoint(.outputPublished)
            receipt.stage = .exported
            try storage.save(receipt)
            try checkpoint(.exported)
        }
        if receipt.configuration.archive {
            try storage.prepareArchive()
            if storage.exists(archive) {
                guard digest(try storage.read(archive)) == receipt.id else {
                    throw OCRFailure("Archive collision or changed archived bytes; source retained.")
                }
                if receipt.stage != .archived && storage.exists(source) {
                    throw OCRFailure("Both source and archive exist; refusing ambiguous recovery.")
                }
            } else {
                guard receipt.stage != .archived else { throw OCRFailure("Archived original missing; cannot silently archive a replacement.") }
                guard digest(try storage.read(source)) == receipt.id else { throw OCRFailure("Source changed before archival.") }
                guard try storage.read(output) == render(receipt, archived: false) else {
                    throw OCRFailure("Export changed before archival; source retained.")
                }
                try storage.move(source, to: archive)
                try checkpoint(.archiveMoved)
            }
            guard digest(try storage.read(archive)) == receipt.id else {
                throw OCRFailure("Archived bytes changed; refusing to finalize.")
            }
            if receipt.stage != .archived {
                receipt.stage = .archived
                try storage.save(receipt)
                try checkpoint(.archived)
            }
            let final = render(receipt, archived: true)
            let existing = try storage.read(output)
            guard existing == final || existing == render(receipt, archived: false) else {
                throw OCRFailure("Export changed before link update; refusing to replace it.")
            }
            if existing != final { try storage.write(final, to: output, replace: true) }
            try checkpoint(.linkUpdated)
        }
    }
}
