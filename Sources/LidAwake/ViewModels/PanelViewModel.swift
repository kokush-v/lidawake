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
    /// The content's new height and the duration of the animation that caused it (0 = none).
    var onContentHeight: (CGFloat, TimeInterval) -> Void = { _, _ in }

    func reloadLoginState() {
        launchAtLogin = LoginItem.isEnabled
        loginError = nil
    }

    func resetExpansion() {
        accessExpanded = false
        commandShown = false
    }

    /// When the last animated expand/collapse started, so the popover can resize in step with it.
    private var layoutAnimationStart: Date?

    /// Applies a state read from the system. A change of the panel's layout (warning card, access
    /// rows) is animated together with the popover's height.
    func apply(_ new: StatusSnapshot) {
        guard new != snapshot else { return }
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let animation: Animation? = reduceMotion ? nil : .easeInOut(duration: PanelTheme.motionDuration)
        layoutAnimationStart = animation == nil ? nil : Date()
        withAnimation(animation) { snapshot = new }
    }

    /// Flips an expansion flag, animating the layout unless `animation` is nil (Reduce Motion).
    func toggle(_ flag: ReferenceWritableKeyPath<PanelViewModel, Bool>, animation: Animation?) {
        layoutAnimationStart = animation == nil ? nil : Date()
        withAnimation(animation) { self[keyPath: flag].toggle() }
    }

    /// Reports the content's height; the change is animated only right after `toggle`.
    func contentHeightChanged(_ height: CGFloat) {
        defer { layoutAnimationStart = nil }
        let animated = layoutAnimationStart.map { Date().timeIntervalSince($0) < 0.1 } ?? false
        onContentHeight(height, animated ? PanelTheme.motionDuration : 0)
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
