import Foundation
import Testing
@testable import ShootIt

struct ThumbnailCacheKeyTests {
    @Test func keyChangesForFileVersionAndRequestedSize() {
        let first = IdeaItem(
            url: URL(fileURLWithPath: "/tmp/idea.png"),
            filename: "idea.png",
            captureDate: .distantPast,
            modificationDate: Date(timeIntervalSinceReferenceDate: 100),
            fileSize: 200
        )
        let changed = IdeaItem(
            url: first.url,
            filename: first.filename,
            captureDate: first.captureDate,
            modificationDate: Date(timeIntervalSinceReferenceDate: 101),
            fileSize: 220
        )

        #expect(ThumbnailCacheKey.make(for: first, maxPixelSize: 512) == ThumbnailCacheKey.make(for: first, maxPixelSize: 512))
        #expect(ThumbnailCacheKey.make(for: first, maxPixelSize: 512) != ThumbnailCacheKey.make(for: changed, maxPixelSize: 512))
        #expect(ThumbnailCacheKey.make(for: first, maxPixelSize: 512) != ThumbnailCacheKey.make(for: first, maxPixelSize: 256))
    }
}
