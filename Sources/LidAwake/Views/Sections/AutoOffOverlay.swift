import LidAwakeCore
import SwiftUI

/// A card with the auto-off wheel over a dimmed panel. Closes on an outside click, Done or Escape.
struct AutoOffOverlay: View {
    @ObservedObject var model: PanelViewModel
    let motion: Animation?

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .contentShape(Rectangle())
                .onTapGesture(perform: close)
            VStack(spacing: 10) {
                Text("Auto-off").font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
                WheelPicker(
                    items: AutoOff.allCases,
                    selection: Binding(get: { model.snapshot.autoOff }, set: { model.onSetAutoOff($0) }),
                    label: { $0.label })
                Button(action: close) {
                    Text("Done")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(PanelTheme.grantButton, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
            .frame(width: 200)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: PanelTheme.groupCorner, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 4)
        }
        .onExitCommand(perform: close)
    }

    private func close() {
        model.toggle(\.autoOffPickerShown, animation: motion)
    }
}
