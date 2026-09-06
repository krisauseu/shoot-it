import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    let preferences = Preferences.shared
    private let hotKeyManager = HotKeyManager()
    private let editor = EditorWindowController()
    private let gallery = IdeaGalleryWindowController()
    private lazy var captureCoordinator = CaptureCoordinator(
        showEditor: { [weak self] document in self?.editor.show(document: document) },
        reportError: { [weak self] error in self?.present(error) }
    )
    private var cancellables: Set<AnyCancellable> = []
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        registerHotKey()
        preferences.$hotKeyCode
            .combineLatest(preferences.$hotKeyModifiers)
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in self?.registerHotKey() }
            .store(in: &cancellables)
    }

    func takeScreenshot() {
        guard editor.allowNewCapture() else { return }
        captureCoordinator.start()
    }

    func openIdeasGallery() {
        gallery.show(preferences: preferences)
    }

    private func registerHotKey() {
        do {
            try hotKeyManager.register(
                keyCode: preferences.hotKeyCode,
                modifiers: preferences.hotKeyModifiers,
                action: { [weak self] in self?.takeScreenshot() }
            )
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        NSAlert(error: error).runModal()
    }
}
