import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

enum ScreenCaptureError: LocalizedError {
    case permissionDenied
    case emptyImage

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Bildschirmaufnahme ist nicht erlaubt. Aktiviere Shoot It unter Systemeinstellungen > Datenschutz & Sicherheit > Bildschirmaufnahme und starte die App neu."
        case .emptyImage:
            "Der ausgewählte Bereich konnte nicht aufgenommen werden."
        }
    }
}

enum ScreenCaptureService {
    static func ensurePermission() -> Bool {
        CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
    }

    static func capture(nsScreenRect: CGRect) async throws -> CGImage {
        guard CGPreflightScreenCaptureAccess() else {
            throw ScreenCaptureError.permissionDenied
        }
        let captureRect = coreGraphicsRect(from: nsScreenRect)
        let image: CGImage
        if #available(macOS 15.2, *) {
            image = try await withCheckedThrowingContinuation { continuation in
                SCScreenshotManager.captureImage(in: captureRect) { image, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: ScreenCaptureError.emptyImage)
                    }
                }
            }
        } else {
            throw ScreenCaptureError.emptyImage
        }
        return image
    }

    static func coreGraphicsRect(from nsRect: CGRect) -> CGRect {
        let mainHeight = CGDisplayBounds(CGMainDisplayID()).height
        return CGRect(x: nsRect.minX, y: mainHeight - nsRect.maxY, width: nsRect.width, height: nsRect.height)
    }
}
