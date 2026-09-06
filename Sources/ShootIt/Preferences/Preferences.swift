import AppKit
import Combine
import Foundation

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private enum Key {
        static let hotKeyCode = "hotKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
        static let ideaFolderPath = "ideaFolderPath"
        static let defaultColor = "defaultColor"
        static let defaultLineWidth = "defaultLineWidth"
        static let closeAfterCopy = "closeAfterCopy"
    }

    @Published var hotKeyCode: UInt32 { didSet { defaults.set(Int(hotKeyCode), forKey: Key.hotKeyCode) } }
    @Published var hotKeyModifiers: UInt32 { didSet { defaults.set(Int(hotKeyModifiers), forKey: Key.hotKeyModifiers) } }
    @Published var ideaFolderURL: URL { didSet { defaults.set(ideaFolderURL.path, forKey: Key.ideaFolderPath) } }
    @Published var defaultColor: RGBAColor { didSet { saveColor() } }
    @Published var defaultLineWidth: CGFloat { didSet { defaults.set(Double(defaultLineWidth), forKey: Key.defaultLineWidth) } }
    @Published var closeAfterCopy: Bool { didSet { defaults.set(closeAfterCopy, forKey: Key.closeAfterCopy) } }

    private let defaults = UserDefaults.standard

    private init() {
        hotKeyCode = UInt32(defaults.object(forKey: Key.hotKeyCode) as? Int ?? 18) // 1
        hotKeyModifiers = UInt32(defaults.object(forKey: Key.hotKeyModifiers) as? Int ?? 768) // cmd + shift
        let defaultIdeas = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Screenshot Ideas", isDirectory: true)
        ideaFolderURL = URL(fileURLWithPath: defaults.string(forKey: Key.ideaFolderPath) ?? defaultIdeas.path)
        if let data = defaults.data(forKey: Key.defaultColor),
           let decoded = try? JSONDecoder().decode(RGBAColor.self, from: data) {
            defaultColor = decoded
        } else {
            defaultColor = .yellow
        }
        let storedWidth = defaults.double(forKey: Key.defaultLineWidth)
        defaultLineWidth = storedWidth == 0 ? 4 : storedWidth
        closeAfterCopy = defaults.object(forKey: Key.closeAfterCopy) as? Bool ?? true
    }

    func chooseIdeaFolder() {
        let panel = NSOpenPanel()
        panel.title = "Ordner für Ideen wählen"
        panel.prompt = "Wählen"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = ideaFolderURL
        if panel.runModal() == .OK, let url = panel.url {
            ideaFolderURL = url
        }
    }

    private func saveColor() {
        if let data = try? JSONEncoder().encode(defaultColor) {
            defaults.set(data, forKey: Key.defaultColor)
        }
    }
}
