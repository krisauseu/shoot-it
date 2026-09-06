import AppKit
import Foundation

struct ScreenshotDocument {
    let sourceImage: CGImage
    var annotations: [Annotation] = []
    let createdAt: Date

    init(sourceImage: CGImage, annotations: [Annotation] = [], createdAt: Date = Date()) {
        self.sourceImage = sourceImage
        self.annotations = annotations
        self.createdAt = createdAt
    }

    var imageSize: CGSize {
        CGSize(width: sourceImage.width, height: sourceImage.height)
    }
}
