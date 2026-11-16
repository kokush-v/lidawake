import Testing
@testable import LidAwakeCore

@Suite struct AccessStateTests {
    static let ruleLine = "    (root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
    static let other = "    (root) NOPASSWD: /usr/local/bin/smc -k CH0B -r\n"
    static let adminAll = "    (ALL) ALL\n"

    func runner(listing: String, exit: Int32 = 0) -> FakeCommandRunner {
        let r = FakeCommandRunner()
        r.responses["/usr/bin/sudo -n -l"] = CommandResult(exitCode: exit, stdout: listing)
        return r
    }

    @Test func bothCommandsNoPasswdIsGrantedWithRuleText() {
        let listing = "User x may run the following commands:\n" + Self.other + Self.ruleLine + "\n" + Self.adminAll
        #expect(AccessChecker.check(using: runner(listing: listing))
            == .granted(rule: "(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"))
    }

    @Test func otherNopasswdEntriesAndAdminAllAreNotAccess() {
        // The false positive that `sudo -l <command>` would give: the user may run it, but with a password.
        let listing = "User x may run the following commands:\n" + Self.other + Self.adminAll
        #expect(AccessChecker.check(using: runner(listing: listing)) == .missing)
    }

    @Test func onlyOneOfTheTwoCommandsIsMissing() {
        let listing = "    (root) NOPASSWD: /usr/bin/pmset -a disablesleep 1\n"
        #expect(AccessChecker.check(using: runner(listing: listing)) == .missing)
    }

    @Test func commandsThatNeedAPasswordAreMissing() {
        let listing = "    (root) /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1\n"
        #expect(AccessChecker.check(using: runner(listing: listing)) == .missing)
    }

    @Test func nopasswdAllCountsAsAccess() {
        let listing = "    (ALL) NOPASSWD: ALL\n"
        #expect(AccessChecker.check(using: runner(listing: listing)) == .granted(rule: "(ALL) NOPASSWD: ALL"))
    }

    @Test func failedListingIsMissing() {
        #expect(AccessChecker.check(using: runner(listing: "", exit: 1)) == .missing)
    }
}
