import XCTest
@testable import UpdateSupport
final class InstallationGateTests: XCTestCase {
    func testWaitsAndResumesOnlyOnce() async {
        await MainActor.run {
            let gate = InstallationGate(); var installs = 0
            XCTAssertTrue(gate.request(busy: true) { installs += 1 })
            gate.workChanged(busy: true)
            XCTAssertEqual(installs, 0)
            XCTAssertTrue(gate.pending)
            gate.workChanged(busy: false); gate.workChanged(busy: false)
            XCTAssertEqual(installs, 1)
        }
    }
    func testAbortDiscardsDeferredInstallation() async {
        await MainActor.run {
            let gate = InstallationGate(); var installs = 0
            _ = gate.request(busy: true) { installs += 1 }
            gate.abort(); gate.workChanged(busy: false)
            XCTAssertEqual(installs, 0); XCTAssertFalse(gate.pending)
        }
    }
    func testIdleInstallationIsNotPostponed() async {
        await MainActor.run {
            let gate = InstallationGate()
            XCTAssertFalse(gate.request(busy: false) { XCTFail("Sparkle continues directly") })
            XCTAssertTrue(gate.pending)
        }
    }
}
