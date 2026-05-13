import SwiftUI
import AppKit

// MARK: - Tool metadata (icon + accent color)

struct ToolMeta {
    let symbol: String
    let tint: Color
}

enum BrandAssets {
    static let logo: NSImage? = {
        if let url = Bundle.main.url(forResource: "Logo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let url = Bundle.module.url(forResource: "Logo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return nil
    }()
}

struct LogoWatermark: View {
    var size: CGFloat = 140
    var opacity: Double = 0.10

    var body: some View {
        if let logo = BrandAssets.logo {
            Image(nsImage: logo)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(opacity)
                .allowsHitTesting(false)
        }
    }
}

enum ToolCatalog {
    static func meta(for id: String) -> ToolMeta {
        switch id.lowercased() {
        case "vim", "neovim", "nvim":
            return ToolMeta(symbol: "v.square.fill", tint: .green)
        case "tmux":
            return ToolMeta(symbol: "rectangle.split.3x1.fill", tint: .teal)
        case "git":
            return ToolMeta(symbol: "arrow.triangle.branch", tint: .orange)
        case "docker":
            return ToolMeta(symbol: "shippingbox.fill", tint: .blue)
        case "kubernetes", "kubectl", "k8s":
            return ToolMeta(symbol: "helm", tint: .indigo)
        case "bash", "zsh", "shell":
            return ToolMeta(symbol: "terminal.fill", tint: .gray)
        case "ssh":
            return ToolMeta(symbol: "key.fill", tint: .yellow)
        case "make":
            return ToolMeta(symbol: "hammer.fill", tint: .brown)
        default:
            return ToolMeta(symbol: "doc.text.fill", tint: .accentColor)
        }
    }
}

// MARK: - Root

struct ContentView: View {
    @EnvironmentObject var library: CheatSheetLibrary
    @State private var selection: CheatSheet.ID?
    @State private var search: String = ""
    @State private var showingSettings: Bool = false
    @State private var creatingNewSheet: Bool = false
    @State private var newSheetName: String = ""
    @State private var newSheetErrorMessage: String?
    @FocusState private var searchFocused: Bool
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            searchHeader
            quickActionBanner
            Divider().opacity(0.5)
            if library.visibleSheets.isEmpty && !showingSettings {
                emptyState
            } else {
                HStack(spacing: 0) {
                    sidebar
                        .frame(width: 200)
                        .background(Color.primary.opacity(0.04))
                    Divider().opacity(0.5)
                    detail
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            Divider().opacity(0.5)
            footer
        }
        .background(VisualEffect(material: .windowBackground, blending: .behindWindow))
        .onAppear {
            if selection == nil {
                if let last = library.lastSheetID,
                   library.visibleSheets.contains(where: { $0.id == last }) {
                    selection = last
                } else {
                    selection = filtered.first?.id ?? library.visibleSheets.first?.id
                }
            }
            searchFocused = true
            installKeyMonitor()
        }
        .onDisappear { removeKeyMonitor() }
        .onReceive(NotificationCenter.default.publisher(for: .openCheetosSettings)) { _ in
            showingSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .startNewSheet)) { _ in
            beginNewSheet()
        }
        .alert("New cheat sheet", isPresented: $creatingNewSheet) {
            TextField("Name (e.g. docker)", text: $newSheetName)
                .textContentType(.none)
            Button("Create") { commitNewSheet() }
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) { newSheetName = "" }
        } message: {
            Text("A new file will be created in ~/.cheetos and opened in your editor.")
        }
        .alert(
            "Couldn't create sheet",
            isPresented: Binding(
                get: { newSheetErrorMessage != nil },
                set: { if !$0 { newSheetErrorMessage = nil } }
            )
        ) {
            Button("Try Again") { beginNewSheet() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(newSheetErrorMessage ?? "")
        }
        .onChange(of: search) { _, _ in
            let inFiltered = selection.map { id in filtered.contains(where: { $0.id == id }) } ?? false
            if !inFiltered {
                selection = filtered.first?.id
            }
        }
    }

    // MARK: Quick-action banner

