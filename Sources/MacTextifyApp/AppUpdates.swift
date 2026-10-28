import Combine
import UpdateSupport
import Sparkle
import SwiftUI

/// Owns Sparkle for the lifetime of the app; OCR inputs never enter update requests.
@MainActor final class AppUpdates: NSObject, ObservableObject, SPUUpdaterDelegate {
    @Published var canCheck = false
    @Published var automaticChecks = false {
        didSet {
            guard let controller, controller.updater.automaticallyChecksForUpdates != automaticChecks else { return }
            controller.updater.automaticallyChecksForUpdates = automaticChecks
        }
    }
    private var controller: SPUStandardUpdaterController!
    private weak var session: Session?
    private var activity: AnyCancellable?
    private let installation = InstallationGate()

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil)
        controller.updater.automaticallyDownloadsUpdates = false
        controller.updater.sendsSystemProfile = false
        automaticChecks = controller.updater.automaticallyChecksForUpdates
        controller.updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheck)
        controller.startUpdater()
    }

    func attach(_ session: Session) {
        guard self.session !== session else { return }
        self.session = session
        activity = session.$busy.combineLatest(session.$scanning)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                guard let self, let session = self.session else { return }
                // Read current state, not a previously queued Combine event.
                self.installation.workChanged(busy: session.busy || session.scanning)
            }
    }

    func check() { controller.checkForUpdates(nil) }

    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
                 untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        guard let session else { return false }
        session.updatePending = true
        let postpone = installation.request(busy: session.busy || session.scanning, install: installHandler)
        guard postpone else { return false }
        session.message = "Update ready. Installation will begin when the current work finishes."
        return true
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        installation.abort()
        session?.updatePending = false
    }
}
