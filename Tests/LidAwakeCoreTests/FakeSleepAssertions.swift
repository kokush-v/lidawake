import LidAwakeCore

/// Counts what `StatusModel` asks for; can be told to fail the next `hold()`.
final class FakeSleepAssertions: SleepAssertions {
    private(set) var holdCount = 0
    private(set) var releaseCount = 0
    private(set) var isHeld = false
    var failNextHold = false

    func hold() -> Bool {
        if failNextHold {
            failNextHold = false
            return false
        }
        holdCount += 1
        isHeld = true
        return true
    }

    func release() {
        guard isHeld else { return }
        releaseCount += 1
        isHeld = false
    }
}
