import AppKit
import SwiftUI

@MainActor
final class IdeaGalleryWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var store: IdeaGalleryStore?

    func show(preferences: Preferences) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let store = IdeaGalleryStore(preferences: preferences)
        let actions = IdeaGalleryActions(
            preview: { [weak self] in self?.openInPreview($0) },
            copy: { [weak self] in self?.copy($0) },
            reveal: { NSWorkspace.shared.activateFileViewerSelecting([$0.url]) },
            delete: { [weak self] in self?.confirmDelete($0) }
        )
        let hosting = NSHostingController(rootView: IdeaGalleryView(store: store, actions: actions))
        let window = NSWindow(contentViewController: hosting)
        window.title = "Ideen"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(CGSize(width: 940, height: 650))
        window.minSize = CGSize(width: 700, height: 480)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.store = store
        self.window = window
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        store = nil
    }

    private func copy(_ item: IdeaItem) {
        guard let image = NSImage(contentsOf: item.url) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    private func openInPreview(_ item: IdeaItem) {
        let previewURL = URL(fileURLWithPath: "/System/Applications/Preview.app", isDirectory: true)
        NSWorkspace.shared.open(
            [item.url],
            withApplicationAt: previewURL,
            configuration: NSWorkspace.OpenConfiguration()
        ) { [weak self] _, error in
            guard let error else { return }
            Task { @MainActor in self?.present(error) }
        }
    }

    private func confirmDelete(_ item: IdeaItem) {
        guard let window else { return }
        let alert = NSAlert()
        alert.messageText = "Idee löschen?"
        alert.informativeText = "\"\(item.filename)\" wird in den Papierkorb gelegt."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "In den Papierkorb")
        alert.addButton(withTitle: "Abbrechen")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            do {
                var result: NSURL?
                try FileManager.default.trashItem(at: item.url, resultingItemURL: &result)
                self?.store?.reload()
            } catch {
                self?.present(error)
            }
        }
    }

    private func present(_ error: Error) {
        let alert = NSAlert(error: error)
        if let window { alert.beginSheetModal(for: window) }
    }
}
