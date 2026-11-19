import CoreGraphics
import Foundation

/// How long the user has gone without touching the keyboard, mouse or trackpad.
public protocol UserIdleSource {
    func secondsSinceLastInput() -> TimeInterval
}

/// Reports no idle time, so nothing that depends on idleness ever fires.
public struct NoUserIdleSource: UserIdleSource {
    public init() {}
    public func secondsSinceLastInput() -> TimeInterval { 0 }
}

/// Idle time of the current login session, over all input event types.
public struct SessionUserIdleSource: UserIdleSource {
    public init() {}

    public func secondsSinceLastInput() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }
}
