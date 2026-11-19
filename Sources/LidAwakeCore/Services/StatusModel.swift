import Foundation

/// Reads the real system state and performs user-initiated actions.
/// All work runs on one serial queue; `onChange` is called on that queue.
public final class StatusModel {
    private let runner: CommandRunner
    private let privileged: PrivilegeActions
    private let userName: String
    private let autoOffStore: AutoOffStore
    private let assertions: SleepAssertions
    private let idle: UserIdleSource
    private let now: () -> Date
    private let queue = DispatchQueue(label: "lidawake.status-model")
    private let lock = NSLock()
    private var _snapshot = StatusSnapshot()

    public var onChange: ((StatusSnapshot) -> Void)?

    public init(
        runner: CommandRunner,
        privileged: PrivilegeActions? = nil,
        userName: String = NSUserName(),
        autoOffStore: AutoOffStore = MemoryAutoOffStore(),
        assertions: SleepAssertions = NoSleepAssertions(),
        idle: UserIdleSource = NoUserIdleSource(),
        now: @escaping () -> Date = Date.init
    ) {
        self.runner = runner
        self.privileged = privileged ?? PrivilegeInstaller(runner: runner)
        self.userName = userName
        self.autoOffStore = autoOffStore
        self.assertions = assertions
        self.idle = idle
        self.now = now
        _snapshot.autoOff = autoOffStore.selection
        _snapshot.autoOffDeadline = autoOffStore.deadline
    }

    public var snapshot: StatusSnapshot {
        lock.lock(); defer { lock.unlock() }
        return _snapshot
    }

    /// Blocks until queued work has finished (used by tests).
    public func waitUntilIdle() { queue.sync {} }

    /// Re-reads access and sleep state. Never changes the mode or a system setting; it only keeps the app's own
    /// keep-awake request in step with the state it read.
    public func refresh() {
        queue.async { self.readState() }
    }

    private var timer: DispatchSourceTimer?

    /// Reads the real state periodically so changes made outside the app show up.
    /// The timer never changes the mode or a system setting; it only keeps the app's own keep-awake request in step.
    public func startPolling(interval: TimeInterval = 5) {
        queue.async { [weak self] in
            guard let self else { return }
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

            let result = self.setSleepDisabled(target == "1")
            self.readState()

            let expected: SleepState = target == "1" ? .awake : .sleep
            if !result.succeeded {
                self.update { $0.actionError = "Could not change the sleep setting." }
            } else if self.snapshot.sleep != expected {
                self.update { $0.actionError = "The change did not take effect." }
            }
        }
    }

    /// Chooses how long Awake may last. While Awake is on, the countdown restarts from now.
    public func setAutoOff(_ value: AutoOff) {
        queue.async {
            self.autoOffStore.selection = value
            if self.snapshot.sleep == .awake {
                self.autoOffStore.deadline = value.duration.map { self.now().addingTimeInterval($0) }
            }
            self.publishAutoOff()
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
        enforceAutoOff()
        syncAssertions()
    }

    static let holdFailedMessage = "Could not keep the screen awake."

    /// Holds the keep-awake request exactly while the system reports Awake (never what was last requested).
    private func syncAssertions() {
        if snapshot.sleep == .awake {
            cancelPendingDisplayOff()
            guard !assertions.isHeld else { return }
            if assertions.hold() {
                clearHoldError()
            } else if snapshot.actionError != Self.holdFailedMessage {
                update { $0.actionError = Self.holdFailedMessage }
            }
        } else {
            if assertions.isHeld { assertions.release() }
            clearHoldError()
        }
    }

    /// Clears only this feature's own message, never an unrelated error.
    private func clearHoldError() {
        if snapshot.actionError == Self.holdFailedMessage { update { $0.actionError = nil } }
    }

    private func setSleepDisabled(_ on: Bool) -> CommandResult {
        runner.run(AccessChecker.sudoPath, ["-n", SleepState.pmsetPath, "-a", "disablesleep", on ? "1" : "0"])
    }

    /// Starts, keeps or ends the countdown to match the real sleep state.
    private func enforceAutoOff() {
        switch snapshot.sleep {
        case .sleep:
            autoOffStore.deadline = nil
        case .awake:
            if autoOffStore.deadline == nil { startCountdown() }
            if let deadline = autoOffStore.deadline, deadline <= now() { switchOffAtDeadline() }
        case .unknown:
            break
        }
        publishAutoOff()
    }

    private func startCountdown() {
        autoOffStore.deadline = autoOffStore.selection.duration.map { now().addingTimeInterval($0) }
    }

    private func switchOffAtDeadline() {
        let result = setSleepDisabled(false)
        let reading = runner.run(SleepState.pmsetPath, ["-g"])
        let sleep = reading.succeeded ? SleepState.parse(pmsetOutput: reading.stdout) : .unknown
        update { $0.sleep = sleep }
        syncAssertions()
        if result.succeeded && sleep == .sleep { turnDisplayOffIfIdle(pmsetOutput: reading.stdout) }
        if sleep == .awake {
            // Still awake (the command failed): report it and count again rather than retrying every poll.
            startCountdown()
            update { $0.actionError = "Could not switch Awake off automatically." }
        } else {
            autoOffStore.deadline = nil
            if !result.succeeded { update { $0.actionError = "Could not switch Awake off automatically." } }
        }
    }

    private var displayOffTimer: DispatchSourceTimer?

    /// Slack for the idle clock when the display-off timer fires.
    private static let idleTolerance: TimeInterval = 0.5

    /// After the timer ended Awake, macOS restarts the full display-off countdown. Turn the display off when it would
    /// have gone off anyway: now if the user has already been idle that long, otherwise once the rest has passed
    /// (unless they touch the Mac first). Best effort: a failure is ignored.
    private func turnDisplayOffIfIdle(pmsetOutput: String) {
        guard let timeout = DisplaySleepTimeout.parse(pmsetOutput: pmsetOutput), timeout > 0 else { return }
        let idleFor = idle.secondsSinceLastInput()
        if idleFor >= timeout {
            _ = runner.run(SleepState.pmsetPath, ["displaysleepnow"])
            return
        }
        cancelPendingDisplayOff()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + (timeout - idleFor), leeway: .milliseconds(100))
        t.setEventHandler { [weak self] in
            guard let self else { return }
            self.cancelPendingDisplayOff()
            guard self.snapshot.sleep != .awake,
                  self.idle.secondsSinceLastInput() >= timeout - Self.idleTolerance else { return }
            _ = self.runner.run(SleepState.pmsetPath, ["displaysleepnow"])
        }
        t.resume()
        displayOffTimer = t
    }

    private func cancelPendingDisplayOff() {
        displayOffTimer?.cancel()
        displayOffTimer = nil
    }

    /// Mirrors the store into the snapshot and arms a one-shot timer for the deadline.
    private func publishAutoOff() {
        let selection = autoOffStore.selection, deadline = autoOffStore.deadline
        update { $0.autoOff = selection; $0.autoOffDeadline = deadline }
        expiryTimer?.cancel()
        expiryTimer = nil
        guard let deadline else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + max(0, deadline.timeIntervalSince(now())), leeway: .milliseconds(100))
        t.setEventHandler { [weak self] in self?.readState() }
        t.resume()
        expiryTimer = t
    }

    private var expiryTimer: DispatchSourceTimer?

    func update(_ change: (inout StatusSnapshot) -> Void) {
        lock.lock()
        change(&_snapshot)
        let snap = _snapshot
        lock.unlock()
        onChange?(snap)
    }
}
