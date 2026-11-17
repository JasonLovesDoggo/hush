import SwiftUI

struct MenuView: View {
    @Bindable var hush: Hush

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if hush.bluetooth.access == .denied { accessBanner }

            Divider().padding(.vertical, 8)

            Row("Bluetooth", isOn: Binding(
                get: { hush.bluetooth.isOn },
                set: { hush.setBluetooth($0) }
            ))

            Divider().padding(.vertical, 8)

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
        .padding(14)
        .frame(width: 300)
        .animation(.smooth(duration: 0.25), value: hush.isEnabled)
        .animation(.smooth(duration: 0.25), value: hush.restoreOnOpen)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(hush.isEnabled
                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.23, green: 0.25, blue: 0.61),
                                                            Color(red: 0.07, green: 0.08, blue: 0.22)],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.secondary.opacity(0.2)))
                Rune()
                    .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(hush.isEnabled ? .white : .secondary)
                    .frame(width: 9, height: 13)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text("Hush").font(.system(size: 13, weight: .semibold))
                Text(hush.isEnabled ? "Bluetooth off when the lid closes" : "Paused")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 8)
            Toggle("Enabled", isOn: $hush.isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
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
        .padding(.top, 10)
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
