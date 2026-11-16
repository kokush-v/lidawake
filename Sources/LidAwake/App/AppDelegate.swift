import AppKit
import LidAwakeCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private let model = StatusModel(runner: ProcessCommandRunner())
    private let panelModel = PanelViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Only one menu-bar icon: quit if another instance is already running.
        let bundleID = Bundle.main.bundleIdentifier ?? "com.lidawake.app"
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0 != NSRunningApplication.current }
        if !others.isEmpty {
            NSApp.terminate(nil)
            return
        }

        let controller = StatusItemController()
        statusItemController = controller
        let host = NSHostingController(rootView: PanelView(model: panelModel))
        host.sizingOptions = []  // the popover's height is driven by `onContentHeight`, not by the hosting view
        panelModel.onContentHeight = { [weak controller] height, duration in
            controller?.setContentHeight(height, duration: duration)
        }
        controller.setPanel(host, size: NSSize(width: PanelTheme.width, height: 400), canvasHeight: PanelTheme.canvasHeight)
        host.view.layoutSubtreeIfNeeded()  // measures the content, so the first open already has the right height
        controller.canToggle = { [model] in model.snapshot.canToggle }
        controller.onToggle = { [model] in model.toggle() }
        controller.onOpenPanel = { [weak self] in self?.openPanel() }

        panelModel.onToggle = { [model] in model.toggle() }
        panelModel.onGrant = { [model] in model.grant() }
        panelModel.onRevoke = { [model] in model.revoke() }
        panelModel.onQuit = { [weak self] in self?.quit() }

        model.onChange = { [panelModel] snapshot in
            DispatchQueue.main.async {
                controller.update(icon: snapshot.icon)
                panelModel.apply(snapshot)
            }
        }
        model.refresh()  // show the real state right after launch
        model.startPolling(interval: 5)
    }

    private func openPanel() {
        panelModel.snapshot = model.snapshot
        panelModel.reloadLoginState()
        panelModel.resetExpansion()
        statusItemController?.togglePanel()
        model.refresh()  // never show a stale state when the panel opens
    }

    /// Quitting never changes the mode; if it is still on, ask first.
    private func quit() {
        if model.snapshot.icon == .awake {
            statusItemController?.closePanel()
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Sleep mode is still disabled. Quit anyway?"
            alert.informativeText = "Your Mac will keep staying awake with the lid closed until you switch it back."
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        NSApp.terminate(nil)
    }
}
