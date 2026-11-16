import AppKit
import LidAwakeCore
import SwiftUI

/// The grouped settings rows: Launch at login and, once granted, the expandable Access row.
struct SettingsSection: View {
    @ObservedObject var model: PanelViewModel
    let motion: Animation?

    var body: some View {
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
        HStack(spacing: PanelTheme.rowSpacing) {
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
        .padding(.horizontal, PanelTheme.spacing)
        .frame(minHeight: PanelTheme.rowMinHeight)
    }

    @ViewBuilder private func accessRows(rule: String) -> some View {
        Button {
            withAnimation(motion) { model.accessExpanded.toggle() }
        } label: {
            HStack(spacing: PanelTheme.rowSpacing) {
                IconTile(color: .green, image: Image(nsImage: lockImage))
                Text("Access")
                Spacer()
                Text("Granted").foregroundColor(.secondary)
                Chevron(expanded: model.accessExpanded).foregroundColor(.secondary)
            }
            .padding(.horizontal, PanelTheme.spacing)
            .frame(minHeight: PanelTheme.rowMinHeight)
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
                .padding(PanelTheme.spacing)
                Divider()
                Button { model.onRevoke() } label: {
                    Text("Revoke access")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, PanelTheme.spacing)
                        .frame(minHeight: PanelTheme.rowMinHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .transition(.opacity)
        }
    }

    /// The `blocked` lock artwork as a small template image for the Access row tile.
    private var lockImage: NSImage {
        IconAssets.image(for: .blocked) ?? NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil) ?? NSImage()
    }
}
