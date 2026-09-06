import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class EditorWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var store: EditorStore?

    func allowNewCapture() -> Bool {
        guard window != nil else { return true }
        guard confirmDiscardIfNeeded() else { return false }
        closeWithoutPrompt()
        return true
    }

    func show(document: ScreenshotDocument) {
        closeWithoutPrompt()

        let store = EditorStore(document: document)
        let actions = EditorActions(
            copy: { [weak self] in self?.copyResult() },
            save: { [weak self] in self?.saveResult() },
            archiveIdea: { [weak self] in self?.archiveIdea() },
            discard: { [weak self] in self?.discard() }
        )
        let rootView = EditorView(store: store, actions: actions)
        let hosting = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Shoot It"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.setContentSize(CGSize(width: 1040, height: 680))
        window.minSize = CGSize(width: 760, height: 500)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.store = store
        self.window = window
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        confirmDiscardIfNeeded()
    }

    private func copyResult() {
        guard let store else { return }
        do {
            let image = try DocumentRenderer.render(store.document)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([NSImage(cgImage: image, size: store.document.imageSize)])
            if Preferences.shared.closeAfterCopy { closeWithoutPrompt() }
        } catch {
            present(error)
        }
    }

    private func saveResult() {
        guard let store, let window else { return }
        let panel = NSSavePanel()
        panel.title = "Screenshot sichern"
        panel.nameFieldStringValue = defaultFilename(for: store.document.createdAt)
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try DocumentRenderer.pngData(store.document).write(to: url, options: .atomic)
            } catch {
                self.present(error)
            }
        }
    }

    private func archiveIdea() {
        guard let store else { return }
        do {
            _ = try IdeaStorage.save(store.document, to: Preferences.shared.ideaFolderURL)
            closeWithoutPrompt()
        } catch {
            present(error)
        }
    }

    private func discard() {
        if confirmDiscardIfNeeded() { closeWithoutPrompt() }
    }

    private func confirmDiscardIfNeeded() -> Bool {
        guard store?.hasChanges == true else { return true }
        let alert = NSAlert()
        alert.messageText = "Bearbeitung verwerfen?"
        alert.informativeText = "Die Annotationen gehen verloren."
        alert.addButton(withTitle: "Verwerfen")
        alert.addButton(withTitle: "Weiter bearbeiten")
        alert.alertStyle = .warning
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func closeWithoutPrompt() {
        window?.delegate = nil
        window?.close()
        window = nil
        store = nil
    }

    private func present(_ error: Error) {
        let alert = NSAlert(error: error)
        if let window { alert.beginSheetModal(for: window) }
        else { alert.runModal() }
    }

    private func defaultFilename(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date) + ".png"
    }
}
