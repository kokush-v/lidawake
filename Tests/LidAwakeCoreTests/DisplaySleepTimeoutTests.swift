import Testing
@testable import LidAwakeCore

@Suite struct DisplaySleepTimeoutTests {
    func output(_ line: String) -> String {
        "System-wide power settings:\n SleepDisabled\t\t0\nCurrently in use:\n standby 1\n\(line)\n womp 1\n"
    }

    @Test func minutesBecomeSeconds() {
        #expect(DisplaySleepTimeout.parse(pmsetOutput: output(" displaysleep            10")) == 600)
    }

    @Test func zeroMeansNever() {
        #expect(DisplaySleepTimeout.parse(pmsetOutput: output(" displaysleep 0")) == 0)
    }

    @Test func missingLineIsUnreadable() {
        #expect(DisplaySleepTimeout.parse(pmsetOutput: output("")) == nil)
    }

    @Test func nonNumericValueIsUnreadable() {
        #expect(DisplaySleepTimeout.parse(pmsetOutput: output(" displaysleep soon")) == nil)
    }

    @Test func ignoresTheWordInsideAnotherLine() {
        let line = " sleep                1 (sleep prevented by caffeinate, displaysleep 5)"
        #expect(DisplaySleepTimeout.parse(pmsetOutput: output(line)) == nil)
    }

    @Test func readsTheValueEvenWhenTheSystemAnnotatesIt() {
        #expect(DisplaySleepTimeout.parse(pmsetOutput: output(" displaysleep         1 (display sleep prevented by LidAwake)")) == 60)
    }
}
