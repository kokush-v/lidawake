import Foundation

public enum IconState: Equatable {
    case blocked  // access not granted
    case awake    // Mac will not sleep
    case sleep    // normal behavior
    case error    // access granted but the sleep state cannot be read

    public static func derive(access: AccessState, sleep: SleepState) -> IconState {
        guard case .granted = access else { return .blocked }
        switch sleep {
        case .awake: return .awake
        case .sleep: return .sleep
        case .unknown: return .error
        }
    }

    public var title: String {
        switch self {
        case .blocked: return "🔒"
        case .awake: return "☕️"
        case .sleep: return "💤"
        case .error: return "⚠️"
        }
    }

    public var tooltip: String {
        switch self {
        case .blocked: return "LidAwake — access not granted"
        case .awake: return "LidAwake — Mac stays awake with the lid closed"
        case .sleep: return "LidAwake — Mac sleeps normally when the lid is closed"
        case .error: return "LidAwake — cannot read sleep state"
        }
    }
}

public enum ClickAction: Equatable {
    case toggle
    case openPanel

    /// Left click toggles only when that is possible; Ctrl+click and right click always open the panel.
    public static func route(isRightClick: Bool, controlHeld: Bool, canToggle: Bool) -> ClickAction {
        if isRightClick || controlHeld { return .openPanel }
        return canToggle ? .toggle : .openPanel
    }
}
