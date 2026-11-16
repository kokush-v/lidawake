import LidAwakeCore
import SwiftUI

/// The popover panel: stacks the sections and the state-dependent cards.
struct PanelView: View {
    @ObservedObject var model: PanelViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var presentation: PanelPresentation { PanelPresentation(icon: model.snapshot.icon) }
    /// Shared by every transition; nil (instant) when Reduce Motion is on.
    private var motion: Animation? { reduceMotion ? nil : .easeInOut(duration: PanelTheme.motionDuration) }

    var body: some View {
        VStack(spacing: PanelTheme.spacing) {
            HeroSection(model: model, motion: motion, reduceMotion: reduceMotion)
            // Blocks fade in and out; the rows below slide. The model animates these changes together
            // with the popover's height (`PanelViewModel.apply`, `toggle`).
            if presentation.showsWarning {
                TintedCard(
                    text: "Switch back to sleep before putting your Mac in a bag. It may overheat and drain the battery.",
                    color: PanelTheme.color(for: .awake))
                    .transition(.opacity)
            }
            if let message = model.snapshot.errorMessage {
                TintedCard(text: message, color: PanelTheme.color(for: .error))
                    .transition(.opacity)
            }
            if case .granted = model.snapshot.access {} else {
                GrantAccessSection(model: model, motion: motion).transition(.opacity)
            }
            SettingsSection(model: model, motion: motion)
            QuitSection(model: model)
        }
        .padding(16)
        .frame(width: PanelTheme.width)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
        })
        .onPreferenceChange(ContentHeightKey.self) { model.contentHeightChanged($0) }
        // The root keeps one fixed size with the content pinned to its top: a root that changed size
        // would be animated around its centre, making the whole panel drop and settle.
        .frame(height: PanelTheme.canvasHeight, alignment: .top)
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
