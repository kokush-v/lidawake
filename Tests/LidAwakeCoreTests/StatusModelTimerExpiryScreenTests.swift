import Foundation
import Testing
@testable import LidAwakeCore

@Suite struct StatusModelTimerExpiryScreenTests {
    typealias T = StatusModelTests

    static let displayOff = "/usr/bin/pmset displaysleepnow"

    final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    final class FakeUserIdleSource: UserIdleSource {
        var seconds: TimeInterval
        init(_ seconds: TimeInterval) { self.seconds = seconds }
        func secondsSinceLastInput() -> TimeInterval { seconds }
    }

    /// `pmset -g` output with a `displaysleep` line (the shared `T.pmset(_:)` has none).
    static func pmsetWithDisplaySleep(awake: Int, minutes: Int?) -> CommandResult {
        let line = minutes.map { " displaysleep \($0)\n" } ?? ""
        return CommandResult(
            exitCode: 0,
            stdout: "System-wide power settings:\n SleepDisabled\t\t\(awake)\nCurrently in use:\n standby 1\n\(line)")
    }

    func runner(_ sleep: [CommandResult]) -> FakeCommandRunner {
        let r = FakeCommandRunner()
        r.responses[T.list] = T.listingGranted
        r.sequences[T.pmsetG] = sleep
        r.responses[T.on] = CommandResult(exitCode: 0)
        r.responses[T.off] = CommandResult(exitCode: 0)
        r.responses[Self.displayOff] = CommandResult(exitCode: 0)
        return r
    }

