// Renders Resources/Icons/*.svg into monochrome template PNGs (18pt, @1x and @2x) in Resources/Icons/Menubar.
// Usage: swift scripts/make-icons.swift Resources/Icons
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/Icons")
let out = root.appendingPathComponent("Menubar")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

let names = ["awake", "sleep", "blocked", "error"]
let canvas: CGFloat = 18   // menu-bar icon size in points
let glyph: CGFloat = 15    // glyph box inside the canvas

func clean(_ svg: String) -> String {
    var s = svg
    s = s.replacingOccurrences(of: #"<rect[^>]*fill="white"[^>]*/>"#, with: "", options: .regularExpression)
    s = s.replacingOccurrences(of: #"#[0-9A-Fa-f]{6}"#, with: "#000000", options: .regularExpression)
    return s
}

func render(_ image: NSImage, scale: Int) -> Data? {
    let px = Int(canvas) * scale
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    let size = image.size
    let k = min(glyph / size.width, glyph / size.height)
    let w = size.width * k, h = size.height * k
    image.draw(in: NSRect(x: (canvas - w) / 2, y: (canvas - h) / 2, width: w, height: h),
               from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

for name in names {
    let src = root.appendingPathComponent("\(name).svg")
    guard let text = try? String(contentsOf: src, encoding: .utf8),
          let image = NSImage(data: Data(clean(text).utf8)), image.size.width > 0 else {
        print("FAILED to load \(name).svg"); exit(1)
    }
    for scale in [1, 2] {
        let file = out.appendingPathComponent(scale == 1 ? "\(name).png" : "\(name)@2x.png")
        guard let data = render(image, scale: scale) else { print("FAILED to render \(name)"); exit(1) }
        try data.write(to: file)
    }
    print("ok \(name)")
}
