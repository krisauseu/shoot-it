import AppKit
import Foundation

@MainActor
final class CaptureCoordinator {
    private let overlay = SelectionOverlayController()
    private let showEditor: (ScreenshotDocument) -> Void
    private let reportError: (Error) -> Void
    private(set) var isCapturing = false

    init(showEditor: @escaping (ScreenshotDocument) -> Void, reportError: @escaping (Error) -> Void) {
        self.showEditor = showEditor
        self.reportError = reportError
    }

    func start() {
        guard !isCapturing else { return }
        guard ScreenCaptureService.ensurePermission() else {
            reportError(ScreenCaptureError.permissionDenied)
            return
        }
        isCapturing = true
        overlay.begin { [weak self] rect in
            guard let self else { return }
            guard let rect else {
                self.isCapturing = false
                return
            }
            Task {
                do {
                    // Give WindowServer one frame to remove the selection overlay.
                    try await Task.sleep(for: .milliseconds(80))
                    let image = try await ScreenCaptureService.capture(nsScreenRect: rect)
                    self.isCapturing = false
                    self.showEditor(ScreenshotDocument(sourceImage: image))
                } catch {
                    self.isCapturing = false
                    self.reportError(error)
                }
            }
        }
    }
}
