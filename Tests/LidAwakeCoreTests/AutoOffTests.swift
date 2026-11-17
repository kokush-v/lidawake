import Foundation
import Testing
@testable import LidAwakeCore

@Suite struct AutoOffTests {
    @Test func labelsAndDurations() {
        let expected: [(AutoOff, String, TimeInterval?)] = [
            (.min15, "15 min", 900), (.min30, "30 min", 1800), (.hour1, "1 h", 3600),
            (.hour2, "2 h", 7200), (.hour4, "4 h", 14400), (.hour8, "8 h", 28800), (.off, "Off", nil),
        ]
        #expect(AutoOff.allCases == expected.map(\.0))
        for (value, label, duration) in expected {
            #expect(value.label == label)
            #expect(value.duration == duration)
        }
    }

    @Test func remainingLabelFormats() {
        #expect(AutoOff.remainingLabel(6120) == "1 h 42 min")
        #expect(AutoOff.remainingLabel(7200) == "2 h")
        #expect(AutoOff.remainingLabel(2520) == "42 min")
        #expect(AutoOff.remainingLabel(2461) == "42 min")  // rounds up to whole minutes
    }

    @Test func remainingLabelClampsSmallAndNegative() {
        #expect(AutoOff.remainingLabel(30) == "1 min")
        #expect(AutoOff.remainingLabel(-5) == "1 min")
    }

    @Test func userDefaultsStoreRoundTrips() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = UserDefaultsAutoOffStore(defaults: defaults)
        #expect(store.selection == .off)
        #expect(store.deadline == nil)

        let deadline = Date(timeIntervalSince1970: 5_000)
        store.selection = .hour2
        store.deadline = deadline
        let reloaded = UserDefaultsAutoOffStore(defaults: defaults)
        #expect(reloaded.selection == .hour2)
        #expect(reloaded.deadline == deadline)

        reloaded.deadline = nil
        #expect(UserDefaultsAutoOffStore(defaults: defaults).deadline == nil)
    }

    @Test func unknownStoredMinutesMeanOff() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(7, forKey: "autoOffMinutes")
        #expect(UserDefaultsAutoOffStore(defaults: defaults).selection == .off)
    }
}
