import Foundation

/// How long Awake mode may stay on before it switches itself off. The raw value is the minutes (0 = never).
public enum AutoOff: Int, CaseIterable, Equatable {
    case min15 = 15
    case min30 = 30
    case hour1 = 60
    case hour2 = 120
    case hour4 = 240
    case hour8 = 480
    case off = 0

    public var duration: TimeInterval? { self == .off ? nil : TimeInterval(rawValue * 60) }

    public var label: String {
        switch self {
        case .off: return "Off"
        default: return Self.format(minutes: rawValue)
        }
    }

    /// The time left, rounded up to whole minutes ("1 h 42 min"); never below "1 min".
    public static func remainingLabel(_ interval: TimeInterval) -> String {
        format(minutes: max(1, Int((interval / 60).rounded(.up))))
    }

    private static func format(minutes: Int) -> String {
        let hours = minutes / 60, rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) min"
        case (_, 0): return "\(hours) h"
        default: return "\(hours) h \(rest) min"
        }
    }
}
