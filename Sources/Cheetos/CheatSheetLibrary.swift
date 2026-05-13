import Foundation
import SwiftUI
import AppKit

struct CheatSheet: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL
    let isUserProvided: Bool
    let content: String

    static func load(id: String, title: String, url: URL, isUserProvided: Bool) -> CheatSheet {
        let body = (try? String(contentsOf: url, encoding: .utf8)) ?? "Failed to load \(title)."
        return CheatSheet(id: id, title: title, url: url, isUserProvided: isUserProvided, content: body)
    }
}

struct IndexedCommand: Hashable {
    let sheetID: String
    let sheetTitle: String
    let key: String
    let desc: String
}

@MainActor
final class CheatSheetLibrary: ObservableObject {
    @Published private(set) var sheets: [CheatSheet] = []
    @Published private(set) var commandIndex: [IndexedCommand] = []
    @Published private(set) var hiddenSheetIDs: Set<String> = []

    /// User-editable directory at ~/.cheetos.
    let userDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cheetos", isDirectory: true)

    private var watcher: DispatchSourceFileSystemObject?
    private var watchFD: Int32 = -1

    private let usageKey = "cheetos.sheetUsageCounts"
    private let lastSheetKey = "cheetos.lastSheetID"
    private let hiddenKey = "cheetos.hiddenSheetIDs"

    /// Sheets that aren't hidden. The sidebar, search, and command index use this.
    var visibleSheets: [CheatSheet] {
        sheets.filter { !hiddenSheetIDs.contains($0.id) }
    }

    func isHidden(_ id: String) -> Bool {
        hiddenSheetIDs.contains(id)
    }

    func setHidden(_ id: String, hidden: Bool) {
        if hidden {
            hiddenSheetIDs.insert(id)
        } else {
            hiddenSheetIDs.remove(id)
        }
        persistHidden()
        buildCommandIndex()
    }

    func toggleHidden(_ id: String) {
        setHidden(id, hidden: !isHidden(id))
    }

    private func loadHidden() {
        let arr = UserDefaults.standard.stringArray(forKey: hiddenKey) ?? []
        hiddenSheetIDs = Set(arr)
    }

    private func persistHidden() {
        UserDefaults.standard.set(Array(hiddenSheetIDs), forKey: hiddenKey)
    }

    var lastSheetID: String? {
        get { UserDefaults.standard.string(forKey: lastSheetKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastSheetKey) }
    }

    private var usageCounts: [String: Int] {
        get { (UserDefaults.standard.dictionary(forKey: usageKey) as? [String: Int]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: usageKey) }
    }

    func usage(for sheetID: String) -> Int {
        usageCounts[sheetID] ?? 0
    }

    func recordUse(of sheetID: String) {
        var counts = usageCounts
        counts[sheetID, default: 0] += 1
        usageCounts = counts
        lastSheetID = sheetID
    }

    init() {
        ensureUserDirectory()
        loadHidden()
        load()
        startWatching()
    }

    deinit {
        watcher?.cancel()
        if watchFD >= 0 { close(watchFD) }
    }

    // MARK: Loading

    func load() {
        var byId: [String: CheatSheet] = [:]

        // 1. Bundled defaults (read-only)
        if let bundledDir = Bundle.module.url(forResource: "cheatsheets", withExtension: nil) {
            for url in (try? FileManager.default.contentsOfDirectory(at: bundledDir, includingPropertiesForKeys: nil)) ?? [] {
                guard url.pathExtension.lowercased() == "md" else { continue }
                let id = url.deletingPathExtension().lastPathComponent
                byId[id] = CheatSheet.load(
                    id: id,
                    title: Self.title(from: id),
                    url: url,
                    isUserProvided: false
                )
            }
        }

        // 2. User sheets (override bundled if same id)
        for url in (try? FileManager.default.contentsOfDirectory(at: userDirectory, includingPropertiesForKeys: nil)) ?? [] {
            guard url.pathExtension.lowercased() == "md" else { continue }
            let id = url.deletingPathExtension().lastPathComponent
            byId[id] = CheatSheet.load(
                id: id,
                title: Self.title(from: id),
                url: url,
                isUserProvided: true
            )
        }

        sheets = byId.values.sorted { a, b in
            let aN = usage(for: a.id)
            let bN = usage(for: b.id)
            if aN != bN { return aN > bN }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
        buildCommandIndex()
    }

    private func buildCommandIndex() {
        var index: [IndexedCommand] = []
        for sheet in sheets where !hiddenSheetIDs.contains(sheet.id) {
            let blocks = MarkdownBlock.parse(sheet.content)
            for block in blocks {
                if case .keyRow(let key, let desc) = block {
                    index.append(IndexedCommand(
                        sheetID: sheet.id,
                        sheetTitle: sheet.title,
                        key: key,
                        desc: desc
                    ))
                }
            }
        }
        commandIndex = index
    }

    /// Best matching command across all sheets for the given query.
    /// Prefers key matches over description matches.
    func topMatch(for rawQuery: String) -> IndexedCommand? {
        let q = rawQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return nil }
        if let m = commandIndex.first(where: { $0.key.lowercased().contains(q) }) { return m }
        return commandIndex.first(where: { $0.desc.lowercased().contains(q) })
    }

