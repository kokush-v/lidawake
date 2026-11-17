import Foundation

/// Where the chosen duration and the running deadline are kept.
public protocol AutoOffStore: AnyObject {
    var selection: AutoOff { get set }
    var deadline: Date? { get set }
}

/// Survives relaunches, so the deadline still counts after the app restarts.
public final class UserDefaultsAutoOffStore: AutoOffStore {
    private let defaults: UserDefaults
    private static let minutesKey = "autoOffMinutes"
    private static let deadlineKey = "autoOffDeadline"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var selection: AutoOff {
        get { AutoOff(rawValue: defaults.integer(forKey: Self.minutesKey)) ?? .off }
        set { defaults.set(newValue.rawValue, forKey: Self.minutesKey) }
    }

    public var deadline: Date? {
        get { defaults.object(forKey: Self.deadlineKey) as? Date }
        set {
            if let newValue { defaults.set(newValue, forKey: Self.deadlineKey) }
            else { defaults.removeObject(forKey: Self.deadlineKey) }
        }
    }
}

/// In-memory store for tests.
public final class MemoryAutoOffStore: AutoOffStore {
    public var selection: AutoOff
    public var deadline: Date?

    public init(selection: AutoOff = .off, deadline: Date? = nil) {
        self.selection = selection
        self.deadline = deadline
    }
}
