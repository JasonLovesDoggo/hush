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
