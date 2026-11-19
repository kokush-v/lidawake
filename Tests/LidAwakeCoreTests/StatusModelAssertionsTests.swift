import Foundation
import Testing
@testable import LidAwakeCore

@Suite struct StatusModelAssertionsTests {
    typealias T = StatusModelTests

    static let holdFailed = "Could not keep the screen awake."

    final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    static let unreadable = CommandResult(exitCode: 1, stderr: "pmset failed")

    /// A runner with access granted whose toggle commands succeed.
    func runner(_ sleep: [CommandResult], list: CommandResult = T.listingGranted) -> FakeCommandRunner {
        let r = FakeCommandRunner()
        r.responses[T.list] = list
        r.sequences[T.pmsetG] = sleep
        r.responses[T.on] = CommandResult(exitCode: 0)
        r.responses[T.off] = CommandResult(exitCode: 0)
        return r
    }

    func model(
        _ runner: FakeCommandRunner,
        _ fake: FakeSleepAssertions,
        store: AutoOffStore = MemoryAutoOffStore(),
        clock: Clock = Clock()
    ) -> StatusModel {
        StatusModel(runner: runner, autoOffStore: store, assertions: fake, now: { clock.now })
    }

    func refresh(_ m: StatusModel) { m.refresh(); m.waitUntilIdle() }

    @Test func holdsWhenStateIsAwake() {
        let fake = FakeSleepAssertions()
        let m = model(runner([T.pmset(1)]), fake)
        refresh(m)
        #expect(fake.isHeld)
        #expect(fake.holdCount == 1)
    }

    @Test func holdsWhenAwakeSwitchedOnFromToggle() {
        let fake = FakeSleepAssertions()
        let m = model(runner([T.pmset(0), T.pmset(1)]), fake)
        refresh(m)
        #expect(!fake.isHeld)
        m.toggle(); m.waitUntilIdle()
        #expect(fake.isHeld)
        #expect(fake.holdCount == 1)
    }

    @Test func doesNotHoldTwiceAcrossPolls() {
        let fake = FakeSleepAssertions()
        let m = model(runner([T.pmset(1)]), fake)
        refresh(m); refresh(m); refresh(m)
        #expect(fake.holdCount == 1)
        #expect(fake.releaseCount == 0)
    }

    @Test func releasesWhenStateIsSleep() {
        let fake = FakeSleepAssertions()
        let m = model(runner([T.pmset(1), T.pmset(0)]), fake)
        refresh(m)
        refresh(m)
        #expect(!fake.isHeld)
        #expect(fake.releaseCount == 1)
    }

    @Test func neverHoldsWhileStateIsUnknown() {
        let fake = FakeSleepAssertions()
        let m = model(runner([Self.unreadable]), fake)
        refresh(m)
        #expect(fake.holdCount == 0)
    }

    @Test func releasesWhenStateBecomesUnknown() {
        let fake = FakeSleepAssertions()
        let m = model(runner([T.pmset(1), Self.unreadable]), fake)
        refresh(m)
        refresh(m)
        #expect(!fake.isHeld)
        #expect(fake.releaseCount == 1)
    }

    @Test func failedHoldShowsErrorAndKeepsAwake() {
        let fake = FakeSleepAssertions()
        fake.failNextHold = true
        let r = runner([T.pmset(1)])
        let m = model(r, fake)
        refresh(m)
        #expect(m.snapshot.errorMessage == Self.holdFailed)
        #expect(m.snapshot.sleep == .awake)
        #expect(!r.calls.contains(T.off))
    }

    @Test func failedHoldIsRetriedAndClearsItsOwnError() {
        let fake = FakeSleepAssertions()
        fake.failNextHold = true
        let m = model(runner([T.pmset(1)]), fake)
        refresh(m)
        #expect(m.snapshot.errorMessage == Self.holdFailed)
        refresh(m)
        #expect(fake.isHeld)
        #expect(m.snapshot.errorMessage == nil)
    }

    @Test func holdErrorClearsWhenAwakeEnds() {
        let fake = FakeSleepAssertions()
        fake.failNextHold = true
        let m = model(runner([T.pmset(1), T.pmset(0)]), fake)
        refresh(m)
        #expect(m.snapshot.errorMessage == Self.holdFailed)
        refresh(m)
        #expect(m.snapshot.errorMessage == nil)
    }

