import Testing
@testable import LidAwakeCore

@Suite struct IconStateTests {
    private let granted = AccessState.granted(rule: "r")

    @Test func missingAccessIsBlockedWhateverTheSleepState() {
        for s in [SleepState.awake, .sleep, .unknown] {
            #expect(IconState.derive(access: .missing, sleep: s) == .blocked)
        }
    }

    @Test func grantedMapsSleepState() {
        #expect(IconState.derive(access: granted, sleep: .awake) == .awake)
        #expect(IconState.derive(access: granted, sleep: .sleep) == .sleep)
        #expect(IconState.derive(access: granted, sleep: .unknown) == .error)
    }

    @Test func titlesAndTooltipsMatchSpec() {
        #expect(IconState.blocked.title == "🔒")
        #expect(IconState.awake.title == "☕️")
        #expect(IconState.sleep.title == "💤")
        #expect(IconState.error.title == "⚠️")
        #expect(IconState.blocked.tooltip == "LidAwake — access not granted")
        #expect(IconState.sleep.tooltip == "LidAwake — Mac sleeps normally when the lid is closed")
        #expect(IconState.awake.tooltip == "LidAwake — Mac stays awake with the lid closed")
        #expect(IconState.error.tooltip == "LidAwake — cannot read sleep state")
    }

    @Test func clickRouting() {
        #expect(ClickAction.route(isRightClick: false, controlHeld: false, canToggle: true) == .toggle)
        #expect(ClickAction.route(isRightClick: false, controlHeld: false, canToggle: false) == .openPanel)
        #expect(ClickAction.route(isRightClick: true, controlHeld: false, canToggle: true) == .openPanel)
        #expect(ClickAction.route(isRightClick: false, controlHeld: true, canToggle: true) == .openPanel)
    }
}
