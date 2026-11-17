// Renders Resources/AppIcon.icns and Resources/icon.png. Run: swift scripts/make-icon.swift
import AppKit

/// Apple-style continuous-corner squircle (superellipse).
func squircle(in r: CGRect, n: CGFloat = 5) -> CGPath {
    let path = CGMutablePath()
    let a = r.width / 2, b = r.height / 2
    for i in 0...360 {
        let t = CGFloat(i) * .pi / 180
        let c = cos(t), s = sin(t)
        let x = r.midX + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = r.midY + b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func draw(_ ctx: CGContext, size: CGFloat) {
    let u = size / 1024
    ctx.scaleBy(x: u, y: u)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let tile = squircle(in: CGRect(x: 100, y: 100, width: 824, height: 824))

    // Drop shadow under the tile.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: rgb(0x000000, 0.35))
    ctx.addPath(tile); ctx.setFillColor(rgb(0x14163A)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(tile); ctx.clip()

    // Night sky.
    let sky = CGGradient(colorsSpace: space, colors: [rgb(0x3A3F9C), rgb(0x1A1C52), rgb(0x0A0B22)] as CFArray,
                         locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(sky, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

    // Warm glow leaking out of the closing lid.
    let lidY: CGFloat = 318
    let glow = CGGradient(colorsSpace: space, colors: [rgb(0x9C8CFF, 0.55), rgb(0x6A5CFF, 0.18), rgb(0x6A5CFF, 0)] as CFArray,
                          locations: [0, 0.45, 1])!
    ctx.saveGState()
    ctx.translateBy(x: 512, y: lidY); ctx.scaleBy(x: 1.9, y: 0.75)
    ctx.drawRadialGradient(glow, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 230, options: [])
    ctx.restoreGState()

    // A few stars.
    for (x, y, r, a) in [(258.0, 790.0, 5.0, 0.9), (330, 690, 3, 0.55), (770, 812, 4, 0.75),
                         (720, 700, 2.5, 0.45), (196, 610, 2.5, 0.4), (836, 600, 3, 0.5)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
        ctx.setFillColor(rgb(0xFFFFFF, a))
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    // Bluetooth rune, fading as it sinks toward the lid.
    let h: CGFloat = 420, w: CGFloat = 108, cx: CGFloat = 512, cy: CGFloat = 586
    let rune = CGMutablePath()
    rune.move(to: CGPoint(x: cx - w, y: cy + h / 4))
    rune.addLine(to: CGPoint(x: cx + w, y: cy - h / 4))
    rune.addLine(to: CGPoint(x: cx, y: cy - h / 2))
    rune.addLine(to: CGPoint(x: cx, y: cy + h / 2))
    rune.addLine(to: CGPoint(x: cx + w, y: cy + h / 4))
    rune.addLine(to: CGPoint(x: cx - w, y: cy - h / 4))
    let stroked = rune.copy(strokingWithWidth: 50, lineCap: .round, lineJoin: .round, miterLimit: 10)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 30, color: rgb(0xB8B0FF, 0.45))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.addPath(stroked); ctx.clip()
    let fade = CGGradient(colorsSpace: space, colors: [rgb(0xFFFFFF), rgb(0xE6E2FF, 0.9), rgb(0xC9C2FF, 0.12)] as CFArray,
                          locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(fade, start: CGPoint(x: cx, y: cy + h / 2 + 25), end: CGPoint(x: cx, y: cy - h / 2 - 25), options: [])
    ctx.endTransparencyLayer()
    ctx.restoreGState()

    // The lid: a bright seam of light.
    let seam = CGRect(x: 262, y: lidY - 9, width: 500, height: 18)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 24, color: rgb(0xC4BBFF, 0.9))
    let seamGrad = CGGradient(colorsSpace: space, colors: [rgb(0xFFFFFF, 0), rgb(0xFFFFFF), rgb(0xFFFFFF, 0)] as CFArray,
                              locations: [0, 0.5, 1])!
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.addPath(CGPath(roundedRect: seam, cornerWidth: 9, cornerHeight: 9, transform: nil)); ctx.clip()
    ctx.drawLinearGradient(seamGrad, start: CGPoint(x: seam.minX, y: lidY), end: CGPoint(x: seam.maxX, y: lidY), options: [])
    ctx.endTransparencyLayer()
    ctx.restoreGState()

    ctx.restoreGState()

    // Hairline highlight on the tile's edge — light catching the material.
    ctx.addPath(tile); ctx.setStrokeColor(rgb(0xFFFFFF, 0.12)); ctx.setLineWidth(3); ctx.strokePath()
}

func png(_ px: Int) -> Data {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    draw(ctx, size: CGFloat(px))
    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! png(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! png(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try! png(512).write(to: URL(fileURLWithPath: "Resources/icon.png"))
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! task.run(); task.waitUntilExit()
print("Wrote Resources/AppIcon.icns")