    private static func title(from id: String) -> String {
        id.replacingOccurrences(of: "-", with: " ")
          .replacingOccurrences(of: "_", with: " ")
          .capitalized
    }

    // MARK: Directory + file watcher

    func ensureUserDirectory() {
        try? FileManager.default.createDirectory(
            at: userDirectory,
            withIntermediateDirectories: true
        )
    }

    private func startWatching() {
        watchFD = open(userDirectory.path, O_EVTONLY)
        guard watchFD >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: watchFD,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )
        src.setEventHandler { [weak self] in self?.load() }
        src.setCancelHandler { [weak self] in
            if let fd = self?.watchFD, fd >= 0 { close(fd) }
            self?.watchFD = -1
        }
        src.resume()
        watcher = src
    }

    // MARK: User actions

    enum CreateError: LocalizedError {
        case emptyName
        case alreadyExists
        case writeFailed(Error)
        var errorDescription: String? {
            switch self {
            case .emptyName: return "Name can't be empty."
            case .alreadyExists: return "A sheet with that name already exists."
            case .writeFailed(let e): return "Couldn't create file: \(e.localizedDescription)"
            }
        }
    }

    /// Sanitize the given name into a valid sheet id.
    static func sanitize(name: String) -> String {
        var s = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.lowercased().hasSuffix(".md") { s = String(s.dropLast(3)) }
        s = s.replacingOccurrences(of: "/", with: "-")
             .replacingOccurrences(of: "\\", with: "-")
             .replacingOccurrences(of: ":", with: "-")
        return s
    }

    func createSheet(named rawName: String) -> Result<URL, CreateError> {
        ensureUserDirectory()
        let name = Self.sanitize(name: rawName)
        guard !name.isEmpty else { return .failure(.emptyName) }
        let url = userDirectory.appendingPathComponent("\(name).md")
        if FileManager.default.fileExists(atPath: url.path) {
            return .failure(.alreadyExists)
        }
        let title = Self.title(from: name)
        let stub = """
        # \(title)

        ## Section
        - `command` — description
        - `another` — does something else

        ## Tips
        - Plain bullet line
        - Use backticks for `inline code`

        ```
        # fenced code blocks render with monospace + copy button
        echo "hello"
        ```
        """
        do {
            try stub.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(url)
            return .success(url)
        } catch {
            return .failure(.writeFailed(error))
        }
    }

    func revealUserDirectory() {
        ensureUserDirectory()
        NSWorkspace.shared.activateFileViewerSelecting([userDirectory])
    }

    func reveal(_ sheet: CheatSheet) {
        guard sheet.isUserProvided else {
            revealUserDirectory()
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([sheet.url])
    }

    func openInEditor(_ sheet: CheatSheet) {
        NSWorkspace.shared.open(sheet.url)
    }

    /// Copy a bundled sheet into ~/.cheetos so the user can edit it. No-op if a user copy exists.
    @discardableResult
    func overrideBundled(_ sheet: CheatSheet) -> URL? {
        guard !sheet.isUserProvided else { return sheet.url }
        ensureUserDirectory()
        let dest = userDirectory.appendingPathComponent("\(sheet.id).md")
        if FileManager.default.fileExists(atPath: dest.path) {
            NSWorkspace.shared.open(dest)
            return dest
        }
        let content = sheet.content
        do {
            try content.write(to: dest, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(dest)
            return dest
        } catch {
            NSLog("Failed to override sheet: \(error)")
            return nil
        }
    }

    @discardableResult
    func delete(_ sheet: CheatSheet) -> Bool {
        guard sheet.isUserProvided else { return false }
        do {
            try FileManager.default.trashItem(at: sheet.url, resultingItemURL: nil)
            return true
        } catch {
            NSLog("Failed to trash \(sheet.url.path): \(error)")
            return false
        }
    }
}
