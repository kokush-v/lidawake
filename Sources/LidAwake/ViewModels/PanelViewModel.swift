import AppKit
import LidAwakeCore
import SwiftUI

final class PanelViewModel: ObservableObject {
    @Published var snapshot = StatusSnapshot() {
        didSet {
            // A different layout (granted <-> missing) always starts collapsed.
            if oldValue.access.isGranted != snapshot.access.isGranted { resetExpansion() }
        }
    }
    @Published var launchAtLogin = LoginItem.isEnabled
    @Published var loginError: String?
    @Published var accessExpanded = false
    @Published var commandShown = false

    let userName = NSUserName()
    var onToggle: () -> Void = {}
    var onGrant: () -> Void = {}
    var onRevoke: () -> Void = {}
    var onQuit: () -> Void = {}

    func reloadLoginState() {
        launchAtLogin = LoginItem.isEnabled
        loginError = nil
    }

    func resetExpansion() {
        accessExpanded = false
        commandShown = false
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        loginError = LoginItem.set(enabled: enabled)
        launchAtLogin = LoginItem.isEnabled
    }
}

private extension AccessState {
    var isGranted: Bool {
        if case .granted = self { return true }
        return false
    }
}
