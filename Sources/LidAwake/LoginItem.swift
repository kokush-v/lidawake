import ServiceManagement

/// Launch at login, backed by the system's login-item setting (the app stores nothing itself).
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    /// Returns an English error message, or nil on success.
    static func set(enabled: Bool) -> String? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval {
                    return "Approve LidAwake in System Settings › General › Login Items."
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return "Could not change Launch at login: \(error.localizedDescription)"
        }
    }
}
