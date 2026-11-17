import CoreBluetooth
import IOBluetooth
import os

// Private IOBluetooth symbols — the same ones `blueutil` and Control Center use.
@_silgen_name("IOBluetoothPreferenceGetControllerPowerState")
private func IOBluetoothPreferenceGetControllerPowerState() -> Int32
@_silgen_name("IOBluetoothPreferenceSetControllerPowerState")
private func IOBluetoothPreferenceSetControllerPowerState(_ state: Int32)

let log = Logger(subsystem: "dev.jasoncameron.Hush", category: "app")

/// Owns the Bluetooth radio: power, live state, and reconnecting devices.
@Observable
final class Bluetooth: NSObject {
    enum Access { case unknown, granted, denied }

    private(set) var isOn = IOBluetoothPreferenceGetControllerPowerState() != 0
    private(set) var access: Access = .unknown

    private var central: CBCentralManager?
    private let connector = Connector()

    override init() {
        super.init()
        // Creating a central manager triggers the one-time permission prompt and
        // then streams power-state changes, so the menu is always truthful.
        // ShowPowerAlert=false stops macOS nagging "turn Bluetooth on" while we keep it off.
        central = CBCentralManager(
            delegate: self, queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
    }

    /// Reads the controller directly — `isOn` can lag a moment behind CoreBluetooth.
    var radioIsOn: Bool { IOBluetoothPreferenceGetControllerPowerState() != 0 }

    func setPower(_ on: Bool) {
        IOBluetoothPreferenceSetControllerPowerState(on ? 1 : 0)
        isOn = on
    }

    /// Addresses of devices connected right now.
    func connectedDevices() -> [String] {
        let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        return paired.filter { $0.isConnected() }.compactMap(\.addressString)
    }

    /// Powers on, waits for the controller to come up, then asks each device to reconnect.
    func powerOnAndReconnect(_ addresses: [String]) async {
        setPower(true)
        guard !addresses.isEmpty else { return }
        for _ in 0..<50 where IOBluetoothPreferenceGetControllerPowerState() == 0 {
            try? await Task.sleep(for: .milliseconds(100))
        }
        // Give the controller a beat after power-up; devices that auto-reconnect
        // (keyboards, trackpads) usually beat us here, which is fine.
        try? await Task.sleep(for: .seconds(1))
        for address in addresses {
            guard let device = IOBluetoothDevice(addressString: address), !device.isConnected() else { continue }
            log.notice("Reconnecting \(device.name ?? address, privacy: .public)")
            device.openConnection(connector)
        }
    }
}

extension Bluetooth: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: isOn = true; access = .granted
        case .poweredOff: isOn = false; access = .granted
        case .unauthorized: access = .denied
        default: break
        }
    }
}

/// Target for IOBluetooth's async `openConnection(_:)`, so reconnecting never blocks the UI.
private final class Connector: NSObject {
    @objc func connectionComplete(_ device: IOBluetoothDevice, status: IOReturn) {
        if status != kIOReturnSuccess {
            log.notice("Reconnect failed for \(device.name ?? "device", privacy: .public): \(status)")
        }
    }
}
