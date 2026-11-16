import SwiftUI

/// iOS-style rounded group: rows separated by hairlines.
struct GroupedRows<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .frame(maxWidth: .infinity)
            .background(PanelTheme.groupFill)
            .clipShape(RoundedRectangle(cornerRadius: PanelTheme.groupCorner, style: .continuous))
    }
}
