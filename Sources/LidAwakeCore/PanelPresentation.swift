import Foundation

/// Accent colour family of a panel state; the app target maps it to system colours.
public enum PanelAccent: Equatable {
    case awake, sleep, neutral, error
}

/// What the panel's hero area shows for a state.
public struct PanelPresentation: Equatable {
    public let title: String
    public let subtitle: String
    public let accent: PanelAccent
    /// The pre-packing reminder card is shown only while the Mac is kept awake.
    public let showsWarning: Bool
    /// The hero icon switches the mode only when a plain left click on the menu-bar icon would.
    public let heroTogglable: Bool

    public init(icon: IconState) {
        switch icon {
        case .awake:
            title = "Awake"
            subtitle = "Your Mac won't sleep with the lid closed"
            accent = .awake
            showsWarning = true
            heroTogglable = true
        case .sleep:
            title = "Sleep"
            subtitle = "Your Mac sleeps normally when the lid is closed"
            accent = .sleep
            showsWarning = false
            heroTogglable = true
        case .blocked:
            title = "Access needed"
            subtitle = "LidAwake needs a one-time permission to switch sleep mode without asking for your password."
            accent = .neutral
            showsWarning = false
            heroTogglable = false
        case .error:
            title = "Cannot read sleep state"
            subtitle = "Check the message below."
            accent = .error
            showsWarning = false
            heroTogglable = false
        }
    }
}
