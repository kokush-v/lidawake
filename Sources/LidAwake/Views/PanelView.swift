import LidAwakeCore
import SwiftUI

/// The popover panel: stacks the sections and the state-dependent cards.
struct PanelView: View {
    @ObservedObject var model: PanelViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var presentation: PanelPresentation { PanelPresentation(icon: model.snapshot.icon) }
    /// Shared by every transition; nil (instant) when Reduce Motion is on.
    private var motion: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.25) }

    var body: some View {
        VStack(spacing: PanelTheme.spacing) {
            HeroSection(model: model, motion: motion, reduceMotion: reduceMotion)
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
                GrantAccessSection(model: model, motion: motion).fadeInOnAppear(motion)
            }
            SettingsSection(model: model, motion: motion)
            QuitSection(model: model)
        }
        .padding(16)
        .frame(width: 340)
        // The popover resizes instantly while the content animates; pin the content to the top so the
        // hero does not shift when a card appears or disappears.
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
