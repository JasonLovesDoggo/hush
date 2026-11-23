import AppKit
import SwiftUI

/// The menu bar icon and its menu — a real `NSMenu`, built the way Tailscale builds theirs:
/// SwiftUI rows with switches hosted in menu items, plain native items for the rest. The
/// system draws the glass, highlight and keyboard navigation, so it matches every other menu.
final class StatusController: NSObject, NSMenuDelegate {
    private let hush: Hush
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let lastActionItem = NSMenuItem()
    private let accessItem = NSMenuItem(title: "Allow Bluetooth Access…", action: #selector(openPrivacy), keyEquivalent: "")

    init(hush: Hush) {
        self.hush = hush
        super.init()

        let access = accessItem
        access.target = self
        access.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)
        lastActionItem.isEnabled = false

        menu.autoenablesItems = false
        menu.delegate = self
        menu.items = [
            hosted(HeaderRow(hush: hush)),
            access,
            .separator(),
            hosted(SwitchRow("Bluetooth", isOn: Binding(get: { hush.bluetooth.isOn }, set: { hush.setBluetooth($0) }))),
            .separator(),
            .sectionHeader(title: "When the Lid Opens"),
            hosted(SettingRow(hush: hush, title: "Turn Bluetooth Back On", key: \.restoreOnOpen)),
            hosted(SettingRow(hush: hush, title: "Reconnect My Devices", key: \.reconnectDevices, indent: true)),
            .separator(),
            hosted(SettingRow(hush: hush, title: "Stay On with an External Display", key: \.stayOnWithDisplay)),
            hosted(SwitchRow("Open at Login", isOn: Binding(get: { hush.launchAtLogin }, set: { hush.launchAtLogin = $0 }))),
            .separator(),
            lastActionItem,
            NSMenuItem(title: "Quit Hush", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
        ]
        item.menu = menu
        trackState()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        if let last = hush.lastAction {
            lastActionItem.title = "\(last.text) · \(last.date.formatted(.relative(presentation: .named)))"
        } else {
            lastActionItem.title = "Nothing yet. Close the lid to try it."
        }
    }

    private func trackState() {
        withObservationTracking {
            item.button?.image = .menuBarLid(paused: !hush.isEnabled)
            item.button?.setAccessibilityLabel(hush.isEnabled ? "Hush, on" : "Hush, paused")
            accessItem.isHidden = hush.bluetooth.access != .denied
        } onChange: { [weak self] in
            Task { @MainActor in self?.trackState() }
        }
    }

    @objc private func openPrivacy() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")!)
    }

    private func hosted(_ view: some View) -> NSMenuItem {
        let host = NSHostingView(rootView: view.frame(width: 320))
        host.frame.size = host.fittingSize
        let item = NSMenuItem()
        item.view = host
        return item
    }
}

// MARK: - Rows

/// "Hush / Turns off Bluetooth when the lid closes" with the master switch — Tailscale's header.
private struct HeaderRow: View {
    @Bindable var hush: Hush

    var body: some View {
        SwitchRow("Hush", subtitle: hush.isEnabled ? "Turns off Bluetooth when the lid closes" : "Paused",
                  isOn: $hush.isEnabled)
    }
}

/// A setting that only matters while Hush is on (and, for reconnecting, while restore is on).
private struct SettingRow: View {
    @Bindable var hush: Hush
    let title: String
    let key: ReferenceWritableKeyPath<Hush, Bool>
    var indent = false

    var body: some View {
        let enabled = hush.isEnabled && (key != \.reconnectDevices || hush.restoreOnOpen)
        SwitchRow(title, isOn: Binding(get: { hush[keyPath: key] }, set: { hush[keyPath: key] = $0 }), indent: indent)
            .disabled(!enabled)
    }
}

/// Title, optional subtitle, trailing switch. Clicking anywhere on the row flips it, and the
/// menu stays open so you can see the result.
private struct SwitchRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    var indent = false
    @Environment(\.isEnabled) private var isEnabled

    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>, indent: Bool = false) {
        self.title = title; self.subtitle = subtitle; _isOn = isOn; self.indent = indent
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13))
                if let subtitle {
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .opacity(isEnabled ? 1 : 0.4)
            Spacer(minLength: 0)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(MenuSwitch())
        }
        .padding(.leading, indent ? 31 : 15)
        .padding(.trailing, 15)
        .padding(.vertical, subtitle == nil ? 3 : 5)
        .contentShape(.rect)
        .onTapGesture { if isEnabled { isOn.toggle() } }
    }
}

/// A switch drawn in the accent colour. The stock one is AppKit-backed and checks whether its
/// window is key; menus never are, so it always draws greyed out. Tailscale draws its own for
/// the same reason — this copies its proportions: 54×23 track, pill knob.
private struct MenuSwitch: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let on = configuration.isOn
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule()
                .fill(on ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.primary.opacity(0.18)))
            Capsule()
                .fill(.white)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                .frame(width: 33, height: 19)
                .padding(2)
        }
        .frame(width: 54, height: 23)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.spring(duration: 0.25, bounce: 0), value: on)
        .contentShape(.capsule)
        .onTapGesture { if isEnabled { configuration.isOn.toggle() } }
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}
