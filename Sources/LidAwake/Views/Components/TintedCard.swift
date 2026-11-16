import SwiftUI

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
