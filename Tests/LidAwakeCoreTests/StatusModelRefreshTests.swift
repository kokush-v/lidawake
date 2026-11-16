import Foundation
import Testing
@testable import LidAwakeCore

@Suite struct StatusModelRefreshTests {
    typealias S = StatusModelTests

    func runner(sleep: [CommandResult], granted: Bool = true) -> FakeCommandRunner {
        let r = FakeCommandRunner()
        r.responses[S.list] = granted ? S.listingGranted : S.listingDenied
        r.sequences[S.pmsetG] = sleep
        return r
    }

    @Test func externalChangeIsPickedUpOnRefresh() {
        let r = runner(sleep: [S.pmset(0), S.pmset(1)])
        let model = StatusModel(runner: r)
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .sleep)
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .awake)
    }

    @Test func removedAccessBecomesBlocked() {
        let r = runner(sleep: [S.pmset(0)])
        let model = StatusModel(runner: r)
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .sleep)

        r.responses[S.list] = S.listingDenied
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .blocked)
        #expect(model.snapshot.canToggle == false)
    }

    @Test func unreadableStateShowsErrorIconAndMessageNotAGuess() {
        let r = runner(sleep: [CommandResult(exitCode: 1)])
        let model = StatusModel(runner: r)
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .error)
        #expect(model.snapshot.errorMessage == "Cannot read sleep state.")
        #expect(model.snapshot.canToggle == false)
    }

    @Test func pollingRefreshesAndNeverChangesSettings() {
        let r = runner(sleep: [S.pmset(0)])
        let model = StatusModel(runner: r)
        model.startPolling(interval: 0.05)
        Thread.sleep(forTimeInterval: 0.4)
        model.stopPolling()
        model.waitUntilIdle()
        let reads = r.calls.filter { $0 == S.pmsetG }.count
        #expect(reads >= 2)
        #expect(!r.calls.contains { $0.contains("sudo -n /usr/bin/pmset") })
    }
}
