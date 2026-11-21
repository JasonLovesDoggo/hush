import SwiftUI

struct MenuView: View {
    @Bindable var hush: Hush
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tiles
            Text(hush.isEnabled ? "Closing the lid turns Bluetooth off." : "Paused. Closing the lid leaves Bluetooth alone.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .padding(.horizontal, 2)
                .contentTransition(.opacity)
            if hush.bluetooth.access == .denied { accessBanner }

            Divider().padding(.vertical, 10)

            Group {
                SectionLabel("When the lid opens")
                Row("Turn Bluetooth back on", isOn: $hush.restoreOnOpen)
                Row("Reconnect my devices", isOn: $hush.reconnectDevices)
                    .padding(.leading, 12)
                    .disabled(!hush.restoreOnOpen)
                    .opacity(hush.restoreOnOpen ? 1 : 0.45)

                Divider().padding(.vertical, 8)

                Row("Stay on with an external display", isOn: $hush.stayOnWithDisplay)
                    .help("In clamshell mode you’re likely still typing on a Bluetooth keyboard.")
            }
            .disabled(!hush.isEnabled)
            .opacity(hush.isEnabled ? 1 : 0.45)

            Row("Open at login", isOn: $hush.launchAtLogin)

            Divider().padding(.vertical, 8)

            footer
        }
        .padding(12)
        .frame(width: 300)
        .animation(.smooth(duration: 0.2), value: hush.isEnabled)
        .animation(.smooth(duration: 0.2), value: hush.restoreOnOpen)
    }

    /// Two Control Center–style modules: Hush itself, and the radio it manages.
    private var tiles: some View {
        GlassGroup {
            HStack(spacing: 8) {
                Tile(title: "Hush", subtitle: hush.isEnabled ? "On" : "Paused", isOn: hush.isEnabled) {
                    hush.isEnabled.toggle()
                } icon: {
                    Lid(angle: hush.isEnabled ? Lid.closing : Lid.open)
                        .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                        .frame(width: 13, height: 9)
                        .offset(x: -1, y: 1)
                        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.15), value: hush.isEnabled)
                }
                Tile(title: "Bluetooth", subtitle: hush.bluetooth.isOn ? "On" : "Off", isOn: hush.bluetooth.isOn) {
                    hush.setBluetooth(!hush.bluetooth.isOn)
                } icon: {
                    Rune()
                        .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                        .frame(width: 8, height: 12)
                }
            }
        }
    }

    private var accessBanner: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text("Hush needs Bluetooth access to control the radio.")
                    .font(.system(size: 11))
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Privacy Settings…") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")!)
                }
                .controlSize(.small)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.12), in: .rect(cornerRadius: 8))
        .padding(.top, 8)
    }

    private var footer: some View {
        HStack {
            if let last = hush.lastAction {
                TimelineView(.everyMinute) { _ in
                    Text("\(last.text) · \(last.date, format: .relative(presentation: .named))")
                }
            } else {
                Text("Nothing yet — close the lid to try it")
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
                .keyboardShortcut("q")
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }
}

private struct Row: View {
    let title: String
    @Binding var isOn: Bool
    init(_ title: String, isOn: Binding<Bool>) { self.title = title; _isOn = isOn }

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).font(.system(size: 13)).frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .padding(.vertical, 3)
    }
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }
}

/// A Control Center module: a round toggle button on a glass tile. The whole tile is the hit target.
private struct Tile<Icon: View>: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let action: () -> Void
    @ViewBuilder let icon: Icon

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon
                    .foregroundStyle(isOn ? .white : .primary)
                    .frame(width: 30, height: 30)
                    .background { Circle().fill(isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)) }
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(.system(size: 12, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .contentShape(.rect(cornerRadius: 16))
            .glassTile()
        }
        .buttonStyle(PressStyle())
        .animation(.smooth(duration: 0.2), value: isOn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// Instant, subtle press feedback — the menu is opened many times a day, so nothing slower.
private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.16, bounce: 0), value: configuration.isPressed)
    }
}

/// Liquid Glass on macOS 26+, a quiet material fill before that.
private struct GlassGroup<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 8) { content }
        } else {
            content
        }
    }
}

private extension View {
    @ViewBuilder func glassTile() -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        } else {
            background(.quinary, in: .rect(cornerRadius: 16))
        }
    }
}
