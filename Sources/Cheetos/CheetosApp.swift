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

        // macOS may restore the empty SwiftUI Settings window from a previous
        // session. Close anything that isn't our panel and mark it
        // non-restorable so it doesn't reappear next launch.
        closeStrayWindows()
        DispatchQueue.main.async { [weak self] in self?.closeStrayWindows() }
    }

    private func closeStrayWindows() {
        // Close only normal-level windows (e.g. SwiftUI's auto-restored
        // empty Settings window). Skip the status-bar item's hosting window
        // (level .statusBar) and our panel (level .floating).
        for window in NSApp.windows where window !== panel && window.level == .normal {
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
            button.action = #selector(togglePanel(_:))
            // Fire on mouse-down. With the default (.leftMouseUp), the first
            // click after the app goes to background can get absorbed by the
            // OS activating the app and never reach our action.
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
    }

    // MARK: Panel

    private func buildPanel() {
        let size = NSSize(width: 900, height: 680)
        panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .resizable],
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

        // Make sure isVisible is firmly false before the user can interact.
        // Without this, the first status-item click sometimes hits the
        // orderOut branch of togglePanel and the panel stays hidden.
        panel.orderOut(nil)
    }

    @objc func togglePanel(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseDown {
            showStatusMenu()
            return
        }
        let isShown = panel.isVisible && panel.occlusionState.contains(.visible)
        if isShown {
            panel.orderOut(nil)
            return
        }
        centerPanel()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func showStatusMenu() {
        let menu = NSMenu()

        let open = NSMenuItem(title: "Open Cheetos", action: #selector(togglePanel(_:)), keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        let prefs = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Cheetos",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        // Temporarily attach the menu; clicking the button now shows it.
        // performClick presents it anchored to the status item, then we
        // detach so left-click reverts to the action selector.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
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
