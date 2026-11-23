import AppKit

// Plain AppKit entry point: Hush is a status item and a panel, nothing else.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var status: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = StatusController(hush: Hush())
    }
}
