import AppKit
import LidAwakeCore

/// Owns the menu-bar status item and routes clicks.
final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    private let popover = NSPopover()

    var onToggle: () -> Void = {}
    var onOpenPanel: () -> Void = {}
    /// True when a left click may toggle (access granted and state readable).
    var canToggle: () -> Bool = { false }

    override init() {
        super.init()
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        update(icon: .blocked)
    }

    func setPanel(_ content: NSViewController) {
        popover.contentViewController = content
        popover.behavior = .transient  // closes when the user clicks elsewhere
    }

    /// Shows the panel anchored to the icon, or closes it if it is already open.
    func togglePanel() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func closePanel() {
        popover.performClose(nil)
    }

    func update(icon: IconState) {
        guard let button = statusItem.button else { return }
        button.title = icon.title
        button.toolTip = icon.tooltip
        button.setAccessibilityLabel(icon.tooltip)
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let action = ClickAction.route(
            isRightClick: event?.type == .rightMouseUp,
            controlHeld: event?.modifierFlags.contains(.control) ?? false,
            canToggle: canToggle()
        )
        switch action {
        case .toggle: onToggle()
        case .openPanel: onOpenPanel()
        }
    }
}
