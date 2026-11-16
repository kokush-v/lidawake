import AppKit
import LidAwakeCore
import SwiftUI

/// Colours and shared styles of the panel.
enum PanelTheme {
    /// Awake orange, Sleep indigo, Access needed grey, error red; all adapt to light/dark appearance.
    static func color(for accent: PanelAccent) -> Color {
        switch accent {
        case .awake: return .orange
        case .sleep: return .indigo
        case .neutral: return neutralGrey
        case .error: return .red
        }
    }

    /// The system's "grey 2" (#636366 in dark appearance).
    private static let neutralGrey = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.388, green: 0.388, blue: 0.4, alpha: 1)
            : NSColor(srgbRed: 0.682, green: 0.682, blue: 0.698, alpha: 1)
    })

    static let grantButton = Color.blue
    static let groupFill = Color.primary.opacity(0.07)
    static let groupCorner: CGFloat = 12
}

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

/// Small coloured square with a white glyph, used at the start of a settings row.
struct IconTile: View {
    let color: Color
    let image: Image

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: 14, height: 14)
            .foregroundColor(.white)
            .frame(width: 26, height: 26)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

/// Tinted rounded card for the Awake reminder and error messages.
struct TintedCard: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Monospaced, selectable box showing the sudoers rule.
struct RuleBox: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .fixedSize(horizontal: false, vertical: true)
    }
}
