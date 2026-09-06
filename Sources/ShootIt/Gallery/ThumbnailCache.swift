import AppKit
import Foundation
import ImageIO

enum ThumbnailCacheKey {
    static func make(for item: IdeaItem, maxPixelSize: Int) -> String {
        let timestamp = item.modificationDate.timeIntervalSinceReferenceDate.bitPattern
        return "\(item.url.standardizedFileURL.path)|\(item.fileSize)|\(timestamp)|\(maxPixelSize)"
    }
}

actor ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, CGImage>()

    init() {
        cache.countLimit = 300
        cache.totalCostLimit = 96 * 1_024 * 1_024
    }

    func image(for item: IdeaItem, maxPixelSize: Int) -> CGImage? {
        let key = ThumbnailCacheKey.make(for: item, maxPixelSize: maxPixelSize) as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let source = CGImageSourceCreateWithURL(item.url as CFURL, [
            kCGImageSourceShouldCache: false
        ] as CFDictionary) else { return nil }
        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        cache.setObject(image, forKey: key, cost: image.bytesPerRow * image.height)
        return image
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
