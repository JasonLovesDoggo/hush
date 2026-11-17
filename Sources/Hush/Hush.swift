import ServiceManagement
import SwiftUI

/// The rules: lid closes → radio off (remembering what was connected); lid opens → put it all back.
@Observable
final class Hush {
    let bluetooth = Bluetooth()
    private var lid: LidMonitor?
    private let defaults = UserDefaults.standard

    var isEnabled: Bool { didSet { defaults.set(isEnabled, forKey: "enabled") } }
    var restoreOnOpen: Bool { didSet { defaults.set(restoreOnOpen, forKey: "restoreOnOpen") } }
    var reconnectDevices: Bool { didSet { defaults.set(reconnectDevices, forKey: "reconnectDevices") } }
    var stayOnWithDisplay: Bool { didSet { defaults.set(stayOnWithDisplay, forKey: "stayOnWithDisplay") } }
    private(set) var lastAction: (text: String, date: Date)?

    /// Persisted so a crash or update while the lid is closed still restores Bluetooth.
    private var turnedOffByUs: Bool { didSet { defaults.set(turnedOffByUs, forKey: "turnedOffByUs") } }
    private var savedDevices: [String] { didSet { defaults.set(savedDevices, forKey: "savedDevices") } }

    init() {
        defaults.register(defaults: [
            "enabled": true, "restoreOnOpen": true, "reconnectDevices": true, "stayOnWithDisplay": true,
        ])
        isEnabled = defaults.bool(forKey: "enabled")
        restoreOnOpen = defaults.bool(forKey: "restoreOnOpen")
        reconnectDevices = defaults.bool(forKey: "reconnectDevices")
        stayOnWithDisplay = defaults.bool(forKey: "stayOnWithDisplay")
        turnedOffByUs = defaults.bool(forKey: "turnedOffByUs")
        savedDevices = defaults.stringArray(forKey: "savedDevices") ?? []

        if !defaults.bool(forKey: "hasLaunched") {
            defaults.set(true, forKey: "hasLaunched")
            // A lid watcher is only useful if it's running. (didSet doesn't fire in init.)
            try? SMAppService.mainApp.register()
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }

        lid = LidMonitor { [weak self] in self?.handle($0) }
        if lid?.isLidClosed == false { restore() }
    }

    private func handle(_ event: LidMonitor.Event) {
        switch event {
        case .closed(let causesSleep):
            if causesSleep || !stayOnWithDisplay { turnOff() }
        case .willSleep:
            // Backstop in case the clamshell message was missed.
            if lid?.isLidClosed == true, !stayOnWithDisplay || !externalDisplayAttached { turnOff() }
        case .opened:
            restore()
        case .didWake:
            if lid?.isLidClosed == false { restore() }
        }
    }

    private var externalDisplayAttached: Bool {
        NSScreen.screens.contains { CGDisplayIsBuiltin($0.displayID) == 0 }
    }

    private func turnOff() {
        guard isEnabled, bluetooth.radioIsOn else { return } // already off: not ours to restore
        savedDevices = bluetooth.connectedDevices()
        bluetooth.setPower(false)
        turnedOffByUs = true
        let count = savedDevices.count
        record(count == 0 ? "Turned off" : "Turned off · \(count) device\(count == 1 ? "" : "s")")
    }

    private func restore() {
        guard turnedOffByUs else { return }
        turnedOffByUs = false
        guard restoreOnOpen else { return }
        let devices = reconnectDevices ? savedDevices : []
        record("Turned back on")
        Task { await bluetooth.powerOnAndReconnect(devices) }
    }

    /// The menu's Bluetooth switch. A manual choice always wins over our pending restore.
    func setBluetooth(_ on: Bool) {
        turnedOffByUs = false
        bluetooth.setPower(on)
    }

    private func record(_ text: String) {
        lastAction = (text, .now)
        log.info("\(text, privacy: .public)")
    }

    var launchAtLogin = SMAppService.mainApp.status == .enabled {
        didSet {
            guard launchAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if launchAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                log.error("Login item: \(error.localizedDescription, privacy: .public)")
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
    }
}
