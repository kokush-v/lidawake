import LidAwakeCore
import SwiftUI

/// The large round state icon (also the toggle) with the state title and subtitle.
struct HeroSection: View {
    @ObservedObject var model: PanelViewModel
    let motion: Animation?
    let reduceMotion: Bool

    private var icon: IconState { model.snapshot.icon }
    private var presentation: PanelPresentation { PanelPresentation(icon: icon) }

    /// While Awake is counting down, the time left replaces the generic subtitle.
    private func subtitle(at date: Date) -> String {
        if icon == .awake, let deadline = model.snapshot.autoOffDeadline {
            return "Auto-off in \(AutoOff.remainingLabel(deadline.timeIntervalSince(date)))"
        }
        return presentation.subtitle
    }

    var body: some View {
        let color = PanelTheme.color(for: presentation.accent)
        return VStack(spacing: 8) {
            Button { model.onToggle() } label: {
                ZStack {
                    Circle().fill(color).frame(width: 110, height: 110).blur(radius: 26).opacity(0.35)
                    Circle().fill(color).frame(width: 84, height: 84)
                    glyph.id(icon).transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                .animation(motion, value: icon)
                .frame(height: 96)
                .contentShape(Circle())
            }
            .buttonStyle(HeroPressStyle(animated: !reduceMotion))
            .disabled(!presentation.heroTogglable)
            .accessibilityLabel(presentation.title)

            Text(presentation.title).font(.title3.weight(.semibold)).contentTransition(.opacity).animation(motion, value: icon)
            TimelineView(.everyMinute) { context in
                Text(subtitle(at: context.date))
                    .font(.callout)
                    .contentTransition(.opacity)
                    .animation(motion, value: icon)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var glyph: some View {
        if let image = IconAssets.heroImage(for: icon) {
            Image(nsImage: image).renderingMode(.template).foregroundColor(.white)
        } else {
            Text(icon.title).font(.system(size: 34))  // fallback outside the app bundle
        }
    }
}