    /// A model whose Awake timer ended a minute ago.
    func expiredModel(
        _ runner: FakeCommandRunner, idle: FakeUserIdleSource, fake: FakeSleepAssertions = FakeSleepAssertions()
    ) -> StatusModel {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(-60))
        return StatusModel(
            runner: runner, autoOffStore: store, assertions: fake, idle: idle, now: { clock.now })
    }

    func refresh(_ m: StatusModel) { m.refresh(); m.waitUntilIdle() }

    func displayOffCalls(_ r: FakeCommandRunner) -> Int {
        r.calls.filter { $0 == Self.displayOff }.count
    }

    @Test func timerExpiryWithLongIdleTurnsDisplayOff() {
        let fake = FakeSleepAssertions()
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 10),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 10),
        ])
        let m = expiredModel(r, idle: FakeUserIdleSource(700), fake: fake)
        refresh(m)
        #expect(displayOffCalls(r) == 1)
        let off = r.calls.firstIndex(of: T.off), screen = r.calls.firstIndex(of: Self.displayOff)
        #expect(off != nil && screen != nil && off! < screen!)
        #expect(!fake.isHeld)
    }

    @Test func timerExpiryWithFreshActivityDoesNothing() {
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 10),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 10),
        ])
        refresh(expiredModel(r, idle: FakeUserIdleSource(5)))
        #expect(displayOffCalls(r) == 0)
        #expect(r.calls.contains(T.off))
    }

    @Test func idleExactlyAtTheTimeoutTurnsDisplayOff() {
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 10),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 10),
        ])
        refresh(expiredModel(r, idle: FakeUserIdleSource(600)))
        #expect(displayOffCalls(r) == 1)
    }

    @Test func timerExpiryWhenTimeoutIsNeverDoesNothing() {
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 0),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 0),
        ])
        refresh(expiredModel(r, idle: FakeUserIdleSource(9999)))
        #expect(displayOffCalls(r) == 0)
    }

    @Test func timerExpiryWhenTimeoutUnreadableDoesNothing() {
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: nil),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: nil),
        ])
        refresh(expiredModel(r, idle: FakeUserIdleSource(9999)))
        #expect(displayOffCalls(r) == 0)
    }

    @Test func failedDisplayOffIsSilent() {
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 10),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 10),
        ])
        r.responses[Self.displayOff] = CommandResult(exitCode: 1, stderr: "pmset: failed")
        let m = expiredModel(r, idle: FakeUserIdleSource(700))
        refresh(m)
        #expect(displayOffCalls(r) == 1)
        #expect(m.snapshot.errorMessage == nil)
    }

    @Test func failedAutoOffDoesNotTurnDisplayOff() {
        let r = runner([Self.pmsetWithDisplaySleep(awake: 1, minutes: 10)])
        r.responses[T.off] = CommandResult(exitCode: 1, stderr: "sudo: a password is required")
        let m = expiredModel(r, idle: FakeUserIdleSource(700))
        refresh(m)
        #expect(m.snapshot.sleep == .awake)
        #expect(displayOffCalls(r) == 0)
    }

    @Test func manualAndExternalSwitchOffNeverTurnDisplayOff() {
        let idle = FakeUserIdleSource(9999)
        let manual = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 10),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 10),
        ])
        let m1 = StatusModel(runner: manual, assertions: FakeSleepAssertions(), idle: idle)
        refresh(m1)
        m1.toggle(); m1.waitUntilIdle()
        #expect(manual.calls.contains(T.off))
        #expect(displayOffCalls(manual) == 0)

        let external = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 10),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 10),
        ])
        let m2 = StatusModel(runner: external, assertions: FakeSleepAssertions(), idle: idle)
        refresh(m2); refresh(m2)
        #expect(displayOffCalls(external) == 0)
    }

    // MARK: - The user was idle for only part of the display-off time

    /// Long enough for a one-shot timer set for about a second to fire.
    func waitForPendingDisplayOff(_ m: StatusModel) {
        Thread.sleep(forTimeInterval: 1.3)
        m.waitUntilIdle()
    }

    @Test func partlyIdleUserGetsTheDisplayOffWhenTheRestOfTheTimeoutPasses() {
        let idle = FakeUserIdleSource(59)
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 1),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 1),
        ])
        let m = expiredModel(r, idle: idle)
        refresh(m)
        #expect(displayOffCalls(r) == 0)
        idle.seconds = 60                       // the user stays away
        waitForPendingDisplayOff(m)
        #expect(displayOffCalls(r) == 1)
        let off = r.calls.firstIndex(of: T.off), screen = r.calls.firstIndex(of: Self.displayOff)
        #expect(off != nil && screen != nil && off! < screen!)
    }

    @Test func touchingTheMacBeforeThePendingDisplayOffCancelsIt() {
        let idle = FakeUserIdleSource(59)
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 1),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 1),
        ])
        let m = expiredModel(r, idle: idle)
        refresh(m)
        idle.seconds = 2                        // the user touched the Mac again
        waitForPendingDisplayOff(m)
        #expect(displayOffCalls(r) == 0)
    }

    @Test func awakeSwitchedBackOnCancelsThePendingDisplayOff() {
        let idle = FakeUserIdleSource(59)
        let r = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 1),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 1),
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 1),
        ])
        let m = expiredModel(r, idle: idle)
        refresh(m)
        refresh(m)                              // the state now reads Awake again
        idle.seconds = 60
        waitForPendingDisplayOff(m)
        #expect(displayOffCalls(r) == 0)
    }

    @Test func manualAndExternalSwitchOffNeverScheduleADisplayOff() {
        let idle = FakeUserIdleSource(59)
        let manual = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 1),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 1),
        ])
        let m1 = StatusModel(runner: manual, assertions: FakeSleepAssertions(), idle: idle)
        refresh(m1)
        m1.toggle(); m1.waitUntilIdle()

        let external = runner([
            Self.pmsetWithDisplaySleep(awake: 1, minutes: 1),
            Self.pmsetWithDisplaySleep(awake: 0, minutes: 1),
        ])
        let m2 = StatusModel(runner: external, assertions: FakeSleepAssertions(), idle: idle)
        refresh(m2); refresh(m2)

        idle.seconds = 60
        waitForPendingDisplayOff(m1)
        waitForPendingDisplayOff(m2)
        #expect(displayOffCalls(manual) == 0)
        #expect(displayOffCalls(external) == 0)
    }

    @Test func pollWithoutAnExpiredTimerNeverTurnsDisplayOff() {
        let r = runner([Self.pmsetWithDisplaySleep(awake: 1, minutes: 10)])
        let m = StatusModel(runner: r, assertions: FakeSleepAssertions(), idle: FakeUserIdleSource(9999))
        for _ in 0..<3 { refresh(m) }
        #expect(displayOffCalls(r) == 0)
    }
}
