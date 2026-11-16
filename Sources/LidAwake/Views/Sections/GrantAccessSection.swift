import LidAwakeCore
import SwiftUI

/// Shown until access is granted: the Grant button and the rule behind "Show command".
struct GrantAccessSection: View {
    @ObservedObject var model: PanelViewModel
    let motion: Animation?

    var body: some View {
        VStack(spacing: PanelTheme.spacing) {
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
                model.toggle(\.commandShown, animation: motion)
            } label: {
                HStack(spacing: 4) {
                    Text("Show command")
                    Chevron(expanded: model.commandShown)
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            if model.commandShown {
                RuleBox(text: AccessChecker.ruleLine(user: model.userName)).transition(.opacity)
            }
        }
    }
}
