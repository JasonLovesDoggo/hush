import IOKit
import IOKit.pwr_mgt

/// Watches the lid and system sleep through IOKit's power-management root domain.
///
/// Two signals, because either can arrive first: the clamshell message fires the
/// instant the lid moves, and the sleep notification lets us finish before the
/// Mac actually sleeps (we hold sleep until `onWillSleep` returns).
final class LidMonitor {
    enum Event { case closed(causesSleep: Bool), opened, willSleep, didWake }

    private let onEvent: (Event) -> Void
    private let rootDomain: io_service_t
    private var interestPort: IONotificationPortRef?
    private var interestNotifier: io_object_t = 0
    private var powerPort: IONotificationPortRef?
    private var powerNotifier: io_object_t = 0
    private var powerConnection: io_connect_t = 0

    // IOKit message macros don't import into Swift.
    private static let clamshellStateChange: UInt32 = 0xE003_4100 // kIOPMMessageClamshellStateChange
    private static let canSystemSleep: UInt32 = 0xE000_0270
    private static let systemWillSleep: UInt32 = 0xE000_0280
    private static let systemHasPoweredOn: UInt32 = 0xE000_0300

    init(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
        rootDomain = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        interestPort = IONotificationPortCreate(kIOMainPortDefault)
        IONotificationPortSetDispatchQueue(interestPort, .main)
        IOServiceAddInterestNotification(interestPort, rootDomain, kIOGeneralInterest, { refcon, _, type, arg in
            let state = UInt(bitPattern: arg)
            MainActor.assumeIsolated {
                Unmanaged<LidMonitor>.fromOpaque(refcon!).takeUnretainedValue().handleInterest(type, state)
            }
        }, refcon, &interestNotifier)

        powerConnection = IORegisterForSystemPower(refcon, &powerPort, { refcon, _, type, arg in
            MainActor.assumeIsolated {
                Unmanaged<LidMonitor>.fromOpaque(refcon!).takeUnretainedValue().handlePower(type, arg)
            }
        }, &powerNotifier)
        IONotificationPortSetDispatchQueue(powerPort, .main)
    }

    var isLidClosed: Bool { property("AppleClamshellState") }

    private func property(_ key: String) -> Bool {
        let value = IORegistryEntryCreateCFProperty(rootDomain, key as CFString, kCFAllocatorDefault, 0)
        return (value?.takeRetainedValue() as? Bool) ?? false
    }

    private func handleInterest(_ type: UInt32, _ state: UInt) {
        guard type == Self.clamshellStateChange else { return }
        let closed = state & 1 != 0         // kClamshellStateBit
        let causesSleep = state & 2 != 0    // kClamshellSleepBit — false in clamshell mode with a display
        onEvent(closed ? .closed(causesSleep: causesSleep) : .opened)
    }

    private func handlePower(_ type: UInt32, _ arg: UnsafeMutableRawPointer?) {
        switch type {
        case Self.canSystemSleep:
            IOAllowPowerChange(powerConnection, Int(bitPattern: arg))
        case Self.systemWillSleep:
            onEvent(.willSleep)
            IOAllowPowerChange(powerConnection, Int(bitPattern: arg))
        case Self.systemHasPoweredOn:
            onEvent(.didWake)
        default: break
        }
    }
}
