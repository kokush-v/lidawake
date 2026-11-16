// Renders Resources/AppIcon.icns: an indigo rounded square with the coffee cup and "zzz" from Resources/Icons.
// Usage: swift scripts/make-app-icon.swift Resources
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources")
let icons = out.appendingPathComponent("Icons")

/// Loads an SVG from Resources/Icons as a white glyph.
func glyph(_ name: String) -> NSImage {
    let url = icons.appendingPathComponent("\(name).svg")
    guard var text = try? String(contentsOf: url, encoding: .utf8) else { print("FAILED to read \(name).svg"); exit(1) }
    text = text.replacingOccurrences(of: #"<rect[^>]*fill="white"[^>]*/>"#, with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: #"#[0-9A-Fa-f]{6}"#, with: "#FFFFFF", options: .regularExpression)
    text = text.replacingOccurrences(of: "currentColor", with: "#FFFFFF")
    text = text.replacingOccurrences(of: "width=\"24\"", with: "width=\"1024\"").replacingOccurrences(of: "height=\"24\"", with: "height=\"1024\"")  // SVGs rasterize at their own size: render large so scaling down stays sharp
    guard let image = NSImage(data: Data(text.utf8)), image.size.width > 0 else { print("FAILED to load \(name).svg"); exit(1) }
    return image
}

let cup = glyph("awake")
let zzz = glyph("sleep")

/// Draws an image fitted and centered in a square box (1024-unit coordinates).
func draw(_ image: NSImage, center: NSPoint, box: CGFloat, shadow: Bool) {
    let k = min(box / image.size.width, box / image.size.height)
    let w = image.size.width * k, h = image.size.height * k
    NSGraphicsContext.saveGraphicsState()
    if shadow {
        let s = NSShadow()
        s.shadowColor = NSColor.black.withAlphaComponent(0.28)
        s.shadowBlurRadius = 18
        s.shadowOffset = NSSize(width: 0, height: -8)
        s.set()
    }
    image.draw(in: NSRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h),
               from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

func render(px: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    let t = NSAffineTransform()
    t.scale(by: CGFloat(px) / 1024)
    t.concat()

    // macOS icon grid: an 824-unit rounded square centered on the 1024 canvas.
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let path = NSBezierPath(roundedRect: body, xRadius: 824 * 0.2237, yRadius: 824 * 0.2237)
    NSGraphicsContext.saveGraphicsState()
    let drop = NSShadow()
    drop.shadowColor = NSColor.black.withAlphaComponent(0.3)
    drop.shadowBlurRadius = 24
    drop.shadowOffset = NSSize(width: 0, height: -10)
    drop.set()
    NSColor(srgbRed: 0.29, green: 0.28, blue: 0.82, alpha: 1).setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSGradient(colors: [
        NSColor(srgbRed: 0.45, green: 0.44, blue: 0.96, alpha: 1),
        NSColor(srgbRed: 0.29, green: 0.28, blue: 0.82, alpha: 1),
    ])?.draw(in: body, angle: -70)
    // Soft top highlight.
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.18), NSColor.white.withAlphaComponent(0)])?
        .draw(in: NSRect(x: 100, y: 512, width: 824, height: 412), angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    draw(cup, center: NSPoint(x: 486, y: 478), box: 461, shadow: true)
    draw(zzz, center: NSPoint(x: 692, y: 708), box: 190, shadow: true)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

let iconset = out.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        guard let data = render(px: size * scale) else { print("FAILED to render \(size)@\(scale)x"); exit(1) }
        try data.write(to: iconset.appendingPathComponent(scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"))
    }
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", out.appendingPathComponent("AppIcon.icns").path]
try task.run(); task.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print(task.terminationStatus == 0 ? "ok AppIcon.icns" : "iconutil failed")
