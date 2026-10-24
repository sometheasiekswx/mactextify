import XCTest
@testable import OCRCore

final class BatchProcessorTests: XCTestCase {
    var root: URL!
    override func setUpWithError() throws { root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false) }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }
    func file(_ path: String, _ content: String) throws -> URL {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(content.utf8).write(to: url); return url
    }
    func testMixedRootsRecoveryAndEditedExportProtection() async throws {
        let a = try file("one/same.png", "one"), b = try file("two/same.png", "two")
        let dest = root.appendingPathComponent("exports"), fake = FakeRecognizer(), processor = BatchProcessor(recognizer: fake)
        var outputs = [URL]()
        try await processor.process(files: [a,b], destination: dest, configuration: Configuration()) { if let u = $0.output { outputs.append(u) } }
        XCTAssertEqual(outputs.count,2); XCTAssertNotEqual(outputs[0], outputs[1])
        XCTAssertTrue(try String(contentsOf: outputs[0]).contains("../one/same.png"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("one/.ocr-state").path))
        try await processor.process(files: [a,b], destination: dest, configuration: Configuration()) { if $0.state != .extracting { XCTAssertEqual($0.state,.skipped) } }
        XCTAssertEqual(fake.calls,2)
        try Data("edited".utf8).write(to: outputs[0])
        do { try await processor.process(files: [a], destination: dest, configuration: Configuration()) { _ in }; XCTFail("Must protect edits") } catch {}
        XCTAssertEqual(try String(contentsOf: outputs[0]),"edited")
    }
    func testInterruptedPublicationAndDuplicateContent() async throws {
        let a = try file("one/a.png", "same"), b = try file("two/b.png", "same")
        let dest = root.appendingPathComponent("exports"), fake = FakeRecognizer(), processor = BatchProcessor(recognizer: fake)
        do { try await processor.process(files: [a], destination: dest, configuration: Configuration(), checkpoint: { if $0 == .outputPublished { throw OCRFailure("interrupt") } }) { _ in }; XCTFail("Expected interruption") } catch {}
        try await processor.process(files: [a,b], destination: dest, configuration: Configuration()) { if $0.state != .extracting { XCTAssertEqual($0.state,.skipped) } }
        XCTAssertEqual(fake.calls,1)
    }
    func testLegacyDestinationRejectedAndNamesValidated() async throws {
        let a = try file("one/a.png", "one"), dest = root.appendingPathComponent("exports")
        _ = try file("exports/.ocr-state/input-folder.json", "\"legacy\"")
        do { try await BatchProcessor(recognizer: FakeRecognizer()).process(files: [a], destination: dest, configuration: Configuration()) { _ in }; XCTFail("Must reject legacy state") } catch {}
        for name in ["", ".", "..", "a/b", "a\\b", ".ocr-state"] { XCTAssertThrowsError(try BatchDestination.resolve(parent: root, folderName: name)) }
        XCTAssertEqual(try BatchDestination.resolve(parent: root, folderName: nil).path,root.path)
    }
    func testSelectionRecursionAndSymlinkExclusion() throws {
        let a = try file("input/a.png","one"), b = try file("input/nested/b.jpg","two")
        _ = try file("input/readme.txt","unsupported")
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("input/link.png"), withDestinationURL: a)
        let top = try BatchSelection.scan([root.appendingPathComponent("input"),a], recursive: false)
        XCTAssertEqual(top.files,[a]); XCTAssertEqual(top.excluded.count,3)
        let all = try BatchSelection.scan([root.appendingPathComponent("input")], recursive: true)
        XCTAssertEqual(Set(all.files),Set([a,b]))
    }
    func testExplicitNestedFolderSelectionIsOrderIndependent() throws {
        let image = try file("input/nested/image.png", "synthetic")
        let parent = root.appendingPathComponent("input")
        let child = parent.appendingPathComponent("nested")
        for selection in [[parent, child], [child, parent], [parent, child, child]] {
            let result = try BatchSelection.scan(selection, recursive: false)
            XCTAssertEqual(result.files, [image])
            XCTAssertFalse(result.excluded.contains { $0 == "nested: subfolder excluded" })
        }
    }
    func testDestinationLockAndSymbolicLinkAreRejected() async throws {
        let a = try file("input/a.png", "one"), destination = root.appendingPathComponent("exports")
        let processor = BatchProcessor(recognizer: FakeRecognizer())
        try await processor.process(files: [a], destination: destination, configuration: Configuration()) { _ in }
        let lock = try FolderLock(destination.appendingPathComponent(".ocr-state/lock"))
        do { try await processor.process(files: [a], destination: destination, configuration: Configuration()) { _ in }; XCTFail("Must respect lock") } catch {}
        withExtendedLifetime(lock) {}
        let link = root.appendingPathComponent("linked")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: destination)
        do { try await processor.process(files: [a], destination: link, configuration: Configuration()) { _ in }; XCTFail("Must reject symlink") } catch {}
    }
    func testUnownedOutputAndChangedSourceArePreserved() async throws {
        let a = try file("input/a.png", "one"), destination = root.appendingPathComponent("exports")
        let hash = digest(Data("one".utf8))
        let collision = try file("exports/a--\(hash).md", "personal notes")
        let processor = BatchProcessor(recognizer: FakeRecognizer())
        var failed = false
        try await processor.process(files: [a], destination: destination, configuration: Configuration()) { if $0.state == .failed { failed = true } }
        XCTAssertTrue(failed); XCTAssertEqual(try String(contentsOf: collision), "personal notes")
        let fake = FakeRecognizer(); fake.beforeReturn = { try Data("changed".utf8).write(to: a) }
        failed = false
        try await BatchProcessor(recognizer: fake).process(files: [a], destination: root.appendingPathComponent("different"), configuration: Configuration()) { if $0.state == .failed { failed = true } }
        XCTAssertTrue(failed)
    }
    func testCancellationFinishesCurrentPublicationAndStopsNextImage() async throws {
        let a = try file("input/a.png", "one"), b = try file("input/b.png", "two")
        let destination = root.appendingPathComponent("exports")
        let task = Task { () -> [BatchItemState] in
            var states = [BatchItemState]()
            do {
                try await BatchProcessor(recognizer: FakeRecognizer()).process(files: [a,b], destination: destination, configuration: Configuration()) { event in
                    states.append(event.state)
                    if event.state == .extracting { withUnsafeCurrentTask { $0?.cancel() } }
                }
            } catch { XCTFail("Unexpected error: \(error)") }
            return states
        }
        let states = await task.value
        XCTAssertTrue(states.contains(.exported)); XCTAssertTrue(states.contains(.cancelled))
        XCTAssertEqual(states.filter { $0 == .extracting }.count, 1)
    }
    func testFrameworkErrorHasActionableRecoveryMessage() async throws {
        struct BrokenEngine: Recognizer {
            struct FrameworkError: Error {}
            func supportedLanguages(for configuration: Configuration) throws -> [String] { ["en-US"] }
            func recognize(_ data: Data, configuration: Configuration) async throws -> Recognition { throw FrameworkError() }
        }
        let a = try file("input/a.png", "one")
        var failure: String?
        try await BatchProcessor(recognizer: BrokenEngine()).process(files: [a], destination: root.appendingPathComponent("exports"), configuration: Configuration()) {
            if $0.state == .failed { failure = $0.detail }
        }
        XCTAssertTrue(failure?.contains("Try Vision OCR") == true)
    }
    func testCancellationBeforeStartCreatesNothing() async throws {
        let a = try file("input/a.png","one"), dest = root.appendingPathComponent("exports")
        let task = Task { try await Task.sleep(nanoseconds: 50_000_000); try await BatchProcessor(recognizer: FakeRecognizer()).process(files: [a], destination: dest, configuration: Configuration()) { _ in } }
        task.cancel(); _ = try? await task.value
        XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path))
    }
}
