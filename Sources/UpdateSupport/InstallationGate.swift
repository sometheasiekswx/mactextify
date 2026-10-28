/// Serializes a confirmed installation with active work. Call only on the main actor.
@MainActor public final class InstallationGate {
    public private(set) var pending = false
    private var resume: (() -> Void)?
    public init() {}
    public func request(busy: Bool, install: @escaping () -> Void) -> Bool {
        pending = true
        if busy { resume = install }
        return busy
    }
    public func workChanged(busy: Bool) {
        guard !busy, let install = resume else { return }
        resume = nil
        install()
    }
    public func abort() { resume = nil; pending = false }
}
