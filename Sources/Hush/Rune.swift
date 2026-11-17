import SwiftUI

/// The Bluetooth rune from the app icon, so the menu bar, menu and icon share one mark.
nonisolated struct Rune: Shape {
    func path(in rect: CGRect) -> Path {
        let h = rect.height, w = h * 0.26, cx = rect.midX, cy = rect.midY
        var p = Path()
        p.move(to: CGPoint(x: cx - w, y: cy - h / 4))
        p.addLine(to: CGPoint(x: cx + w, y: cy + h / 4))
        p.addLine(to: CGPoint(x: cx, y: cy + h / 2))
        p.addLine(to: CGPoint(x: cx, y: cy - h / 2))
        p.addLine(to: CGPoint(x: cx + w, y: cy - h / 4))
        p.addLine(to: CGPoint(x: cx - w, y: cy + h / 4))
        return p
    }
}

extension NSImage {
    /// Menu bar template: the rune when armed; dimmed with a slash when paused.
    static func menuBarRune(paused: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.setLineCap(.round); ctx.setLineJoin(.round)
            ctx.addPath(Rune().path(in: CGRect(x: 4, y: 2.5, width: 10, height: 13)).cgPath)
            ctx.setLineWidth(1.7)
            ctx.setStrokeColor(NSColor.black.withAlphaComponent(paused ? 0.45 : 1).cgColor)
            ctx.strokePath()
            if paused {
                // Knock a gap out around the slash so it reads cleanly at 18pt.
                ctx.setBlendMode(.clear); ctx.setLineWidth(4)
                ctx.move(to: CGPoint(x: 3, y: 3)); ctx.addLine(to: CGPoint(x: 15, y: 15)); ctx.strokePath()
                ctx.setBlendMode(.normal); ctx.setLineWidth(1.7)
                ctx.move(to: CGPoint(x: 3, y: 3)); ctx.addLine(to: CGPoint(x: 15, y: 15))
                ctx.setStrokeColor(NSColor.black.cgColor); ctx.strokePath()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
