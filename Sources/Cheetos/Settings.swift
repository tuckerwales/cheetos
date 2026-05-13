import SwiftUI
import AppKit
import Carbon.HIToolbox
import ServiceManagement

extension Notification.Name {
    static let openCheetosSettings = Notification.Name("openCheetosSettings")
    static let startNewSheet = Notification.Name("startNewSheet")
}

// MARK: - Persistent settings store

@MainActor
final class SettingsStore: ObservableObject {
    @Published var hotkeyKeyCode: Int {
        didSet { UserDefaults.standard.set(hotkeyKeyCode, forKey: "hotkeyKeyCode") }
    }
    @Published var hotkeyModifiers: Int {
        didSet { UserDefaults.standard.set(hotkeyModifiers, forKey: "hotkeyModifiers") }
    }
    @Published var openAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(openAtLogin, forKey: "openAtLogin")
            applyLoginItem()
        }
    }
    @Published var loginItemError: String?

    var hasShortcut: Bool { hotkeyKeyCode >= 0 }
    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: UInt(hotkeyModifiers))
    }

    init() {
        let d = UserDefaults.standard
        self.hotkeyKeyCode = (d.object(forKey: "hotkeyKeyCode") as? Int) ?? -1
        self.hotkeyModifiers = (d.object(forKey: "hotkeyModifiers") as? Int) ?? 0
        self.openAtLogin = d.bool(forKey: "openAtLogin")
    }

    private func applyLoginItem() {
        let service = SMAppService.mainApp
        do {
            if openAtLogin {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
    }
}

// MARK: - Global hotkey via Carbon

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onTrigger: (() -> Void)?

    func register(keyCode: Int, modifiers: NSEvent.ModifierFlags) {
        unregister()
        guard keyCode >= 0 else { return }
        let carbonMods = Self.carbonFlags(from: modifiers)
        guard carbonMods != 0 else { return } // require at least one modifier

        let hotKeyID = EventHotKeyID(signature: 0x43485453 /* 'CHTS' */, id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(keyCode),
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if registerStatus != noErr {
            NSLog("RegisterEventHotKey failed: \(registerStatus)")
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { manager.onTrigger?() }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    func unregister() {
        if let h = hotKeyRef { UnregisterEventHotKey(h); hotKeyRef = nil }
        if let e = eventHandler { RemoveEventHandler(e); eventHandler = nil }
    }

    static func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }

    static func displayString(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String {
        var s = ""
        if modifiers.contains(.control) { s += "⌃" }
        if modifiers.contains(.option)  { s += "⌥" }
        if modifiers.contains(.shift)   { s += "⇧" }
        if modifiers.contains(.command) { s += "⌘" }
        s += keyCodeToString(keyCode)
        return s
    }

    private static func keyCodeToString(_ keyCode: Int) -> String {
        let map: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P",
            37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            25: "9", 26: "7", 28: "8", 29: "0",
            27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'",
            42: "\\", 43: ",", 47: ".", 44: "/", 50: "`",
            49: "Space", 36: "↩", 51: "⌫", 53: "Esc", 48: "⇥",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4",
            96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        return map[keyCode] ?? "Key\(keyCode)"
    }
}
