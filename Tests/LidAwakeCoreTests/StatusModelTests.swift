import Testing
@testable import LidAwakeCore

@Suite struct StatusModelTests {
    static let sudo = "/usr/bin/sudo"
    static let list = "/usr/bin/sudo -n -l"
    static let listingGranted = CommandResult(exitCode: 0, stdout: "    (root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1\n")
    static let listingDenied = CommandResult(exitCode: 0, stdout: "    (ALL) ALL\n")
    static let pmsetG = "/usr/bin/pmset -g"
    static let on = "/usr/bin/sudo -n /usr/bin/pmset -a disablesleep 1"
    static let off = "/usr/bin/sudo -n /usr/bin/pmset -a disablesleep 0"

    static func pmset(_ v: Int) -> CommandResult {
        CommandResult(exitCode: 0, stdout: "System-wide power settings:\n SleepDisabled\t\t\(v)\nCurrently in use:\n standby 1\n")
    }

    /// A runner with access granted.
    func grantedRunner(sleep sequence: [CommandResult]) -> FakeCommandRunner {
        let r = FakeCommandRunner()
        r.responses[Self.list] = Self.listingGranted
        r.sequences[Self.pmsetG] = sequence
        return r
    }

    @Test func toggleOnRunsSudoThenRereadsRealState() {
        let runner = grantedRunner(sleep: [Self.pmset(0), Self.pmset(1)])
        runner.responses[Self.on] = CommandResult(exitCode: 0)
        let model = StatusModel(runner: runner)
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .sleep)

        model.toggle(); model.waitUntilIdle()
        #expect(runner.calls.contains(Self.on))
        #expect(model.snapshot.icon == .awake)
        #expect(model.snapshot.errorMessage == nil)
    }

    @Test func toggleOffRunsDisablesleepZero() {
        let runner = grantedRunner(sleep: [Self.pmset(1), Self.pmset(0)])
        runner.responses[Self.off] = CommandResult(exitCode: 0)
        let model = StatusModel(runner: runner)
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .awake)

        model.toggle(); model.waitUntilIdle()
        #expect(runner.calls.contains(Self.off))
        #expect(model.snapshot.icon == .sleep)
    }

    @Test func failedCommandShowsErrorAndRealState() {
        let runner = grantedRunner(sleep: [Self.pmset(0)])
        runner.responses[Self.on] = CommandResult(exitCode: 1, stderr: "sudo: a password is required")
        let model = StatusModel(runner: runner)
        model.refresh(); model.waitUntilIdle()

        model.toggle(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .sleep)
        #expect(model.snapshot.errorMessage != nil)
    }

    @Test func stateNotChangedAfterToggleIsReportedAsFailure() {
        // sudo succeeds but pmset still reports 0: the UI must show the real state, not the request.
        let runner = grantedRunner(sleep: [Self.pmset(0)])
        runner.responses[Self.on] = CommandResult(exitCode: 0)
        let model = StatusModel(runner: runner)
        model.refresh(); model.waitUntilIdle()

        model.toggle(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .sleep)
        #expect(model.snapshot.errorMessage != nil)
    }

    @Test func toggleDoesNothingWithoutAccess() {
        let runner = FakeCommandRunner()
        runner.responses[Self.pmsetG] = Self.pmset(0)
        let model = StatusModel(runner: runner)
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .blocked)
        #expect(model.snapshot.canToggle == false)

        model.toggle(); model.waitUntilIdle()
        #expect(!runner.calls.contains(Self.on))
        #expect(!runner.calls.contains(Self.off))
    }
}

final class FakePrivileged: PrivilegeActions {
    var grantResult = PrivilegeResult.success
    var revokeResult = PrivilegeResult.success
    private(set) var grantedUsers: [String] = []
    private(set) var revokes = 0
    var onGrant: () -> Void = {}
    func grant(user: String) -> PrivilegeResult { grantedUsers.append(user); onGrant(); return grantResult }
    func revoke() -> PrivilegeResult { revokes += 1; return revokeResult }
}

@Suite struct StatusModelAccessTests {
    typealias S = StatusModelTests

    @Test func grantPassesUserAndRechecksAccess() {
        let runner = FakeCommandRunner()
        runner.responses[S.list] = S.listingDenied
        runner.responses[S.pmsetG] = S.pmset(0)
        let priv = FakePrivileged()
        priv.onGrant = { runner.responses[S.list] = S.listingGranted }
        let model = StatusModel(runner: runner, privileged: priv, userName: "alice")
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .blocked)

        model.grant(); model.waitUntilIdle()
        #expect(priv.grantedUsers == ["alice"])
        #expect(model.snapshot.icon == .sleep)
        #expect(model.snapshot.errorMessage == nil)
    }

    @Test func cancelledGrantChangesNothingAndSaysSo() {
        let runner = FakeCommandRunner()
        runner.fallback = CommandResult(exitCode: 1)
        let priv = FakePrivileged()
        priv.grantResult = .cancelled
        let model = StatusModel(runner: runner, privileged: priv, userName: "alice")
        model.grant(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .blocked)
        #expect(model.snapshot.errorMessage == "Access was not granted.")
    }

    @Test func revokeReturnsToBlocked() {
        let runner = FakeCommandRunner()
        runner.responses[S.list] = S.listingGranted
        runner.responses[S.pmsetG] = S.pmset(0)
        let priv = FakePrivileged()
        priv.onGrant = {}
        let model = StatusModel(runner: runner, privileged: priv, userName: "alice")
        model.refresh(); model.waitUntilIdle()
        #expect(model.snapshot.icon == .sleep)

        runner.responses[S.list] = S.listingDenied
        model.revoke(); model.waitUntilIdle()
        #expect(priv.revokes == 1)
        #expect(model.snapshot.icon == .blocked)
    }

    @Test func failedGrantShowsError() {
        let runner = FakeCommandRunner()
        runner.fallback = CommandResult(exitCode: 1)
        let priv = FakePrivileged()
        priv.grantResult = .validationFailed
        let model = StatusModel(runner: runner, privileged: priv, userName: "alice")
        model.grant(); model.waitUntilIdle()
        #expect(model.snapshot.errorMessage == "Could not grant access.")
    }
}
