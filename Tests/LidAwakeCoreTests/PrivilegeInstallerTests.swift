import Foundation
import Testing
@testable import LidAwakeCore

@Suite struct PrivilegeInstallerTests {
    static var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    @Test func embeddedScriptsEqualTheReviewableFiles() throws {
        let dir = Self.repoRoot.appendingPathComponent("Resources/scripts")
        let grant = try String(contentsOf: dir.appendingPathComponent("grant-access.sh"), encoding: .utf8)
        let revoke = try String(contentsOf: dir.appendingPathComponent("revoke-access.sh"), encoding: .utf8)
        #expect(EmbeddedScripts.grantAccess + "\n" == grant || EmbeddedScripts.grantAccess == grant)
        #expect(EmbeddedScripts.revokeAccess + "\n" == revoke || EmbeddedScripts.revokeAccess == revoke)
    }

    @Test func shellQuoteRoundTripsHostileText() {
        let text = "it's \"quoted\" $HOME `date` \\ back\nnew line; rm -rf /"
        let result = ProcessCommandRunner().run("/bin/sh", ["-c", "printf '%s' " + PrivilegeInstaller.shellQuote(text)])
        #expect(result.stdout == text)
    }

    @Test func commandPassesScriptTextNotAFilePath() {
        let fake = FakeCommandRunner()
        fake.responses["/usr/bin/osascript"] = CommandResult(exitCode: 0)
        _ = PrivilegeInstaller(runner: fake).run(scriptText: "echo 'hi'", arguments: ["alice"], prompt: "P")
        let args = PrivilegeInstaller.osascriptArguments(scriptText: "echo 'hi'", arguments: ["alice"], prompt: "P")
        #expect(args[6] == "/bin/sh -c 'echo '\\''hi'\\''' sh 'alice'")
        #expect(args[7] == "P")
        #expect(args.count == 8)
    }

    @Test func dryRunOfEmbeddedGrantScriptMatchesSwiftRuleLine() {
        // Runs the embedded text exactly as the app would, but with --dry-run and no privileges.
        let line = PrivilegeInstaller.commandLine(scriptText: EmbeddedScripts.grantAccess, arguments: ["--dry-run", "alice"])
        let result = ProcessCommandRunner().run("/bin/sh", ["-c", line])
        #expect(result.exitCode == 0)
        #expect(result.stdout.trimmingCharacters(in: .newlines) == AccessChecker.ruleLine(user: "alice"))
    }

    @Test func exitCodesAndCancelMapToDistinctResults() {
        #expect(PrivilegeInstaller.map(stderr: "execution error: User canceled. (-128)") == .cancelled)
        #expect(PrivilegeInstaller.map(stderr: "execution error: invalid user name (2)") == .invalidArgument)
        #expect(PrivilegeInstaller.map(stderr: "execution error: rule failed validation (3)") == .validationFailed)
        if case .installFailed = PrivilegeInstaller.map(stderr: "execution error: boom (4)") {} else {
            Issue.record("exit 4 must map to installFailed")
        }
        if case .installFailed = PrivilegeInstaller.map(stderr: "something odd") {} else {
            Issue.record("unknown text must map to installFailed")
        }
    }

    @Test func successAndFailurePropagate() {
        let fake = FakeCommandRunner()
        fake.fallback = CommandResult(exitCode: 0)
        #expect(PrivilegeInstaller(runner: fake).revoke() == .success)
        fake.fallback = CommandResult(exitCode: 1, stderr: "execution error: User canceled. (-128)")
        #expect(PrivilegeInstaller(runner: fake).grant(user: "alice") == .cancelled)
    }
}
