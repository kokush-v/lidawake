import Foundation
import IOKit.pwr_mgt

/// Asks the system not to dim the display, show the screen saver, lock or (while the display stays on) sleep
/// because of inactivity. The assertion belongs to this process, so the system drops it if the app quits or crashes.
/// Not thread-safe; `StatusModel` calls it only on its serial queue.
public final class IOKitSleepAssertions: SleepAssertions {
    /// Shown in `pmset -g assertions`, so the source of the request is identifiable.
    static let reason = "LidAwake: Awake mode"

    private static let types = [kIOPMAssertionTypePreventUserIdleDisplaySleep]

    private var ids: [IOPMAssertionID] = []

    public init() {}

    deinit { release() }

    public var isHeld: Bool { !ids.isEmpty }

    public func hold() -> Bool {
        if isHeld { return true }
        var created: [IOPMAssertionID] = []
        for type in Self.types {
            var id = IOPMAssertionID(0)
            let status = IOPMAssertionCreateWithName(
                type as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), Self.reason as CFString, &id)
            guard status == kIOReturnSuccess else {
                created.forEach { IOPMAssertionRelease($0) }
                return false
            }
            created.append(id)
        }
        ids = created
        return true
    }

    public func release() {
        ids.forEach { IOPMAssertionRelease($0) }
        ids = []
    }
}
