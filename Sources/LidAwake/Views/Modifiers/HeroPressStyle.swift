import SwiftUI

/// Small press feedback for the hero: shrinks slightly while pressed and springs back.
struct HeroPressStyle: ButtonStyle {
    let animated: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(animated ? .spring(response: 0.25, dampingFraction: 0.6) : nil, value: configuration.isPressed)
    }
}
