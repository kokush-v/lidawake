// Renders Resources/Icons/*.svg into monochrome template PNGs (@1x and @2x):
// 18pt menu-bar icons in Resources/Icons/Menubar and 48pt panel hero icons (<name>-large) in Resources/Icons/Panel.
// Usage: swift scripts/make-icons.swift Resources/Icons
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/Icons")
let out = root.appendingPathComponent("Menubar")
let panelOut = root.appendingPathComponent("Panel")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(at: panelOut, withIntermediateDirectories: true)

let names = ["awake", "sleep", "blocked", "error"]
/// A rendering target: canvas size in points and the glyph box inside it.
struct Target { let dir: URL; let suffix: String; let canvas: CGFloat; let glyph: CGFloat; let stroke: String }
let targets = [
    // Menu bar: 1.5 px per SVG unit at @2x, so the 2-unit stroke is exactly 3 px (a heavier stroke clogs the cup).
    Target(dir: out, suffix: "", canvas: 18, glyph: 18, stroke: "2"),
    Target(dir: panelOut, suffix: "-large", canvas: 48, glyph: 40, stroke: "2"),  // panel hero
]

func clean(_ svg: String, stroke: String) -> String {
    var s = svg
    s = s.replacingOccurrences(of: "stroke-width=\"2\"", with: "stroke-width=\"\(stroke)\"")
    s = s.replacingOccurrences(of: #"<rect[^>]*fill="white"[^>]*/>"#, with: "", options: .regularExpression)
    s = s.replacingOccurrences(of: #"#[0-9A-Fa-f]{6}"#, with: "#000000", options: .regularExpression)
    s = s.replacingOccurrences(of: "currentColor", with: "#000000")
    s = s.replacingOccurrences(of: "width=\"24\"", with: "width=\"1024\"").replacingOccurrences(of: "height=\"24\"", with: "height=\"1024\"")  // SVGs rasterize at their own size: render large so scaling down stays sharp
    return s
}

func render(_ image: NSImage, scale: Int, canvas: CGFloat, glyph: CGFloat) -> Data? {
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
    guard let text = try? String(contentsOf: src, encoding: .utf8) else { print("FAILED to read \(name).svg"); exit(1) }
    for t in targets {
        guard let image = NSImage(data: Data(clean(text, stroke: t.stroke).utf8)), image.size.width > 0 else {
            print("FAILED to load \(name).svg"); exit(1)
        }
        for scale in [1, 2] {
            let base = name + t.suffix
            let file = t.dir.appendingPathComponent(scale == 1 ? "\(base).png" : "\(base)@2x.png")
            guard let data = render(image, scale: scale, canvas: t.canvas, glyph: t.glyph) else {
                print("FAILED to render \(base)"); exit(1)
            }
            try data.write(to: file)
        }
    }
    print("ok \(name)")
}
