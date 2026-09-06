import CoreGraphics
import Foundation
import Testing
@testable import ShootIt

struct IdeaStorageTests {
    @Test func ideaStorageWritesOnlyOnePNG() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let context = CGContext(
            data: nil,
            width: 8,
            height: 6,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        let document = ScreenshotDocument(sourceImage: context.makeImage()!)

        let savedURL = try IdeaStorage.save(document, to: temporaryDirectory)
        let files = try FileManager.default.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil
        )

        #expect(savedURL.pathExtension == "png")
        #expect(files.count == 1)
        #expect(files.first?.lastPathComponent == savedURL.lastPathComponent)
    }
}
