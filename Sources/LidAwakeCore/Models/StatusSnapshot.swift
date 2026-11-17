import Foundation

/// A consistent view of the model state, safe to read from any thread.
public struct StatusSnapshot: Equatable {
    public var access: AccessState = .missing
    public var sleep: SleepState = .unknown
    /// The chosen auto-off duration and, while Awake is counting down, when it ends.
    public var autoOff: AutoOff = .off
    public var autoOffDeadline: Date?
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
