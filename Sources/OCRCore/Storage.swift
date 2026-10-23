import Foundation
import Darwin

public final class FolderLock {
    private var descriptor: Int32 = -1
    public init(_ url: URL) throws {
        descriptor = open(url.path, O_CREAT | O_RDWR | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard descriptor >= 0 else { throw OCRFailure("Cannot open folder lock: \(String(cString: strerror(errno))).") }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor); descriptor = -1
            throw OCRFailure("Another process is using this folder. Try again when it finishes.")
        }
    }
    deinit { if descriptor >= 0 { flock(descriptor, LOCK_UN); close(descriptor) } }
}

public final class Storage {
    public let root: URL
    private let fm = FileManager.default
    public let customOutput: URL?
    public var state: URL { (customOutput ?? root).appendingPathComponent(".ocr-state", isDirectory: true) }
    public var records: URL { state.appendingPathComponent("records", isDirectory: true) }
    public var outputs: URL { customOutput ?? root.appendingPathComponent("Extracted", isDirectory: true) }
    public var archives: URL { root.appendingPathComponent("Processed", isDirectory: true) }
    public init(root: URL, outputFolder: URL? = nil) throws {
        self.root = root.standardizedFileURL
        let requested = outputFolder?.standardizedFileURL
        self.customOutput = requested?.path == self.root.appendingPathComponent("Extracted", isDirectory: true).path ? nil : requested
        try requireDirectory(self.root)
        if let customOutput {
            guard customOutput.path != self.root.path,
                  !customOutput.path.hasPrefix(self.root.appendingPathComponent(".ocr-state").path + "/"),
                  customOutput.path != self.root.appendingPathComponent(".ocr-state").path,
                  customOutput.path != archives.path else { throw OCRFailure("Output folder overlaps a managed input directory.") }
            var ancestor = customOutput
            while ancestor.path != "/" {
                // macOS system temp aliases are trusted; arbitrary user symlinks are not.
                let systemAlias = ["/var": "private/var", "/tmp": "private/tmp"][ancestor.path]
                let trusted = systemAlias != nil && (try? fm.destinationOfSymbolicLink(atPath: ancestor.path)) == systemAlias
                if exists(ancestor) && !trusted { try requireDirectory(ancestor) }
                ancestor.deleteLastPathComponent()
            }
            try requireDirectory(customOutput.deletingLastPathComponent())
        }
        for url in [state, records, outputs, archives] where exists(url) { try requireDirectory(url) }
        try validateBinding()
    }
    private var binding: URL { state.appendingPathComponent("input-folder.json") }
    public func validateBinding() throws {
        guard customOutput != nil else { return }
        if exists(binding) {
            let saved = try JSONDecoder().decode(String.self, from: read(binding))
            guard saved == root.path else { throw OCRFailure("Output folder belongs to another input folder.") }
        } else if exists(state) {
            let entries = try fm.contentsOfDirectory(atPath: state.path).filter { $0 != "lock" && $0 != "records" }
            let hasRecords = try exists(records) && !fm.contentsOfDirectory(atPath: records.path).isEmpty
            guard entries.isEmpty && !hasRecords else { throw OCRFailure("Output folder contains unbound state.") }
        }
    }
    public func bindInput() throws {
        try validateBinding()
        if customOutput != nil && !exists(binding) { try write(JSONEncoder().encode(root.path), to: binding) }
    }
    public func renderReceipt(_ receipt: Receipt, archived: Bool) -> Data {
        guard customOutput != nil else { return render(receipt, archived: archived) }
        let target = (archived ? archives : root).appendingPathComponent(archived ? receipt.archiveName : receipt.originalName)
        let from = outputs.pathComponents, to = target.pathComponents
        var common = 0
        while common < min(from.count, to.count) && from[common] == to[common] { common += 1 }
        let relative = Array(repeating: "..", count: from.count-common) + to.dropFirst(common).map(linkComponent)
        return render(receipt, archived: archived, sourceLink: relative.joined(separator: "/"))
    }
    public func exists(_ url: URL) -> Bool {
        var value = stat()
        return lstat(url.path, &value) == 0
    }
    public func requireDirectory(_ url: URL) throws {
        var value = stat()
        guard lstat(url.path, &value) == 0, (value.st_mode & S_IFMT) == S_IFDIR else {
            throw OCRFailure("Expected a real directory, not a symlink: \(displayName(url.lastPathComponent)).")
        }
    }
    public func read(_ url: URL) throws -> Data {
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK)
        guard fd >= 0 else { throw OCRFailure("Cannot read \(displayName(url.lastPathComponent)): \(String(cString: strerror(errno))).") }
        var info = stat()
        guard fstat(fd, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else {
            close(fd); throw OCRFailure("Not a regular file: \(displayName(url.lastPathComponent)).")
        }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        return try handle.readToEnd() ?? Data()
    }
    private func directory(_ url: URL) throws {
        if !exists(url) {
            do { try fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]) }
            catch { if !exists(url) { throw error } }
        }
        try requireDirectory(url)
    }
    public func prepare() throws {
        if customOutput != nil { try directory(outputs) }
        try directory(state)
        try directory(records)
        try directory(outputs)
    }
    public func prepareArchive() throws { try directory(archives) }
    public func inputs() throws -> [URL] {
        try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    public func loadReceipts() throws -> [Receipt] {
        guard exists(records) else { return [] }
        try requireDirectory(records)
        return try fm.contentsOfDirectory(at: records, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.sorted { $0.path < $1.path }.map {
                let receipt = try JSONDecoder().decode(Receipt.self, from: read($0))
                try receipt.validate(fileID: $0.deletingPathExtension().lastPathComponent)
                return receipt
            }
    }
    public func save(_ receipt: Receipt, new: Bool = false) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try write(encoder.encode(receipt), to: records.appendingPathComponent(receipt.id + ".json"), replace: !new)
    }
    public func write(_ data: Data, to destination: URL, replace: Bool = false) throws {
        try requireDirectory(destination.deletingLastPathComponent())
        // All managed replacement callers validate the previous content under the folder lock.
        if exists(destination) {
            _ = try read(destination) // reject symlinks and nonregular destinations
            if !replace { throw OCRFailure("Refusing to overwrite \(displayName(destination.lastPathComponent)).") }
        }
        let temporary = destination.deletingLastPathComponent().appendingPathComponent(".ocr-tmp-" + UUID().uuidString)
        defer { try? fm.removeItem(at: temporary) }
        guard fm.createFile(atPath: temporary.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
            throw OCRFailure("Cannot create temporary output.")
        }
        let handle = try FileHandle(forWritingTo: temporary)
        do { try handle.write(contentsOf: data); try handle.synchronize(); try handle.close() }
        catch { try? handle.close(); throw error }
        let result = replace ? rename(temporary.path, destination.path) : renamex_np(temporary.path, destination.path, UInt32(RENAME_EXCL))
        guard result == 0 else { throw OCRFailure("Cannot publish \(displayName(destination.lastPathComponent)): \(String(cString: strerror(errno))).") }
    }
    public func move(_ source: URL, to destination: URL) throws {
        try requireDirectory(source.deletingLastPathComponent())
        try requireDirectory(destination.deletingLastPathComponent())
        guard renamex_np(source.path, destination.path, UInt32(RENAME_EXCL)) == 0 else {
            throw OCRFailure("Cannot archive \(displayName(source.lastPathComponent)): \(String(cString: strerror(errno))). Source retained.")
        }
    }
    public func validateIndexOwnership() throws {
        struct IndexState: Decodable { let schema: Int; let acceptedHashes: [String] }
        let target = outputs.appendingPathComponent("index.md")
        let stateFile = state.appendingPathComponent("index.json")
        let record = exists(stateFile) ? try JSONDecoder().decode(IndexState.self, from: read(stateFile)) : nil
        guard record == nil || record?.schema == 1 else { throw OCRFailure("Unsupported index schema.") }
        if exists(target) {
            guard record?.acceptedHashes.contains(digest(try read(target))) == true else {
                throw OCRFailure("index.md is edited or unowned; refusing replacement.")
            }
        }
    }
    public func rebuildIndex(_ receipts: [Receipt]) throws {
        struct IndexState: Codable { let schema: Int; let acceptedHashes: [String] }
        let target = outputs.appendingPathComponent("index.md")
        let stateFile = state.appendingPathComponent("index.json")
        let old = exists(stateFile) ? try JSONDecoder().decode(IndexState.self, from: read(stateFile)) : nil
        guard old == nil || old?.schema == 1 else { throw OCRFailure("Unsupported index schema.") }
        if exists(target) {
            let existing = try read(target)
            guard old?.acceptedHashes.contains(digest(existing)) == true else {
                throw OCRFailure("index.md was edited or is not owned by this tool; preserve it elsewhere before rebuilding.")
            }
        }
        let rows = receipts.sorted { $0.originalName < $1.originalName }.map { receipt in
            "- [\(markdownLabel(receipt.originalName))](\(linkComponent(receipt.outputName))) — \(receipt.stage.rawValue), \(receipt.reviewNeeded ? "needs-review" : "unverified")"
        }
        let data = Data(("# OCR index\n\nGenerated navigation. All text is unverified; keep notes in a separate file.\n\n" + rows.joined(separator: "\n") + "\n").utf8)
        if exists(target), try read(target) == data { return }
        let encoder = JSONEncoder()
        let accepted = Array(Set((old?.acceptedHashes ?? []) + [digest(data)]))
        try write(encoder.encode(IndexState(schema: 1, acceptedHashes: accepted)), to: stateFile, replace: exists(stateFile))
        try write(data, to: target, replace: exists(target))
        try write(encoder.encode(IndexState(schema: 1, acceptedHashes: [digest(data)])), to: stateFile, replace: true)
    }
}
