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

    /// Gap between sections; also the horizontal inset of a row.
    static let spacing: CGFloat = 12
    static let rowMinHeight: CGFloat = 44
    /// Gap between a row's icon tile and its label.
    static let rowSpacing: CGFloat = 10
}
