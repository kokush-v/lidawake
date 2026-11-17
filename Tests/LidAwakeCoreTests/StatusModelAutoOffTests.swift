import Foundation
import Testing
@testable import LidAwakeCore

@Suite struct StatusModelAutoOffTests {
    typealias T = StatusModelTests

    final class Clock {
        var now = Date(timeIntervalSince1970: 1_000)
    }

    /// A granted runner whose off command succeeds.
    func runner(sleep sequence: [CommandResult]) -> FakeCommandRunner {
        let r = FakeCommandRunner()
        r.responses[T.list] = T.listingGranted
        r.sequences[T.pmsetG] = sequence
        r.responses[T.off] = CommandResult(exitCode: 0)
        r.responses[T.on] = CommandResult(exitCode: 0)
        return r
    }

    func model(_ runner: FakeCommandRunner, store: AutoOffStore, clock: Clock) -> StatusModel {
        StatusModel(runner: runner, autoOffStore: store, now: { clock.now })
    }

    @Test func awakeWithSelectionStartsCountdown() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1)
        let m = model(runner(sleep: [T.pmset(0), T.pmset(1)]), store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()
        #expect(m.snapshot.autoOffDeadline == nil)

        m.toggle(); m.waitUntilIdle()
        #expect(m.snapshot.icon == .awake)
        #expect(m.snapshot.autoOffDeadline == clock.now.addingTimeInterval(3600))
        #expect(store.deadline == clock.now.addingTimeInterval(3600))
    }

    @Test func externallyEnabledAwakeStartsCountdown() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1)
        let m = model(runner(sleep: [T.pmset(1)]), store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()
        #expect(m.snapshot.autoOffDeadline == clock.now.addingTimeInterval(3600))
    }

    @Test func offSelectionNeverStartsCountdown() {
        let store = MemoryAutoOffStore(selection: .off)
        let m = model(runner(sleep: [T.pmset(1)]), store: store, clock: Clock())
        m.refresh(); m.waitUntilIdle()
        #expect(m.snapshot.autoOffDeadline == nil)
    }

    @Test func expiredDeadlineSwitchesOffOnRefresh() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(-10))
        let r = runner(sleep: [T.pmset(1), T.pmset(0)])
        let m = model(r, store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()
        #expect(r.calls.contains(T.off))
        #expect(m.snapshot.icon == .sleep)
        #expect(m.snapshot.errorMessage == nil)
        #expect(store.deadline == nil)
    }

    @Test func runningDeadlineDoesNotSwitchOff() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(60))
        let r = runner(sleep: [T.pmset(1)])
        let m = model(r, store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()
        #expect(!r.calls.contains(T.off))
        #expect(m.snapshot.autoOffDeadline == clock.now.addingTimeInterval(60))
    }

    @Test func selectingOffClearsDeadline() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1)
        let r = runner(sleep: [T.pmset(1)])
        let m = model(r, store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()
        #expect(m.snapshot.autoOffDeadline != nil)

        m.setAutoOff(.off); m.waitUntilIdle()
        #expect(m.snapshot.autoOff == .off)
        #expect(m.snapshot.autoOffDeadline == nil)
        #expect(store.deadline == nil)
        #expect(!r.calls.contains(T.off))
    }

    @Test func changingSelectionWhileAwakeRestartsCountdown() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1)
        let m = model(runner(sleep: [T.pmset(1)]), store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()

        clock.now = clock.now.addingTimeInterval(600)
        m.setAutoOff(.min15); m.waitUntilIdle()
        #expect(m.snapshot.autoOff == .min15)
        #expect(m.snapshot.autoOffDeadline == clock.now.addingTimeInterval(900))
        #expect(store.selection == .min15)
    }

    @Test func selectingWhileAsleepOnlyRemembersChoice() {
        let store = MemoryAutoOffStore()
        let m = model(runner(sleep: [T.pmset(0)]), store: store, clock: Clock())
        m.refresh(); m.waitUntilIdle()
        m.setAutoOff(.hour4); m.waitUntilIdle()
        #expect(m.snapshot.autoOff == .hour4)
        #expect(m.snapshot.autoOffDeadline == nil)
        #expect(store.selection == .hour4)
    }

    @Test func sleepStateClearsDeadline() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(500))
        let m = model(runner(sleep: [T.pmset(0)]), store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()
        #expect(m.snapshot.autoOffDeadline == nil)
        #expect(store.deadline == nil)
    }

    @Test func failedExpiryClearsDeadlineAndReportsError() {
        let clock = Clock()
        let store = MemoryAutoOffStore(selection: .hour1, deadline: clock.now.addingTimeInterval(-10))
        let r = runner(sleep: [T.pmset(1)])
        r.responses[T.off] = CommandResult(exitCode: 1, stderr: "sudo: a password is required")
        let m = model(r, store: store, clock: clock)
        m.refresh(); m.waitUntilIdle()
        #expect(m.snapshot.errorMessage != nil)
        #expect(store.deadline == clock.now.addingTimeInterval(3600))  // a fresh countdown, not a retry loop

        let offCalls = r.calls.filter { $0 == T.off }.count
        m.refresh(); m.waitUntilIdle()
        #expect(r.calls.filter { $0 == T.off }.count == offCalls)
    }

    @Test func snapshotStartsWithStoredChoice() {
        let clock = Clock()
        let deadline = clock.now.addingTimeInterval(500)
        let m = model(runner(sleep: [T.pmset(1)]), store: MemoryAutoOffStore(selection: .hour2, deadline: deadline), clock: clock)
        #expect(m.snapshot.autoOff == .hour2)
        #expect(m.snapshot.autoOffDeadline == deadline)
    }
}
