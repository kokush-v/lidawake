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

/// Fades a block in when it is inserted. Only its own opacity animates, so no sibling (the hero)
/// is moved by the animation while the popover resizes.
private struct FadeInOnAppear: ViewModifier {
    /// An observable flag instead of `@State`: the SwiftUI macros are not available with Command Line Tools only.
    private final class Flag: ObservableObject { @Published var visible = false }

    let animation: Animation?
    @StateObject private var flag = Flag()

    func body(content: Content) -> some View {
        content
            .opacity(flag.visible ? 1 : 0)
            .onAppear { withAnimation(animation) { flag.visible = true } }
    }
}

private extension View {
    func fadeInOnAppear(_ animation: Animation?) -> some View { modifier(FadeInOnAppear(animation: animation)) }
}

/// Small press feedback for the hero: shrinks slightly while pressed and springs back.
private struct HeroPressStyle: ButtonStyle {
    let animated: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(animated ? .spring(response: 0.25, dampingFraction: 0.6) : nil, value: configuration.isPressed)
    }
}

private extension AccessState {
    var isGranted: Bool {
        if case .granted = self { return true }
        return false
    }
}

struct PanelView: View {
    @ObservedObject var model: PanelViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var icon: IconState { model.snapshot.icon }
    private var presentation: PanelPresentation { PanelPresentation(icon: icon) }
    /// Shared by every transition; nil (instant) when Reduce Motion is on.
    private var motion: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.25) }

    var body: some View {
        VStack(spacing: 12) {
            hero
            // Each block animates on its own (fade only). A root-level animation would also animate the
            // hero's position when the popover resizes, making the icon drop and settle.
            if presentation.showsWarning {
                TintedCard(
                    text: "Switch back to sleep before putting your Mac in a bag. It may overheat and drain the battery.",
                    color: PanelTheme.color(for: .awake))
                    .fadeInOnAppear(motion)
            }
            if let message = model.snapshot.errorMessage {
                TintedCard(text: message, color: PanelTheme.color(for: .error))
                    .fadeInOnAppear(motion)
            }
            if case .granted = model.snapshot.access {} else {
                VStack(spacing: 12) { grantBlock }.fadeInOnAppear(motion)
            }
            settingsGroup
            quitGroup
        }
        .padding(16)
        .frame(width: 340)
        // The popover resizes instantly while the content animates; pin the content to the top so the
        // hero does not shift when a card appears or disappears.
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: Hero

    private var hero: some View {
        let color = PanelTheme.color(for: presentation.accent)
        return VStack(spacing: 8) {
            Button { model.onToggle() } label: {
                ZStack {
                    Circle().fill(color).frame(width: 110, height: 110).blur(radius: 26).opacity(0.35)
                    Circle().fill(color).frame(width: 84, height: 84)
                    heroGlyph.id(icon).transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                .animation(motion, value: icon)
                .frame(height: 96)
                .contentShape(Circle())
            }
            .buttonStyle(HeroPressStyle(animated: !reduceMotion))
            .disabled(!presentation.heroTogglable)
            .accessibilityLabel(presentation.title)

            Text(presentation.title).font(.title3.weight(.semibold)).contentTransition(.opacity).animation(motion, value: icon)
            Text(presentation.subtitle)
                .font(.callout)
                .contentTransition(.opacity)
                .animation(motion, value: icon)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var heroGlyph: some View {
        if let image = IconAssets.heroImage(for: icon) {
            Image(nsImage: image).renderingMode(.template).foregroundColor(.white)
        } else {
            Text(icon.title).font(.system(size: 34))  // fallback outside the app bundle
        }
    }

    // MARK: Access needed

    @ViewBuilder private var grantBlock: some View {
        Button { model.onGrant() } label: {
            Text("Grant access")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(PanelTheme.grantButton)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)

        Button {
            withAnimation(motion) { model.commandShown.toggle() }
        } label: {
            HStack(spacing: 4) {
                Text("Show command")
                chevron(expanded: model.commandShown)
            }
            .font(.callout)
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)

        if model.commandShown {
            RuleBox(text: AccessChecker.ruleLine(user: model.userName)).transition(.opacity)
        }
    }

    // MARK: Settings and quit

    private var settingsGroup: some View {
        VStack(alignment: .leading, spacing: 6) {
            GroupedRows {
                launchRow
                if case .granted(let rule) = model.snapshot.access {
                    VStack(spacing: 0) {
                        Divider()
                        accessRows(rule: rule)
                    }
                    .transition(.opacity)
                }
            }
            if let loginError = model.loginError {
                Text(loginError).font(.callout).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var launchRow: some View {
        HStack(spacing: 10) {
            IconTile(color: .blue, image: Image(systemName: "power"))
            Text("Launch at login")
            Spacer()
            Toggle("", isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
    }

    @ViewBuilder private func accessRows(rule: String) -> some View {
        Button {
            withAnimation(motion) { model.accessExpanded.toggle() }
        } label: {
            HStack(spacing: 10) {
                IconTile(color: .green, image: Image(nsImage: lockImage))
                Text("Access")
                Spacer()
                Text("Granted").foregroundColor(.secondary)
                chevron(expanded: model.accessExpanded).foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if model.accessExpanded {
            VStack(spacing: 0) {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("This rule is in effect:").font(.caption).foregroundColor(.secondary)
                    RuleBox(text: rule)
                }
                .padding(12)
                Divider()
                Button { model.onRevoke() } label: {
                    Text("Revoke access")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .transition(.opacity)
        }
    }

    private var quitGroup: some View {
        GroupedRows {
            Button { model.onQuit() } label: {
                Text("Quit LidAwake")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Helpers

    private func chevron(expanded: Bool) -> some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .rotationEffect(.degrees(expanded ? 90 : 0))
    }

    /// The `blocked` lock artwork as a small template image for the Access row tile.
    private var lockImage: NSImage {
        IconAssets.image(for: .blocked) ?? NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil) ?? NSImage()
    }
}