    @ViewBuilder
    private var quickActionBanner: some View {
        if !search.isEmpty, let match = library.topMatch(for: search) {
            Button {
                performQuickAction(match: match)
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                        Image(systemName: "return")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 18, height: 18)
                    Text("Copy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(match.key)
                        .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                    Text("— \(match.desc)")
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                    Text(match.sheetTitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.08)))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.10))
            }
            .buttonStyle(.plain)
            .help("Press ↩ to copy and close")
        }
    }

    private func performQuickAction(match: IndexedCommand? = nil) {
        let match = match ?? library.topMatch(for: search)
        guard let m = match else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(m.key, forType: .string)
        library.recordUse(of: m.sheetID)
        search = ""
        closeWindow()
    }

    // MARK: Drag handle

    private var dragHandle: some View {
        WindowDragArea()
            .frame(height: 8)
    }

    // MARK: Header

    private var searchHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13, weight: .medium))
            TextField("Search cheat sheets", text: $search)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($searchFocused)
                .onSubmit { performQuickAction() }
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: Sidebar

    private var filtered: [CheatSheet] {
        let base = library.visibleSheets
        guard !search.isEmpty else { return base }
        let q = search.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q) || $0.content.lowercased().contains(q)
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, sheet in
                        SidebarRow(
                            sheet: sheet,
                            isSelected: !showingSettings && selection == sheet.id,
                            shortcutHint: idx < 9 ? "⌘\(idx + 1)" : nil
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selection = sheet.id
                            showingSettings = false
                            library.recordUse(of: sheet.id)
                        }
                        .contextMenu {
                            if sheet.isUserProvided {
                                Button("Edit in Editor") { library.openInEditor(sheet) }
                                Button("Reveal in Finder") { library.reveal(sheet) }
                                Divider()
                                Button("Hide Sheet") {
                                    hide(sheet)
                                }
                                Button("Move to Trash", role: .destructive) {
                                    library.delete(sheet)
                                }
                            } else {
                                Button("Override with Custom Copy") {
                                    library.overrideBundled(sheet)
                                }
                                Button("Reveal Folder in Finder") {
                                    library.revealUserDirectory()
                                }
                                Divider()
                                Button("Hide Sheet") {
                                    hide(sheet)
                                }
                            }
                        }
                    }
                    newSheetRow
                }
                .padding(8)
            }
            Divider().opacity(0.4)
            settingsSidebarRow
                .padding(8)
        }
    }

    private var newSheetRow: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(.secondary.opacity(0.4))
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 22, height: 22)
            Text("New sheet")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { beginNewSheet() }
        .help("Create a new cheat sheet in ~/.cheetos")
    }

    private var footerCountLabel: String {
        let shown = filtered.count
        let visible = library.visibleSheets.count
        let hidden = library.sheets.count - visible
        let base = "\(shown) of \(visible)"
        return hidden > 0 ? "\(base) · \(hidden) hidden" : base
    }

    private func hide(_ sheet: CheatSheet) {
        library.setHidden(sheet.id, hidden: true)
        if selection == sheet.id {
            selection = filtered.first?.id
        }
    }

    private func beginNewSheet() {
        showingSettings = false
        newSheetName = ""
        newSheetErrorMessage = nil
        creatingNewSheet = true
    }

    private func commitNewSheet() {
        let nameToCreate = newSheetName
        newSheetName = ""
        switch library.createSheet(named: nameToCreate) {
        case .success(let url):
            let id = url.deletingPathExtension().lastPathComponent
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                selection = id
            }
        case .failure(let err):
            newSheetName = nameToCreate
            newSheetErrorMessage = err.errorDescription
        }
    }

    private var settingsSidebarRow: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(showingSettings ? 0.9 : 0.18))
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(showingSettings ? Color.white : .secondary)
            }
            .frame(width: 22, height: 22)

            Text("Settings")
                .font(.system(size: 13, weight: showingSettings ? .semibold : .regular))
            Spacer(minLength: 0)
            Text("⌘,")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(showingSettings ? Color.primary.opacity(0.10) : Color.clear)
        )
        .onTapGesture { showingSettings.toggle() }
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        if showingSettings {
            SettingsPage()
        } else if let id = selection, let sheet = library.sheets.first(where: { $0.id == id }) {
            CheatSheetView(sheet: sheet, highlight: search, onHide: { hide(sheet) })
                .id(sheet.id)
        } else {
            VStack(spacing: 10) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 64, height: 64)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                VStack(spacing: 3) {
                    Text("No matches")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Try a different search, or press ⎋ to clear.")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Empty / footer

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            LogoWatermark(size: 88, opacity: 1.0)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)

            VStack(spacing: 4) {
                Text(library.sheets.isEmpty ? "Welcome to Cheetos" : "All sheets are hidden")
                    .font(.system(size: 17, weight: .semibold))
                Text(library.sheets.isEmpty
                     ? "Drop .md files into ~/.cheetos, or create one to get started."
                     : "Turn some back on in Settings to bring them back.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            Button {
                if library.sheets.isEmpty {
                    NotificationCenter.default.post(name: .startNewSheet, object: nil)
                } else {
                    showingSettings = true
                }
            } label: {
                Label(library.sheets.isEmpty ? "New Sheet" : "Open Settings",
                      systemImage: library.sheets.isEmpty ? "plus" : "gearshape")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text(footerCountLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            ShortcutHint(keys: "↑↓", label: "navigate")
            ShortcutHint(keys: "⌘F", label: "search")
            ShortcutHint(keys: "esc", label: "close")
            Button {
                NSApp.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    // MARK: Keyboard handling

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKey(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor {
            NSEvent.removeMonitor(m)
            keyMonitor = nil
        }
    }

    // Return true if the event was consumed.
    private func handleKey(_ event: NSEvent) -> Bool {
        // Let any presented alert handle keys natively.
        if creatingNewSheet || newSheetErrorMessage != nil { return false }

        let cmd = event.modifierFlags.contains(.command)
        let chars = event.charactersIgnoringModifiers ?? ""

        // ⌘F → focus search
        if cmd && chars == "f" {
            searchFocused = true
            return true
        }

        // ⌘, → toggle inline settings
        if cmd && chars == "," {
            showingSettings.toggle()
            return true
        }

        // ⌘1..⌘9 → jump to filtered sheet
        if cmd, let n = Int(chars), (1...9).contains(n) {
            let list = filtered
            if n - 1 < list.count {
                selection = list[n - 1].id
                showingSettings = false
                library.recordUse(of: list[n - 1].id)
                return true
            }
            return false
        }

        switch event.keyCode {
        case 53: // Esc
            if showingSettings {
                showingSettings = false
            } else if !search.isEmpty {
                search = ""
            } else {
                closeWindow()
            }
            return true
        case 125: // Down
            moveSelection(by: 1)
            return true
        case 126: // Up
            moveSelection(by: -1)
            return true
        default:
            return false
        }
    }

    private func moveSelection(by delta: Int) {
        let list = filtered
        guard !list.isEmpty else { return }
        let currentIdx = list.firstIndex { $0.id == selection } ?? -1
        let newIdx = max(0, min(list.count - 1, currentIdx + delta))
        let newID = list[newIdx].id
        selection = newID
        showingSettings = false
        library.recordUse(of: newID)
    }

    private func closeWindow() {
        // Close the MenuBarExtra popover by ending its window's key state.
        for window in NSApp.windows where window.isVisible {
            window.resignKey()
            window.orderOut(nil)
        }
    }
}

// MARK: - Sidebar row

private struct SidebarRow: View {
    let sheet: CheatSheet
    let isSelected: Bool
    let shortcutHint: String?
    @State private var hovering = false

    var body: some View {
        let meta = ToolCatalog.meta(for: sheet.id)
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(meta.tint.opacity(isSelected ? 0.9 : 0.18))
                Image(systemName: meta.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : meta.tint)
            }
            .frame(width: 22, height: 22)

            Text(sheet.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            if let hint = shortcutHint, (isSelected || hovering) {
                Text(hint)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.08))
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected
                      ? Color.primary.opacity(0.10)
                      : (hovering ? Color.primary.opacity(0.05) : Color.clear))
        )
        .onHover { hovering = $0 }
    }
}