    @Test func successfulRetryKeepsAnUnrelatedError() {
        let fake = FakeSleepAssertions()
        let r = runner([T.pmset(1)])
        r.responses[T.off] = CommandResult(exitCode: 1, stderr: "sudo: a password is required")
        let m = model(r, fake)
        fake.failNextHold = true
        refresh(m)
        fake.failNextHold = true
        m.toggle(); m.waitUntilIdle()   // the off command fails, the hold fails again, the toggle error wins
        #expect(m.snapshot.errorMessage == "Could not change the sleep setting.")
        refresh(m)                      // the hold now succeeds
        #expect(fake.isHeld)
        #expect(m.snapshot.errorMessage == "Could not change the sleep setting.")
    }

    @Test func timerExpiryReleasesHeldAssertions() {
        let clock = Clock()
        let fake = FakeSleepAssertions()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(60))
        let r = runner([T.pmset(1), T.pmset(1), T.pmset(0)])
        let m = model(r, fake, store: store, clock: clock)
        refresh(m)
        #expect(fake.holdCount == 1)

        clock.now = clock.now.addingTimeInterval(61)
        refresh(m)
        #expect(r.calls.contains(T.off))
        #expect(!fake.isHeld)
        #expect(fake.releaseCount == 1)
    }

    @Test func expiredDeadlineOnFirstReadNeverHolds() {
        let clock = Clock()
        let fake = FakeSleepAssertions()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(-10))
        let r = runner([T.pmset(1), T.pmset(0)])
        let m = model(r, fake, store: store, clock: clock)
        refresh(m)
        #expect(r.calls.contains(T.off))
        #expect(fake.holdCount == 0)
        #expect(fake.releaseCount == 0)
    }

    @Test func failedAutoOffSwitchOffKeepsTheHold() {
        let clock = Clock()
        let fake = FakeSleepAssertions()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(-10))
        let r = runner([T.pmset(1)])
        r.responses[T.off] = CommandResult(exitCode: 1, stderr: "sudo: a password is required")
        let m = model(r, fake, store: store, clock: clock)
        refresh(m)
        #expect(fake.isHeld)
        #expect(m.snapshot.errorMessage == "Could not switch Awake off automatically.")
    }

    @Test func neverSwitchesAwakeOn() {
        let fake = FakeSleepAssertions()
        fake.failNextHold = true
        let r = runner([T.pmset(0), T.pmset(1), Self.unreadable, T.pmset(1)])
        let m = model(r, fake)
        for _ in 0..<5 { refresh(m) }
        #expect(!r.calls.contains(T.on))
    }

    /// Every command the model ran, minus the reads and the two known toggle commands.
    func screenCommands(_ r: FakeCommandRunner) -> [String] {
        r.calls.filter { $0 != T.pmsetG && $0 != T.list && $0 != T.on && $0 != T.off }
    }

    @Test func manualToggleOffReleasesWithoutScreenAction() {
        let fake = FakeSleepAssertions()
        let r = runner([T.pmset(1), T.pmset(0)])
        let m = model(r, fake)
        refresh(m)
        m.toggle(); m.waitUntilIdle()
        #expect(!fake.isHeld)
        #expect(fake.releaseCount == 1)
        #expect(r.calls.contains(T.off))
        #expect(screenCommands(r).isEmpty)
    }

    @Test func externalSwitchOffReleasesWithoutScreenAction() {
        let fake = FakeSleepAssertions()
        let r = runner([T.pmset(1), T.pmset(0)])
        let m = model(r, fake)
        refresh(m)
        refresh(m)
        #expect(!fake.isHeld)
        #expect(screenCommands(r).isEmpty)
    }

    @Test func pollNeverRunsAScreenCommand() {
        let fake = FakeSleepAssertions()
        let r = runner([T.pmset(1), T.pmset(0), T.pmset(1), Self.unreadable, T.pmset(1), T.pmset(0)])
        let m = model(r, fake)
        for _ in 0..<10 { refresh(m) }
        #expect(screenCommands(r).isEmpty)
        #expect(!r.calls.contains(where: { $0.contains("displaysleepnow") }))
    }

    @Test func holdsEvenWithoutAccess() {
        let fake = FakeSleepAssertions()
        let m = model(runner([T.pmset(1)], list: T.listingDenied), fake)
        refresh(m)
        #expect(m.snapshot.access == .missing)
        #expect(fake.isHeld)
    }
}
