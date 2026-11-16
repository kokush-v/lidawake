import Testing
@testable import LidAwakeCore

@Suite struct AccessStateTests {
    private let c0 = "/usr/bin/sudo -n -l /usr/bin/pmset -a disablesleep 0"
    private let c1 = "/usr/bin/sudo -n -l /usr/bin/pmset -a disablesleep 1"
    private let ok = CommandResult(exitCode: 0)
    private let denied = CommandResult(exitCode: 1, stderr: "a password is required")

    @Test func bothAllowedIsGrantedWithRuleText() {
        let runner = FakeCommandRunner()
        runner.responses[c0] = ok
        runner.responses[c1] = ok
        runner.responses["/usr/bin/sudo -n -l"] = CommandResult(
            exitCode: 0,
            stdout: "User x may run the following commands:\n    (root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1\n    (ALL) ALL\n")
        let state = AccessChecker.check(using: runner)
        #expect(state == .granted(rule: "(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"))
    }

    @Test func oneAllowedIsMissing() {
        let runner = FakeCommandRunner()
        runner.responses[c0] = ok
        runner.responses[c1] = denied
        #expect(AccessChecker.check(using: runner) == .missing)
    }

    @Test func neitherAllowedIsMissing() {
        let runner = FakeCommandRunner()
        runner.responses[c0] = denied
        runner.responses[c1] = denied
        #expect(AccessChecker.check(using: runner) == .missing)
    }

    @Test func fallsBackToFixedRuleWhenListingFails() {
        let runner = FakeCommandRunner()
        runner.responses[c0] = ok
        runner.responses[c1] = ok
        runner.responses["/usr/bin/sudo -n -l"] = denied
        #expect(AccessChecker.check(using: runner) == .granted(rule: AccessChecker.fallbackRule))
    }
}
