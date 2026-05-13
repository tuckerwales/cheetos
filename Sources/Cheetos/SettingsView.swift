import SwiftUI
import AppKit

// Inline settings "page" — rendered inside the main panel's detail area.
struct SettingsPage: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var library: CheatSheetLibrary

    var body: some View {
        VStack(spacing: 0) {
            stickyHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AboutHero()

                    section(title: "Your Cheat Sheets") {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                            Text(library.userDirectory.path
                                .replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            Button {
                                NotificationCenter.default.post(name: .startNewSheet, object: nil)
                            } label: {
                                Label("New Sheet…", systemImage: "plus")
                            }
                            Button {
                                library.revealUserDirectory()
                            } label: {
                                Label("Open Folder", systemImage: "arrow.up.forward.app")
                            }
                            Spacer()
                        }
                        .controlSize(.small)
                        Text("Drop `.md` files into this folder, or click **New Sheet…** to create one. The filename becomes the sheet's id; the title is generated from it (`docker-compose.md` → \"Docker Compose\"). Cheetos auto-reloads when files change.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    section(title: "Show / Hide Sheets") {
                        if library.sheets.isEmpty {
                            Text("No sheets yet. Create one above to get started.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(library.sheets.sorted {
                                    $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                                }) { sheet in
                                    SheetVisibilityRow(sheet: sheet)
                                }
                            }
                            HStack(spacing: 12) {
                                Button("Show All") {
                                    for s in library.sheets where library.isHidden(s.id) {
                                        library.setHidden(s.id, hidden: false)
                                    }
                                }
                                Button("Hide All") {
                                    for s in library.sheets where !library.isHidden(s.id) {
                                        library.setHidden(s.id, hidden: true)
                                    }
                                }
                                Spacer()
                            }
                            .controlSize(.small)
                            Text("Hidden sheets are removed from the sidebar, search, and the quick-action banner. Toggle them back on here any time.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    section(title: "General") {
                        SettingsRow(
                            title: "Open at login",
                            subtitle: settings.loginItemError ?? "Launch Cheetos automatically when you sign in.",
                            subtitleIsError: settings.loginItemError != nil
                        ) {
                            Toggle("", isOn: $settings.openAtLogin)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }

                    section(title: "Keyboard Shortcut") {
                        SettingsRow(
                            title: "Open Cheetos",
                            subtitle: "Set a global shortcut to toggle the window from anywhere. Requires at least one modifier (⌘ ⌥ ⌃ ⇧)."
                        ) {
                            ShortcutRecorder()
                        }
                    }

                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var stickyHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.gradient)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)

            Text("Settings")
                .font(.system(size: 20, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.primary.opacity(0.06), Color.primary.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.10))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.9)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct SettingsRow<Trailing: View>: View {
    let title: String
    let subtitle: String
    var subtitleIsError: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(subtitleIsError ? Color.red : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            trailing()
        }
    }
}

private struct AboutHero: View {
    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "v\(short) (\(build))"
    }

    var body: some View {
        HStack(spacing: 14) {
            AppIconView()
                .frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Cheetos")
                    .font(.system(size: 17, weight: .bold))
                Text("Quick cheat sheets, one click away.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(versionLabel)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.08))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.18),
                            Color.orange.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct AppIconView: View {
    var body: some View {
        if let icon = NSApp.applicationIconImage {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
        } else {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(Color.accentColor)
        }
    }
}

private struct SheetVisibilityRow: View {
    let sheet: CheatSheet
    @EnvironmentObject var library: CheatSheetLibrary
    @State private var hovering = false

    var body: some View {
        let meta = ToolCatalog.meta(for: sheet.id)
        let hidden = library.isHidden(sheet.id)
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(meta.tint.opacity(hidden ? 0.10 : 0.85))
                Image(systemName: meta.symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(hidden ? meta.tint.opacity(0.6) : .white)
            }
            .frame(width: 20, height: 20)

            Text(sheet.title)
                .font(.system(size: 13))
                .foregroundStyle(hidden ? .secondary : .primary)
            if sheet.isUserProvided {
                Text("Custom")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.08))
                    )
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { !library.isHidden(sheet.id) },
                set: { library.setHidden(sheet.id, hidden: !$0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hovering ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering = $0 }
    }
}

private struct ShortcutRecorder: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggle) {
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(textColor)
                    .frame(minWidth: 150)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(recording ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(recording ? Color.accentColor : Color.primary.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            if settings.hasShortcut && !recording {
                Button {
                    settings.hotkeyKeyCode = -1
                    settings.hotkeyModifiers = 0
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
        .onDisappear { stopRecording() }
    }

    private var label: String {
        if recording { return "Press keys… (esc cancels)" }
        if settings.hasShortcut {
            return HotkeyManager.displayString(
                keyCode: settings.hotkeyKeyCode,
                modifiers: settings.modifierFlags
            )
        }
        return "Click to record"
    }

    private var textColor: Color {
        if recording { return .accentColor }
        return settings.hasShortcut ? .primary : .secondary
    }

    private func toggle() {
        if recording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Esc
                stopRecording()
                return nil
            }
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            if !mods.isEmpty {
                settings.hotkeyKeyCode = Int(event.keyCode)
                settings.hotkeyModifiers = Int(mods.rawValue)
                stopRecording()
                return nil
            }
            return event
        }
    }

    private func stopRecording() {
        recording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
