import Testing
@testable import LidAwakeCore

@Suite struct SleepStateTests {
    @Test func parsesAwakeWithTabs() {
        let out = "System-wide power settings:\n SleepDisabled\t\t1\nCurrently in use:\n standby 1\n"
        #expect(SleepState.parse(pmsetOutput: out) == .awake)
    }

    @Test func parsesSleepWithSpaces() {
        let out = "System-wide power settings:\n SleepDisabled   0\nCurrently in use:\n standby 1\n"
        #expect(SleepState.parse(pmsetOutput: out) == .sleep)
    }

    @Test func missingFieldInValidOutputMeansDefaultSleep() {
        let out = "Currently in use:\n standby 1\n sleep 1\n"
        #expect(SleepState.parse(pmsetOutput: out) == .sleep)
    }

    @Test func garbageIsUnknown() {
        #expect(SleepState.parse(pmsetOutput: "") == .unknown)
        #expect(SleepState.parse(pmsetOutput: "nonsense") == .unknown)
        #expect(SleepState.parse(pmsetOutput: " SleepDisabled\t\tmaybe\n") == .unknown)
    }

    @Test func nonZeroExitIsUnknown() {
        let runner = FakeCommandRunner()
        runner.responses["/usr/bin/pmset -g"] = CommandResult(exitCode: 1, stdout: " SleepDisabled 1\n")
        #expect(SleepState.read(using: runner) == .unknown)
    }

    @Test func readUsesPmsetG() {
        let runner = FakeCommandRunner()
        runner.responses["/usr/bin/pmset -g"] = CommandResult(exitCode: 0, stdout: " SleepDisabled\t1\n")
        #expect(SleepState.read(using: runner) == .awake)
        #expect(runner.calls == ["/usr/bin/pmset -g"])
    }
}
