import AppKit
import LidAwakeCore
import SwiftUI

final class PanelViewModel: ObservableObject {
    @Published var snapshot = StatusSnapshot()
    @Published var launchAtLogin = LoginItem.isEnabled
    @Published var loginError: String?

    let userName = NSUserName()
    var onGrant: () -> Void = {}
    var onRevoke: () -> Void = {}
    var onQuit: () -> Void = {}

    func reloadLoginState() {
        launchAtLogin = LoginItem.isEnabled
        loginError = nil
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        loginError = LoginItem.set(enabled: enabled)
        launchAtLogin = LoginItem.isEnabled
    }
}

struct PanelView: View {
    @ObservedObject var model: PanelViewModel

    private var stateText: String {
        switch model.snapshot.icon {
        case .blocked: return "Access not granted"
        case .awake: return "Awake — your Mac will not sleep when the lid is closed"
        case .sleep: return "Sleep — your Mac sleeps normally when the lid is closed"
        case .error: return "Cannot read sleep state"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let image = IconAssets.image(for: model.snapshot.icon) {
                    Image(nsImage: image).renderingMode(.template).foregroundColor(.primary)
                } else {
                    Text(model.snapshot.icon.title).font(.title2)
                }
                Text(stateText).font(.headline).fixedSize(horizontal: false, vertical: true)
            }

            if model.snapshot.icon == .awake {
                Text("Switch back to sleep before putting your Mac in a bag — it may overheat and drain the battery.")
                    .font(.callout)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
            accessSection

            if let message = model.snapshot.errorMessage {
                Text(message).font(.callout).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
            Toggle("Launch at login", isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))
            if let loginError = model.loginError {
                Text(loginError).font(.callout).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("Quit") { model.onQuit() }
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    @ViewBuilder private var accessSection: some View {
        if case .granted(let rule) = model.snapshot.access {
            Text("Access granted. This rule is in effect:").font(.subheadline)
            ruleBox(rule)
            Button("Revoke access") { model.onRevoke() }
        } else {
            Text("LidAwake needs a one-time permission to switch your Mac's sleep mode without asking for a password. It adds exactly this rule and nothing else:")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            ruleBox(AccessChecker.ruleLine(user: model.userName))
            Button("Grant access") { model.onGrant() }
        }
    }

    private func ruleBox(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.12))
            .cornerRadius(6)
            .fixedSize(horizontal: false, vertical: true)
    }
}
