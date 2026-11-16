import Foundation

/// Whether the narrow sudo rule (exactly the two `pmset -a disablesleep` commands) is in effect.
public enum AccessState: Equatable {
    case granted(rule: String)
    case missing
}
