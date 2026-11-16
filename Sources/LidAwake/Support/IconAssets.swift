import AppKit
import LidAwakeCore

enum IconAssets {
    /// Monochrome template image: macOS tints it for light/dark appearance and highlighting.
    static func image(for icon: IconState) -> NSImage? {
        guard let image = Bundle.main.image(forResource: icon.assetName) else { return nil }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }

    /// Larger template image for the panel's hero circle (`<name>-large`).
    static func heroImage(for icon: IconState) -> NSImage? {
        guard let image = Bundle.main.image(forResource: icon.assetName + "-large") else { return nil }
        image.size = NSSize(width: 48, height: 48)  // the PNG canvas size: drawn 1:1, no resampling
        image.isTemplate = true
        return image
    }
}
