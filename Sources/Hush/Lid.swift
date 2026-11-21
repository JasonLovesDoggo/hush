import SwiftUI

/// A laptop seen from the side: the base, and a lid hinged at the left.
/// `angle` is the lid's opening in degrees, so it can animate closing.
nonisolated struct Lid: Shape {
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let hinge = CGPoint(x: rect.minX, y: rect.maxY)
        let length = rect.width * 0.92
        let a = angle * .pi / 180
        var p = Path()
        p.move(to: hinge)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))               // base
        p.move(to: hinge)
        p.addLine(to: CGPoint(x: hinge.x + length * cos(a), y: hinge.y - length * sin(a))) // lid
        return p
    }
}

extension Lid {
    static let closing = 24.0 // armed: the lid on its way shut
    static let open = 62.0    // paused: lid up, Hush stands aside
}

extension NSImage {
    /// Menu bar template: the closing lid with an arc tracing its motion. Paused keeps the
    /// same glyph and adds a slash, like bell → bell.slash, so the mark never changes identity.
    static func menuBarLid(paused: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.setStrokeColor(NSColor.black.cgColor)

            // Lid + base, drawn in y-up coordinates.
            let hinge = CGPoint(x: 2.5, y: 3.5)
            let lidAngle = Lid.closing * .pi / 180
            ctx.move(to: CGPoint(x: 17.5, y: hinge.y)); ctx.addLine(to: hinge)
            ctx.addLine(to: CGPoint(x: hinge.x + 14 * cos(lidAngle), y: hinge.y + 14 * sin(lidAngle)))
            ctx.setLineWidth(2); ctx.strokePath()

            // Arc from "open" down toward the lid, arrowhead along the tangent.
            let r: CGFloat = 13.5, from = 78.0 * .pi / 180, to = 40.0 * .pi / 180
            ctx.addArc(center: hinge, radius: r, startAngle: from, endAngle: to, clockwise: true)
            ctx.setLineWidth(1.4); ctx.strokePath()
            let tip = CGPoint(x: hinge.x + r * cos(to), y: hinge.y + r * sin(to))
            let heading = atan2(-cos(to), sin(to)) // direction of travel (clockwise)
            for side in [-1.0, 1.0] {
                let back = heading + .pi + side * 0.55
                ctx.move(to: tip); ctx.addLine(to: CGPoint(x: tip.x + 2.8 * cos(back), y: tip.y + 2.8 * sin(back)))
            }
            ctx.strokePath()

            if paused {
                let a = CGPoint(x: 3, y: 16), b = CGPoint(x: 17, y: 2)
                ctx.setBlendMode(.clear); ctx.setLineWidth(4.5)
                ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
                ctx.setBlendMode(.normal); ctx.setLineWidth(1.7)
                ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