// MARK: - Detail view

struct CheatSheetView: View {
    let sheet: CheatSheet
    let highlight: String
    let onHide: () -> Void
    @EnvironmentObject var library: CheatSheetLibrary
    @State private var confirmDelete = false

    private struct SectionRef: Identifiable, Hashable {
        let id: String   // anchor id used by ScrollViewReader
        let title: String
    }

    var body: some View {
        let blocks = MarkdownBlock.parse(sheet.content)
        let sections: [SectionRef] = blocks.enumerated().compactMap { idx, b in
            if case .section(let s) = b { return SectionRef(id: "section-\(idx)", title: s) }
            return nil
        }

        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                stickyHeader(sections: sections, proxy: proxy)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(blocks.enumerated()), id: \.offset) { idx, block in
                            block.view(highlight: highlight)
                                .id("block-\(idx)")
                                .modifier(SectionAnchorModifier(idx: idx, block: block))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                }
            }
        }
    }

    private func stickyHeader(sections: [SectionRef], proxy: ScrollViewProxy) -> some View {
        let meta = ToolCatalog.meta(for: sheet.id)
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(meta.tint.gradient)
                Image(systemName: meta.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)

            Text(sheet.title)
                .font(.system(size: 20, weight: .bold))
            if sheet.isUserProvided {
                Text("Custom")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.08))
                    )
            }
            Spacer()
            if sections.count > 1 {
                Menu {
                    ForEach(sections) { section in
                        Button(section.title) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(section.id, anchor: .top)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet.indent")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Jump to section")
            }
            Button(action: onHide) {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Hide this sheet")
            if sheet.isUserProvided {
                Button {
                    library.openInEditor(sheet)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Edit in your default editor")
                Button {
                    library.reveal(sheet)
                } label: {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
                Button {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Move to Trash")
            }
        }
        .alert("Delete “\(sheet.title)”?", isPresented: $confirmDelete) {
            Button("Move to Trash", role: .destructive) {
                library.delete(sheet)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The file will be moved to the Trash. You can restore it from there.")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            // Subtle fade so content scrolling beneath doesn't visually collide with the title
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
}

// MARK: - Section anchor (for scroll-to-section)

private struct SectionAnchorModifier: ViewModifier {
    let idx: Int
    let block: MarkdownBlock

    func body(content: Content) -> some View {
        if case .section = block {
            content.id("section-\(idx)")
        } else {
            content
        }
    }
}

// MARK: - Markdown parsing & rendering

enum MarkdownBlock {
    case section(String)
    case subsection(String)
    case quote(String)
    case keyRow(key: String, desc: String)
    case bullet(String)
    case code(String)
    case text(String)
    case spacer

    static func parse(_ content: String) -> [MarkdownBlock] {
        var out: [MarkdownBlock] = []
        var inFence = false
        var fenceBuf: [String] = []
        var skippedTitle = false

        for raw in content.components(separatedBy: "\n") {
            if raw.hasPrefix("```") {
                if inFence {
                    out.append(.code(fenceBuf.joined(separator: "\n")))
                    fenceBuf.removeAll()
                    inFence = false
                } else {
                    inFence = true
                }
                continue
            }
            if inFence {
                fenceBuf.append(raw)
                continue
            }

            if raw.hasPrefix("# ") {
                if !skippedTitle {
                    skippedTitle = true
                    continue
                }
                out.append(.section(String(raw.dropFirst(2))))
            } else if raw.hasPrefix("## ") {
                out.append(.section(String(raw.dropFirst(3))))
            } else if raw.hasPrefix("### ") {
                out.append(.subsection(String(raw.dropFirst(4))))
            } else if raw.hasPrefix("> ") {
                out.append(.quote(String(raw.dropFirst(2))))
            } else if raw.hasPrefix("- ") || raw.hasPrefix("* ") {
                let body = String(raw.dropFirst(2))
                if let row = parseKeyRow(body) {
                    out.append(.keyRow(key: row.0, desc: row.1))
                } else {
                    out.append(.bullet(body))
                }
            } else if raw.trimmingCharacters(in: .whitespaces).isEmpty {
                out.append(.spacer)
            } else {
                out.append(.text(raw))
            }
        }
        if inFence && !fenceBuf.isEmpty {
            out.append(.code(fenceBuf.joined(separator: "\n")))
        }
        return out
    }

    private static func parseKeyRow(_ s: String) -> (String, String)? {
        guard s.hasPrefix("`") else { return nil }
        let rest = s.dropFirst()
        guard let endBacktick = rest.firstIndex(of: "`") else { return nil }
        let key = String(rest[..<endBacktick])
        var tail = rest[rest.index(after: endBacktick)...]
            .trimmingCharacters(in: .whitespaces)
        for sep in ["—", "–", "-", ":"] {
            if tail.hasPrefix(sep) {
                tail = String(tail.dropFirst(sep.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        if tail.isEmpty || key.isEmpty { return nil }
        return (key, tail)
    }

    @ViewBuilder
    func view(highlight: String) -> some View {
        switch self {
        case .section(let s):
            VStack(alignment: .leading, spacing: 6) {
                InlineText(s, highlight: highlight)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.9)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
            }
            .padding(.top, 4)

        case .subsection(let s):
            InlineText(s, highlight: highlight)
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 4)

        case .quote(let s):
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.6))
                    .frame(width: 3)
                InlineText(s, highlight: highlight)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)

        case .keyRow(let key, let desc):
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                CopyableKeyPill(text: key, highlight: highlight)
                InlineText(desc, highlight: highlight)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary.opacity(0.9))
                Spacer(minLength: 0)
            }

        case .bullet(let s):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("•").foregroundStyle(.secondary)
                InlineText(s, highlight: highlight)
                    .font(.system(size: 13))
                Spacer(minLength: 0)
            }

        case .code(let s):
            CopyableCodeBlock(text: s)

        case .text(let s):
            InlineText(s, highlight: highlight)
                .font(.system(size: 13))

        case .spacer:
            Spacer().frame(height: 2)
        }
    }
}

// MARK: - Copyable command pill

private struct CopyableKeyPill: View {
    let text: String
    let highlight: String
    @State private var copied = false
    @State private var hovering = false

    var body: some View {
        Button(action: copy) {
            Text(copied ? "Copied" : text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(copied ? Color.green : .primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(copied
                              ? Color.green.opacity(0.18)
                              : (hovering ? Color.primary.opacity(0.14) : Color.primary.opacity(0.08)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(copied ? Color.green.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
                )
                .overlay(alignment: .center) {
                    if !highlight.isEmpty,
                       text.range(of: highlight, options: .caseInsensitive) != nil {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.yellow.opacity(0.9), lineWidth: 1.5)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .animation(.easeInOut(duration: 0.15), value: copied)
                .animation(.easeInOut(duration: 0.1), value: hovering)
        }
        .buttonStyle(.plain)
        .help("Click to copy “\(text)”")
        .onHover { hovering = $0 }
    }

    private func copy() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            copied = false
        }
    }
}

// MARK: - Copyable fenced code block

private struct CopyableCodeBlock: View {
    let text: String
    @State private var copied = false
    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(text)
                .font(.system(size: 12.5, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            if hovering || copied {
                Button(action: copy) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied" : "Copy")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(copied ? Color.green : .secondary)
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.12), value: hovering)
        .animation(.easeInOut(duration: 0.15), value: copied)
    }

    private func copy() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            copied = false
        }
    }
}

// MARK: - Shortcut hint chip

private struct ShortcutHint: View {
    let keys: String
    let label: String
    var body: some View {
        HStack(spacing: 3) {
            Text(keys)
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                )
            Text(label)
                .font(.system(size: 10))
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Inline text with `code` spans + search highlight

// MARK: - Window drag region

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DraggableNSView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DraggableNSView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}

// MARK: - NSVisualEffectView bridge

private struct VisualEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blending: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .active
        v.isEmphasized = true
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
        v.blendingMode = blending
    }
}

struct InlineText: View {
    private let segments: [Segment]
    private let highlight: String

    init(_ s: String, highlight: String) {
        self.segments = Self.tokenize(s)
        self.highlight = highlight
    }

    var body: some View {
        segments.reduce(Text("")) { acc, seg in
            acc + seg.render(highlight: highlight)
        }
    }

    enum Segment {
        case plain(String)
        case code(String)

        func render(highlight: String) -> Text {
            switch self {
            case .plain(let s):
                return highlighted(s, q: highlight, mono: false)
            case .code(let s):
                return highlighted(s, q: highlight, mono: true)
            }
        }

        private func highlighted(_ s: String, q: String, mono: Bool) -> Text {
            func styled(_ piece: String, hit: Bool) -> Text {
                var t = Text(piece)
                if mono {
                    t = t.font(.system(size: 12.5, weight: .medium, design: .monospaced))
                }
                if hit {
                    t = t.bold().foregroundStyle(Color.yellow)
                } else if mono {
                    t = t.foregroundStyle(.primary)
                }
                return t
            }

            guard !q.isEmpty else { return styled(s, hit: false) }
            var result = Text("")
            var remainder = s[...]
            while let range = remainder.range(of: q, options: .caseInsensitive) {
                let before = String(remainder[..<range.lowerBound])
                let match = String(remainder[range])
                if !before.isEmpty { result = result + styled(before, hit: false) }
                result = result + styled(match, hit: true)
                remainder = remainder[range.upperBound...]
            }
            if !remainder.isEmpty { result = result + styled(String(remainder), hit: false) }
            return result
        }
    }

    private static func tokenize(_ s: String) -> [Segment] {
        var segs: [Segment] = []
        let parts = s.components(separatedBy: "`")
        for (i, p) in parts.enumerated() {
            if p.isEmpty { continue }
            if i % 2 == 1 {
                segs.append(.code(p))
            } else {
                segs.append(.plain(p))
            }
        }
        return segs
    }
}
