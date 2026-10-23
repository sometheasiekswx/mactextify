import XCTest
@testable import OCRCore

final class FakeRecognizer: Recognizer {
    var calls = 0
    var lines = [TextLine("Research result: sample 42", confidence: 0.95)]
    var failData: Data?
    var beforeReturn: (() throws -> Void)?
    func supportedLanguages(for configuration: Configuration) throws -> [String] { ["en-US", "fr-FR"] }
    func recognize(_ data: Data, configuration: Configuration) throws -> Recognition {
        calls += 1
        if data == failData { throw OCRFailure("Invalid fixture") }
        try beforeReturn?()
        return Recognition(lines: lines, engine: "Synthetic test engine")
    }
}

final class ProcessorTests: XCTestCase {
    var root: URL!
    var fake: FakeRecognizer!
    let fm = FileManager.default
    override func setUpWithError() throws {
        root = fm.temporaryDirectory.appendingPathComponent("ocr-tests-" + UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        fake = FakeRecognizer()
    }
    override func tearDownWithError() throws { try fm.removeItem(at: root) }
    @discardableResult func input(_ name: String = "sample.PNG", _ content: String = "fixture") throws -> URL {
        let path = root.appendingPathComponent(name); try Data(content.utf8).write(to: path); return path
    }
    func processFixture(_ config: Configuration = Configuration(), dryRun: Bool = false,
             checkpoint: @escaping (Checkpoint) throws -> Void = { _ in }) async throws -> RunSummary {
        try await Processor(root: root, recognizer: fake, checkpoint: checkpoint, report: { _ in }).process(configuration: config, dryRun: dryRun)
    }
    func records() throws -> [Receipt] { try Storage(root: root).loadReceipts() }
    func output(_ receipt: Receipt) -> URL { root.appendingPathComponent("Extracted/" + receipt.outputName) }
    func archived(_ receipt: Receipt) -> URL { root.appendingPathComponent("Processed/" + receipt.archiveName) }
    func manifest() throws -> [String: String] {
        var result = [String: String]()
        let enumeration = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey])!
        for case let url as URL in enumeration {
            if try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true {
                result[String(url.path.dropFirst(root.path.count))] = digest(try Data(contentsOf: url))
            }
        }
        return result
    }
    func testKeepDefaultAndIdempotency() async throws {
        let path = try input()
        let actual1 = try await processFixture().exported
        XCTAssertEqual(actual1, 1)
        XCTAssertEqual(try Data(contentsOf: path), Data("fixture".utf8))
        XCTAssertFalse(fm.fileExists(atPath: root.appendingPathComponent("Processed").path))
        let before = try manifest()
        let actual2 = try await processFixture().skipped
        XCTAssertEqual(actual2, 1)
        XCTAssertEqual(fake.calls, 1)
        XCTAssertEqual(try manifest(), before)
        XCTAssertTrue(String(data: try Data(contentsOf: output(records()[0])), encoding: .utf8)!.contains("../sample.PNG"))
    }
    func testArchivePreservesBytesAndFinalLink() async throws {
        let source = try input("space [x] #%.PNG")
        var config = Configuration(); config.archive = true
        let actual3 = try await processFixture(config).failed
        XCTAssertEqual(actual3, 0)
        let receipt = try records()[0]
        XCTAssertFalse(fm.fileExists(atPath: source.path))
        XCTAssertEqual(digest(try Data(contentsOf: archived(receipt))), receipt.id)
        XCTAssertEqual(try Data(contentsOf: output(receipt)), render(receipt, archived: true))
        let before = try manifest()
        let actual4 = try await processFixture(config).failed
        XCTAssertEqual(actual4, 0)
        XCTAssertEqual(fake.calls, 1)
        XCTAssertEqual(try manifest(), before)
    }
    func testTextFormatAndConfidenceWarning() async throws {
        try input(); fake.lines = [TextLine("low confidence", confidence: 0.3)]
        var config = Configuration(); config.format = .text
        let result = try await processFixture(config)
        XCTAssertEqual(result.reviewNeeded, 1)
        XCTAssertEqual(try Data(contentsOf: output(records()[0])), Data("low confidence\n".utf8))
    }
    func testDryRunAndStatusHaveNoSideEffects() async throws {
        try input(); let before = try manifest()
        let actual5 = try await processFixture(dryRun: true).failed
        XCTAssertEqual(actual5, 0)
        try Processor(root: root, recognizer: fake, report: { _ in }).status()
        XCTAssertEqual(fake.calls, 0)
        XCTAssertEqual(try manifest(), before)
        XCTAssertFalse(fm.fileExists(atPath: root.appendingPathComponent(".ocr-state").path))
    }
    func testInvalidConfigurationIsPreflight() async throws {
        try input(); var config = Configuration(); config.languages = ["invalid"]
        await assertAsyncThrows { try await processFixture(config) }
        config.languages = ["en-US"]; config.reviewThreshold = .nan
        await assertAsyncThrows { try await processFixture(config) }
        XCTAssertFalse(fm.fileExists(atPath: root.appendingPathComponent("Extracted").path))
    }
    func testBlankAndCorruptImagesRemainWhileOtherItemsComplete() async throws {
        try input("bad.png", "bad"); try input("good.png", "good")
        fake.failData = Data("bad".utf8)
        let result = try await processFixture()
        XCTAssertEqual(result.exported, 1); XCTAssertEqual(result.failed, 1)
        XCTAssertTrue(fm.fileExists(atPath: root.appendingPathComponent("bad.png").path))
        fake.failData = nil; fake.lines = []
        let actual6 = try await processFixture().failed
        XCTAssertEqual(actual6, 1)
    }
    func testExactDuplicatesDontRepeatOCRorDeleteCopies() async throws {
        try input("a.png"); let duplicate = try input("b.jpg")
        var config = Configuration(); config.archive = true
        let result = try await processFixture(config)
        XCTAssertEqual(result.exported, 1); XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(fake.calls, 1)
        XCTAssertTrue(fm.fileExists(atPath: duplicate.path))
    }
    func testSameNameNewBytesGetSeparateExportAfterArchival() async throws {
        try input(); var config = Configuration(); config.archive = true
        _ = try await processFixture(config); try input("sample.PNG", "different")
        let actual7 = try await processFixture(config).exported
        XCTAssertEqual(actual7, 1)
        XCTAssertEqual(try records().count, 2)
    }
    func testConflictingConfigurationDoesNotOverwrite() async throws {
        try input(); _ = try await processFixture(); let before = try manifest()
        var config = Configuration(); config.format = .text
        let actual8 = try await processFixture(config).failed
        XCTAssertEqual(actual8, 1)
        XCTAssertEqual(fake.calls, 1); XCTAssertEqual(try manifest(), before)
    }
    func testEditedOutputIsProtected() async throws {
        try input(); _ = try await processFixture(); let path = try output(records()[0])
        try Data("User notes".utf8).write(to: path)
        let actual9 = try await processFixture().failed
        XCTAssertGreaterThan(actual9, 0)
        XCTAssertEqual(try Data(contentsOf: path), Data("User notes".utf8))
        XCTAssertEqual(fake.calls, 1)
    }
    func testDeletedOutputIsNotRegenerated() async throws {
        try input(); _ = try await processFixture(); let path = try output(records()[0])
        try fm.removeItem(at: path)
        let actual10 = try await processFixture().failed
        XCTAssertGreaterThan(actual10, 0)
        XCTAssertFalse(fm.fileExists(atPath: path.path)); XCTAssertEqual(fake.calls, 1)
    }
    func testChangedSourceDuringOCRIsNotArchived() async throws {
        let source = try input()
        fake.beforeReturn = { try Data("changed".utf8).write(to: source) }
        var config = Configuration(); config.archive = true
        let actual11 = try await processFixture(config).failed
        XCTAssertEqual(actual11, 1)
        XCTAssertTrue(try records().isEmpty)
        XCTAssertEqual(try Data(contentsOf: source), Data("changed".utf8))
    }
    func testResumeAtEveryCommitBoundaryWithoutRepeatingOCR() async throws {
        for point in Checkpoint.allCases {
            let folder = root.appendingPathComponent(point.rawValue)
            try fm.createDirectory(at: folder, withIntermediateDirectories: false)
            let source = folder.appendingPathComponent("input.png")
            try Data("fixture".utf8).write(to: source)
            let engine = FakeRecognizer()
            var config = Configuration(); config.archive = true
            let interrupted = try await Processor(root: folder, recognizer: engine, checkpoint: {
                if $0 == point { throw OCRFailure("Injected interruption") }
            }, report: { _ in }).process(configuration: config)
            XCTAssertEqual(interrupted.failed, 1, point.rawValue)
            let resumed = try await Processor(root: folder, recognizer: engine, report: { _ in }).process(configuration: config)
            XCTAssertEqual(resumed.failed, 0, point.rawValue)
            XCTAssertEqual(engine.calls, 1, point.rawValue)
            let receipt = try Storage(root: folder).loadReceipts()[0]
            XCTAssertEqual(receipt.stage, .archived)
            XCTAssertEqual(try Data(contentsOf: folder.appendingPathComponent("Processed/" + receipt.archiveName)), Data("fixture".utf8))
            XCTAssertFalse(fm.fileExists(atPath: source.path))
        }
    }
    func testArchiveCollisionRetainsSourceAndSavedText() async throws {
        let source = try input(); var config = Configuration(); config.archive = true
        let result = try await processFixture(config, checkpoint: { point in
            if point == .exported {
                let storage = try Storage(root: self.root); try storage.prepareArchive()
                let receipt = try storage.loadReceipts()[0]
                try Data("foreign bytes".utf8).write(to: self.archived(receipt))
            }
        })
        // A collision created between export and archival must never be adopted.
        XCTAssertEqual(result.failed, 1)
        XCTAssertTrue(fm.fileExists(atPath: source.path))
    }
    func testSymlinkInputAndManagedDirectoryAreRejected() async throws {
        let target = try input("real.txt")
        try fm.createSymbolicLink(at: root.appendingPathComponent("link.png"), withDestinationURL: target)
        let actual12 = try await processFixture().failed
        XCTAssertEqual(actual12, 1); XCTAssertEqual(fake.calls, 0)
        try fm.removeItem(at: root.appendingPathComponent("Extracted"))
        try fm.createSymbolicLink(at: root.appendingPathComponent("Extracted"), withDestinationURL: root)
        XCTAssertThrowsError(try Processor(root: root, recognizer: fake))
    }
    func testSymlinkExportDoesNotWriteThrough() async throws {
        try input(); _ = try await processFixture(); let receipt = try records()[0]
        let target = try input("private.txt", "private")
        try fm.removeItem(at: output(receipt))
        try fm.createSymbolicLink(at: output(receipt), withDestinationURL: target)
        let actual13 = try await processFixture().failed
        XCTAssertGreaterThan(actual13, 0)
        XCTAssertEqual(try Data(contentsOf: target), Data("private".utf8))
    }
    func testUnknownSchemaAndMalformedReceiptFailClosed() async throws {
        try input(); _ = try await processFixture(); let receipt = try records()[0]
        let path = root.appendingPathComponent(".ocr-state/records/" + receipt.id + ".json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: path)) as! [String: Any]
        json["schema"] = 99
        try JSONSerialization.data(withJSONObject: json).write(to: path)
        await assertAsyncThrows { try await processFixture() }
        try Data("broken".utf8).write(to: path)
        await assertAsyncThrows { try await processFixture() }; XCTAssertEqual(fake.calls, 1)
    }
    func testLockPreventsConcurrentRunAndReleases() async throws {
        try input(); let storage = try Storage(root: root); try storage.prepare()
        var lock: FolderLock? = try FolderLock(storage.state.appendingPathComponent("lock"))
        await assertAsyncThrows { try await processFixture() }
        withExtendedLifetime(lock) {}
        lock = nil
        let actual14 = try await processFixture().failed
        XCTAssertEqual(actual14, 0)
    }
    func testEditedIndexProtectedAndMissingIndexRebuilt() async throws {
        try input(); _ = try await processFixture()
        let index = root.appendingPathComponent("Extracted/index.md")
        try fm.removeItem(at: index)
        let actual15 = try await processFixture().failed
        XCTAssertEqual(actual15, 0)
        XCTAssertTrue(fm.fileExists(atPath: index.path))
        try Data("user index".utf8).write(to: index)
        let actual16 = try await processFixture().failed
        XCTAssertEqual(actual16, 1)
        XCTAssertEqual(try Data(contentsOf: index), Data("user index".utf8))
    }
    func testMarkdownCannotBreakOutOfCodeFence() async throws {
        try input("[link](bad)#%.png")
        fake.lines = [TextLine("```\n[click](https://example.invalid)\n````")]
        _ = try await processFixture()
        let data = try Data(contentsOf: output(records()[0]))
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("`````text"))
        XCTAssertTrue(text.contains("%23%25.png"))
        XCTAssertTrue(text.contains("\\[link\\]"))
    }
    func testExportWriteFailureKeepsSourceAndCanResume() async throws {
        let source = try input(); var config = Configuration(); config.archive = true
        var blocked: URL?
        let result = try await processFixture(config, checkpoint: { point in
            if point == .prepared {
                let receipt = try self.records()[0]
                blocked = self.output(receipt)
                try self.fm.createDirectory(at: blocked!, withIntermediateDirectories: false)
            }
        })
        XCTAssertEqual(result.failed, 1)
        XCTAssertEqual(try Data(contentsOf: source), Data("fixture".utf8))
        try fm.removeItem(at: blocked!)
        let actual17 = try await processFixture(config).failed
        XCTAssertEqual(actual17, 0)
        XCTAssertEqual(fake.calls, 1)
    }
    func testUnownedOutputCollisionIsPreserved() async throws {
        try input(); _ = try await processFixture()
        let receipt = try records()[0]
        try fm.removeItem(at: root.appendingPathComponent(".ocr-state/records/" + receipt.id + ".json"))
        let original = try Data(contentsOf: output(receipt))
        let actual18 = try await processFixture().failed
        XCTAssertEqual(actual18, 1)
        XCTAssertEqual(try Data(contentsOf: output(receipt)), original)
        XCTAssertTrue(try records().isEmpty)
    }
    func testPendingRunUsesSavedPolicyAndReportsNewConfigConflict() async throws {
        try input(); var config = Configuration(); config.archive = true
        _ = try await processFixture(config, checkpoint: { if $0 == .prepared { throw OCRFailure("stop") } })
        let actual19 = try await processFixture().failed
        XCTAssertEqual(actual19, 0) // source is archived before new-input scan
        XCTAssertEqual(try records()[0].stage, .archived)
        XCTAssertEqual(fake.calls, 1)
    }
    func testOutputEditedBetweenExportAndMovePreventsArchival() async throws {
        let source = try input(); var config = Configuration(); config.archive = true
        let result = try await processFixture(config, checkpoint: { point in
            if point == .exported { try Data("edited".utf8).write(to: self.output(self.records()[0])) }
        })
        XCTAssertEqual(result.failed, 1)
        XCTAssertTrue(fm.fileExists(atPath: source.path))
    }
    func testSeparateFoldersHaveIndependentLocksAndState() async throws {
        try input(); let storage = try Storage(root: root); try storage.prepare()
        let lock = try FolderLock(storage.state.appendingPathComponent("lock"))
        let other = root.appendingPathComponent("other")
        try fm.createDirectory(at: other, withIntermediateDirectories: false)
        try Data("same".utf8).write(to: other.appendingPathComponent("sample.png"))
        let result = try await Processor(root: other, recognizer: fake, report: { _ in }).process(configuration: Configuration())
        XCTAssertEqual(result.exported, 1)
        XCTAssertTrue(try storage.loadReceipts().isEmpty)
        withExtendedLifetime(lock) {}
    }
    func testTraversalInReceiptIsRejectedBeforeTouchingFiles() async throws {
        try input(); _ = try await processFixture(); let receipt = try records()[0]
        let path = root.appendingPathComponent(".ocr-state/records/" + receipt.id + ".json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: path)) as! [String: Any]
        json["originalName"] = "../outside.png"
        try JSONSerialization.data(withJSONObject: json).write(to: path)
        await assertAsyncThrows { try await processFixture() }
    }

    func testEditAfterArchiveMoveIsNotOverwrittenByLinkRepair() async throws {
        try input(); var config = Configuration(); config.archive = true
        let result = try await processFixture(config, checkpoint: { point in
            if point == .archived { try Data("keep this edit".utf8).write(to: self.output(self.records()[0])) }
        })
        XCTAssertEqual(result.failed, 1)
        let receipt = try records()[0]
        XCTAssertEqual(try Data(contentsOf: output(receipt)), Data("keep this edit".utf8))
        XCTAssertEqual(digest(try Data(contentsOf: archived(receipt))), receipt.id)
    }

    func testDryRunDetectsUnownedOutputWithoutOCRorMutation() async throws {
        try input(); _ = try await processFixture(); let receipt = try records()[0]
        try fm.removeItem(at: root.appendingPathComponent(".ocr-state/records/" + receipt.id + ".json"))
        let before = try manifest(), calls = fake.calls
        let actual20 = try await processFixture(dryRun: true).failed
        XCTAssertEqual(actual20, 1)
        XCTAssertEqual(fake.calls, calls)
        XCTAssertEqual(try manifest(), before)
    }

    func testLiveTextUnknownConfidenceIsNotInvented() async throws {
        try input()
        fake.lines = [TextLine("Research notes", confidence: nil, x: nil, y: nil, width: nil, height: nil)]
        let result = try await processFixture()
        XCTAssertEqual(result.reviewNeeded, 1)
        let receipt = try records()[0]
        XCTAssertEqual(receipt.schema, 3)
        XCTAssertNil(receipt.lines[0].confidence)
        XCTAssertNil(receipt.lines[0].x)
        XCTAssertTrue(String(decoding: try Data(contentsOf: output(receipt)), as: UTF8.self).contains("confidence unavailable"))
        let repeatResult = try await processFixture()
        XCTAssertEqual(repeatResult.failed, 0)
    }
    func testLegacyReceiptKeepsVisionMeaningAndExportBytes() async throws {
        try input()
        var legacyConfig = Configuration(); legacyConfig.engine = nil; legacyConfig.imageScale = nil; legacyConfig.layout = nil
        _ = try await processFixture(legacyConfig)
        let receipt = try records()[0]
        let path = root.appendingPathComponent(".ocr-state/records/" + receipt.id + ".json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: path)) as! [String: Any]
        json["schema"] = 1
        var config = json["configuration"] as! [String: Any]; config.removeValue(forKey: "engine")
        json["configuration"] = config
        try JSONSerialization.data(withJSONObject: json).write(to: path)
        let before = try Data(contentsOf: output(receipt))
        var explicitVision = Configuration(); explicitVision.engine = .vision; explicitVision.layout = .whole
        let result = try await processFixture(explicitVision)
        XCTAssertEqual(result.failed, 0)
        XCTAssertEqual(try records()[0].configuration.selectedEngine, .vision)
        XCTAssertEqual(try Data(contentsOf: output(receipt)), before)
        XCTAssertEqual(fake.calls, 1)
        let conflict = try await processFixture() // new default cannot reuse old OCR
        XCTAssertGreaterThan(conflict.failed, 0)
    }

    func testScaleChangeConflictsAndInvalidScaleFailsBeforeWrites() async throws {
        try input()
        var config = Configuration(); config.imageScale = .infinity
        await assertAsyncThrows { try await processFixture(config) }
        XCTAssertFalse(fm.fileExists(atPath: root.appendingPathComponent("Extracted").path))
        config.imageScale = 1
        _ = try await processFixture(config)
        config.imageScale = 0.5
        let result = try await processFixture(config)
        XCTAssertGreaterThan(result.failed, 0)
        XCTAssertEqual(fake.calls, 1)
    }

}

private func assertAsyncThrows(_ operation: () async throws -> RunSummary, file: StaticString = #filePath, line: UInt = #line) async {
    do { _ = try await operation(); XCTFail("Expected an error", file: file, line: line) }
    catch { }
}
