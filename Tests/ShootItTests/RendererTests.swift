import CoreGraphics
import Foundation
import Testing
@testable import ShootIt

struct RendererTests {
    @Test func rendererPreservesPixelDimensions() throws {
        let context = CGContext(
            data: nil,
            width: 320,
            height: 180,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(gray: 0.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 320, height: 180))
        let source = context.makeImage()!
        let annotations = [
            Annotation(kind: .arrow, points: [CGPoint(x: 10, y: 10), CGPoint(x: 100, y: 80)], color: .yellow, lineWidth: 4),
            Annotation(kind: .text, points: [CGPoint(x: 20, y: 120)], color: .white, lineWidth: 4, text: "Test")
        ]

        let rendered = try DocumentRenderer.render(ScreenshotDocument(sourceImage: source, annotations: annotations))

        #expect(rendered.width == 320)
        #expect(rendered.height == 180)
        #expect(try DocumentRenderer.pngData(ScreenshotDocument(sourceImage: source, annotations: annotations)).isEmpty == false)
    }

    @Test func rendererDoesNotFlipSourceImage() throws {
        let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 8,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 1))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 1, width: 2, height: 1))
        let source = context.makeImage()!

        let rendered = try DocumentRenderer.render(ScreenshotDocument(sourceImage: source))

        #expect(samplePixel(rendered, x: 0, y: 0) == samplePixel(source, x: 0, y: 0))
        #expect(samplePixel(rendered, x: 0, y: 1) == samplePixel(source, x: 0, y: 1))
    }

    private func samplePixel(_ image: CGImage, x: Int, y: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.draw(
                image,
                in: CGRect(x: -x, y: -y, width: image.width, height: image.height)
            )
        }
        return bytes
    }
}
