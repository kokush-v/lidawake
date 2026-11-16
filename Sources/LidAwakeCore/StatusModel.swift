import Foundation

/// A consistent view of the model state, safe to read from any thread.
public struct StatusSnapshot: Equatable {
    public var access: AccessState = .missing
    public var sleep: SleepState = .unknown
    /// Result of the last user action that failed (toggle, grant, revoke).
    public var actionError: String?

    public init() {}

    public var icon: IconState { IconState.derive(access: access, sleep: sleep) }

    /// A plain left click may toggle only when access is granted and the state is readable.
    public var canToggle: Bool { icon == .awake || icon == .sleep }

    /// The message shown in the panel: a failed action first, otherwise an unreadable state.
    public var errorMessage: String? {
        if let actionError { return actionError }
        if icon == .error { return "Cannot read sleep state." }
        return nil
    }
}

/// Reads the real system state and performs user-initiated actions.
/// All work runs on one serial queue; `onChange` is called on that queue.
public final class StatusModel {
    private let runner: CommandRunner
    private let privileged: PrivilegeActions
    private let userName: String
    private let queue = DispatchQueue(label: "lidawake.status-model")
    private let lock = NSLock()
    private var _snapshot = StatusSnapshot()

    public var onChange: ((StatusSnapshot) -> Void)?

    public init(
        runner: CommandRunner,
        privileged: PrivilegeActions? = nil,
        userName: String = NSUserName()
    ) {
        self.runner = runner
        self.privileged = privileged ?? PrivilegeInstaller(runner: runner)
        self.userName = userName
    }

    public var snapshot: StatusSnapshot {
        lock.lock(); defer { lock.unlock() }
        return _snapshot
    }

    /// Blocks until queued work has finished (used by tests).
    public func waitUntilIdle() { queue.sync {} }

    /// Re-reads access and sleep state. Never changes any system setting.
    public func refresh() {
        queue.async { self.readState() }
    }

    private var timer: DispatchSourceTimer?

    /// Reads the real state periodically so changes made outside the app show up.
    /// The timer only reads; it never changes any setting.
    public func startPolling(interval: TimeInterval = 5) {
        queue.async {
            self.timer?.cancel()
            let t = DispatchSource.makeTimerSource(queue: self.queue)
            t.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(100))
            t.setEventHandler { [weak self] in self?.readState() }
            t.resume()
            self.timer = t
        }
    }

    public func stopPolling() {
        queue.async {
            self.timer?.cancel()
            self.timer = nil
        }
    }

    /// Switches the mode to the opposite of the real current state, then re-reads the real state.
    public func toggle() {
        queue.async {
            let before = self.snapshot
            guard before.canToggle else { return }
            let target = before.sleep == .awake ? "0" : "1"
            self.update { $0.actionError = nil }

            let result = self.runner.run(
                AccessChecker.sudoPath,
                ["-n", SleepState.pmsetPath, "-a", "disablesleep", target]
            )
            self.readState()

            let expected: SleepState = target == "1" ? .awake : .sleep
            if !result.succeeded {
                self.update { $0.actionError = "Could not change the sleep setting." }
            } else if self.snapshot.sleep != expected {
                self.update { $0.actionError = "The change did not take effect." }
            }
        }
    }

    /// Installs the sudoers rule through the administrator prompt (explicit user action only).
    public func grant() {
        queue.async {
            self.update { $0.actionError = nil }
            let result = self.privileged.grant(user: self.userName)
            self.readState()
            self.report(result, failure: "Could not grant access.", cancelled: "Access was not granted.")
        }
    }

    /// Removes the sudoers rule through the administrator prompt (explicit user action only).
    public func revoke() {
        queue.async {
            self.update { $0.actionError = nil }
            let result = self.privileged.revoke()
            self.readState()
            self.report(result, failure: "Could not revoke access.", cancelled: "Access was not revoked.")
        }
    }

    private func report(_ result: PrivilegeResult, failure: String, cancelled: String) {
        switch result {
        case .success: break
        case .cancelled: update { $0.actionError = cancelled }
        default: update { $0.actionError = failure }
        }
    }

    // MARK: - Internals (call only on `queue`)

    func readState() {
        let access = AccessChecker.check(using: runner)
        let sleep = SleepState.read(using: runner)
        update { $0.access = access; $0.sleep = sleep }
    }

    func update(_ change: (inout StatusSnapshot) -> Void) {
        lock.lock()
        change(&_snapshot)
        let snap = _snapshot
        lock.unlock()
        onChange?(snap)
    }
}
