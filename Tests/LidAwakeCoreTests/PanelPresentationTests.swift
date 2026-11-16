import Testing
@testable import LidAwakeCore

@Suite struct PanelPresentationTests {
    @Test func awake() {
        let p = PanelPresentation(icon: .awake)
        #expect(p.title == "Awake")
        #expect(p.subtitle == "Your Mac won't sleep with the lid closed")
        #expect(p.accent == .awake)
        #expect(p.showsWarning)
        #expect(p.heroTogglable)
    }

    @Test func sleep() {
        let p = PanelPresentation(icon: .sleep)
        #expect(p.title == "Sleep")
        #expect(p.subtitle == "Your Mac sleeps normally when the lid is closed")
        #expect(p.accent == .sleep)
        #expect(!p.showsWarning)
        #expect(p.heroTogglable)
    }

    @Test func blocked() {
        let p = PanelPresentation(icon: .blocked)
        #expect(p.title == "Access needed")
        #expect(p.subtitle == "LidAwake needs a one-time permission to switch sleep mode without asking for your password.")
        #expect(p.accent == .neutral)
        #expect(!p.showsWarning)
        #expect(!p.heroTogglable)
    }

    @Test func error() {
        let p = PanelPresentation(icon: .error)
        #expect(p.title == "Cannot read sleep state")
        #expect(p.subtitle == "Check the message below.")
        #expect(p.accent == .error)
        #expect(!p.showsWarning)
        #expect(!p.heroTogglable)
    }

    @Test func heroTogglableMatchesSnapshotCanToggle() {
        let granted = AccessState.granted(rule: "r")
        let cases: [(AccessState, SleepState)] = [
            (.missing, .awake), (.missing, .sleep), (.missing, .unknown),
            (granted, .awake), (granted, .sleep), (granted, .unknown),
        ]
        for (access, sleep) in cases {
            var snapshot = StatusSnapshot()
            snapshot.access = access
            snapshot.sleep = sleep
            #expect(PanelPresentation(icon: snapshot.icon).heroTogglable == snapshot.canToggle)
        }
    }
}
