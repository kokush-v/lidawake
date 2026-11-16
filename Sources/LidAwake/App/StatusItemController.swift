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

    private var resizeTimer: Timer?

    /// Hosts the panel in a tall fixed-height view pinned to the popover's top edge.
    ///
    /// The SwiftUI root must never change size: SwiftUI animates a size change of the root around its
    /// centre, so with a popover that follows the content the whole panel drops and settles whenever a
    /// row expands. The popover's height is set separately through `setContentHeight`.
    func setPanel(_ content: NSViewController, size: NSSize, canvasHeight: CGFloat) {
        let container = NSViewController()
        container.view = NSView(frame: NSRect(origin: .zero, size: size))
        container.addChild(content)
        content.view.frame = NSRect(x: 0, y: size.height - canvasHeight, width: size.width, height: canvasHeight)
        content.view.autoresizingMask = [.minYMargin]  // keeps the top edge pinned while the popover resizes
        container.view.addSubview(content.view)
        popover.contentViewController = container
        popover.contentSize = size
        popover.behavior = .transient  // closes when the user clicks elsewhere
    }

    /// Resizes the popover to the content's height, over `duration` seconds in step with the content's
    /// own expand/collapse animation (0 = at once).
    func setContentHeight(_ height: CGFloat, duration: TimeInterval) {
        guard height > 0 else { return }
        resizeTimer?.invalidate()
        resizeTimer = nil
        let start = popover.contentSize
        let target = NSSize(width: start.width, height: height)
        guard duration > 0, popover.isShown, start.height != height else { return apply(target) }

        let began = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 1.0 / 120, repeats: true) { [weak self] timer in
            guard let self else { return timer.invalidate() }
            let progress = min((ProcessInfo.processInfo.systemUptime - began) / duration, 1)
            let eased = Self.easeInOut(progress)
            self.apply(NSSize(width: target.width, height: start.height + (height - start.height) * eased))
            if progress >= 1 {
                timer.invalidate()
                self.resizeTimer = nil
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        resizeTimer = timer
    }

    private func apply(_ size: NSSize) {
        popover.animates = false
        popover.contentSize = size
        popover.animates = true
    }

    /// SwiftUI's `.easeInOut` curve (cubic Bézier 0.42, 0, 0.58, 1), so the popover matches the content.
    private static func easeInOut(_ x: Double) -> Double {
        var low = 0.0, high = 1.0, s = x
        for _ in 0..<20 {
            s = (low + high) / 2
            let bx = 3 * (1 - s) * (1 - s) * s * 0.42 + 3 * (1 - s) * s * s * 0.58 + s * s * s
            if bx < x { low = s } else { high = s }
        }
        return 3 * (1 - s) * s * s + s * s * s
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
        if let image = IconAssets.image(for: icon) {
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.image = nil
            button.title = icon.title  // fallback when running outside the app bundle
        }
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
