import SwiftUI

/// Disclosure arrow of an expandable row: points right, turns down when expanded.
struct Chevron: View {
    let expanded: Bool

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .rotationEffect(.degrees(expanded ? 90 : 0))
    }
}
