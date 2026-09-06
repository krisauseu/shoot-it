import AppKit
import CoreText
import Foundation
import UniformTypeIdentifiers

enum DocumentRendererError: LocalizedError {
    case contextCreationFailed
    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .contextCreationFailed: "Das Bild konnte nicht gerendert werden."
        case .pngEncodingFailed: "Das PNG konnte nicht erzeugt werden."
        }
    }
}

enum DocumentRenderer {
    static func render(_ document: ScreenshotDocument) throws -> CGImage {
        let width = document.sourceImage.width
        let height = document.sourceImage.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw DocumentRendererError.contextCreationFailed
        }

        context.interpolationQuality = .high
        context.draw(document.sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for annotation in document.annotations {
            draw(annotation, in: context, imageHeight: CGFloat(height))
        }

        guard let result = context.makeImage() else {
            throw DocumentRendererError.contextCreationFailed
        }
        return result
    }

    static func pngData(_ document: ScreenshotDocument) throws -> Data {
        let image = try render(document)
        let representation = NSBitmapImageRep(cgImage: image)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw DocumentRendererError.pngEncodingFailed
        }
        return data
    }

    private static func draw(_ annotation: Annotation, in context: CGContext, imageHeight: CGFloat) {
        let points = annotation.cgPoints.map { CGPoint(x: $0.x, y: imageHeight - $0.y) }
        guard let first = points.first else { return }
        let color = annotation.color.nsColor.cgColor
        context.saveGState()
        context.setStrokeColor(color)
        context.setFillColor(color)
        context.setLineWidth(annotation.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch annotation.kind {
        case .line:
            guard points.count >= 2 else { break }
            context.move(to: points[0])
            context.addLine(to: points[1])
            context.strokePath()
        case .arrow:
            guard points.count >= 2 else { break }
            drawArrow(from: points[0], to: points[1], lineWidth: annotation.lineWidth, in: context)
        case .rectangle:
            guard points.count >= 2 else { break }
            context.stroke(standardRect(from: points[0], to: points[1]))
        case .ellipse:
            guard points.count >= 2 else { break }
            context.strokeEllipse(in: standardRect(from: points[0], to: points[1]))
        case .freehand:
            context.move(to: first)
            points.dropFirst().forEach { context.addLine(to: $0) }
            context.strokePath()
        case .text:
            drawText(annotation.text ?? "", at: first, color: color, fontSize: annotation.fontSize, in: context)
        }
        context.restoreGState()
    }

    private static func drawArrow(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat, in context: CGContext) {
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = max(12, lineWidth * 4.5)
        let spread = CGFloat.pi / 7
        let left = CGPoint(x: end.x - length * cos(angle - spread), y: end.y - length * sin(angle - spread))
        let right = CGPoint(x: end.x - length * cos(angle + spread), y: end.y - length * sin(angle + spread))
        context.move(to: end)
        context.addLine(to: left)
        context.move(to: end)
        context.addLine(to: right)
        context.strokePath()
    }

    private static func drawText(_ text: String, at point: CGPoint, color: CGColor, fontSize: CGFloat, in context: CGContext) {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(cgColor: color) ?? .white
        ]
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        for (index, value) in text.components(separatedBy: "\n").enumerated() {
            let attributed = NSAttributedString(string: value, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attributed)
            context.textPosition = CGPoint(x: point.x, y: point.y - fontSize - CGFloat(index) * lineHeight)
            CTLineDraw(line, context)
        }
    }

    private static func standardRect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
    }
}
