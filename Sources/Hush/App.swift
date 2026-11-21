import SwiftUI

@main
struct HushApp: App {
    // A plain `let` is fine: the App struct is created exactly once.
    private let hush = Hush()

    var body: some Scene {
        MenuBarExtra {
            MenuView(hush: hush)
        } label: {
            Image(nsImage: .menuBarLid(paused: !hush.isEnabled))
                .accessibilityLabel(hush.isEnabled ? "Hush, on" : "Hush, paused")
        }
        .menuBarExtraStyle(.window)
    }
}
