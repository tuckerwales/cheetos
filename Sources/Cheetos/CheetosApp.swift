import SwiftUI
import AppKit
import Combine

@main
struct CheetosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No SwiftUI scenes — AppDelegate manages all windows directly so this
        // LSUIElement app can show its panel and settings window reliably.
        Settings { EmptyView() }
    }
}

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel!
    private let library = CheatSheetLibrary()
    let settings = SettingsStore()
    private let hotkey = HotkeyManager.shared
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildStatusItem()
        buildPanel()
        setupHotkey()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: .openCheetosSettings,
            object: nil
        )

        // macOS may restore the empty SwiftUI Settings window from a previous
        // session. Close anything that isn't our panel and mark it
        // non-restorable so it doesn't reappear next launch.
        closeStrayWindows()
        DispatchQueue.main.async { [weak self] in self?.closeStrayWindows() }
    }

    private func closeStrayWindows() {
        for window in NSApp.windows where window !== panel {
            window.isRestorable = false
            window.close()
        }
    }

    // MARK: Status item

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "doc.text.magnifyingglass",
                                accessibilityDescription: "Cheetos")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel(sender)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Cheetos", action: #selector(togglePanel(_:)), keyEquivalent: "")
            .target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Cheetos", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: Panel

    private func buildPanel() {
        let size = NSSize(width: 680, height: 640)
        panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = true
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let host = NSHostingController(
            rootView: ContentView()
                .environmentObject(library)
                .environmentObject(settings)
        )
        if #available(macOS 13.0, *) {
            host.sizingOptions = []
        }
        panel.contentViewController = host
        panel.setContentSize(size)
        panel.minSize = size
        host.view.wantsLayer = true
        host.view.layer?.cornerRadius = 12
        host.view.layer?.masksToBounds = true
        host.view.layer?.cornerCurve = .continuous
    }

    @objc func togglePanel(_ sender: Any?) {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            centerPanel()
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func centerPanel() {
        guard let screen = NSScreen.main else { panel.center(); return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    // MARK: Settings

    // Open the main panel and tell ContentView to switch to the inline settings page.
    @objc func openSettings() {
        if !panel.isVisible {
            togglePanel(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        }
        NotificationCenter.default.post(name: .openCheetosSettings, object: nil)
    }

    // MARK: Global hotkey

    private func setupHotkey() {
        hotkey.onTrigger = { [weak self] in
            self?.togglePanel(nil)
        }
        applyHotkey()

        settings.$hotkeyKeyCode
            .combineLatest(settings.$hotkeyModifiers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.applyHotkey() }
            .store(in: &cancellables)
    }

    private func applyHotkey() {
        hotkey.register(keyCode: settings.hotkeyKeyCode, modifiers: settings.modifierFlags)
    }
}
