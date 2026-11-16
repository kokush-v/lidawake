import SwiftUI

/// Fades a block in when it is inserted. Only its own opacity animates, so no sibling (the hero)
/// is moved by the animation while the popover resizes.
struct FadeInOnAppear: ViewModifier {
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

extension View {
    func fadeInOnAppear(_ animation: Animation?) -> some View { modifier(FadeInOnAppear(animation: animation)) }
}
