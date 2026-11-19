import Foundation

/// The app's request to the system not to sleep, dim the display or lock because of inactivity.
/// Held only while the system reports Awake; see `StatusModel`.
public protocol SleepAssertions: AnyObject {
    /// Creates the assertions. Returns false if they could not be created (then none is kept).
    func hold() -> Bool
    /// Releases everything held. Safe to call when nothing is held.
    func release()
    var isHeld: Bool { get }
}

/// Takes nothing from the system; the default so tests and callers that do not opt in never hold a real assertion.
public final class NoSleepAssertions: SleepAssertions {
    public init() {}
    public func hold() -> Bool { true }
    public func release() {}
    public var isHeld: Bool { false }
}
