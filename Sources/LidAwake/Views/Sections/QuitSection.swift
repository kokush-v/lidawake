import SwiftUI

/// The red Quit row in its own group.
struct QuitSection: View {
    @ObservedObject var model: PanelViewModel

    var body: some View {
        GroupedRows {
            Button { model.onQuit() } label: {
                Text("Quit LidAwake")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PanelTheme.spacing)
                    .frame(minHeight: PanelTheme.rowMinHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
