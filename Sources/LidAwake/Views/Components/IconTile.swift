import SwiftUI

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
