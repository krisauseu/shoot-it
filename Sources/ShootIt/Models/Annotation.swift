import AppKit
import Foundation

enum AnnotationKind: String, Codable, CaseIterable, Sendable {
    case arrow
    case line
    case rectangle
    case ellipse
    case freehand
    case text
}

struct RGBAColor: Codable, Equatable, Sendable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ color: NSColor) {
        let converted = color.usingColorSpace(.sRGB) ?? color
        red = converted.redComponent
        green = converted.greenComponent
        blue = converted.blueComponent
        alpha = converted.alphaComponent
    }

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    static let red = RGBAColor(red: 0.95, green: 0.25, blue: 0.20)
    static let orange = RGBAColor(red: 1.00, green: 0.55, blue: 0.12)
    static let yellow = RGBAColor(red: 0.98, green: 0.78, blue: 0.18)
    static let green = RGBAColor(red: 0.18, green: 0.78, blue: 0.42)
    static let blue = RGBAColor(red: 0.20, green: 0.55, blue: 0.98)
    static let purple = RGBAColor(red: 0.65, green: 0.38, blue: 0.93)
    static let white = RGBAColor(red: 0.96, green: 0.96, blue: 0.94)
    static let black = RGBAColor(red: 0.05, green: 0.05, blue: 0.05)

    static let palette: [RGBAColor] = [.red, .orange, .yellow, .green, .blue, .purple, .white, .black]
}

struct CodablePoint: Codable, Equatable, Sendable {
    var x: CGFloat
    var y: CGFloat

    init(_ point: CGPoint) {
        x = point.x
        y = point.y
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

struct Annotation: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var kind: AnnotationKind
    var points: [CodablePoint]
    var color: RGBAColor
    var lineWidth: CGFloat
    var text: String?
    var fontSize: CGFloat

    init(
        id: UUID = UUID(),
        kind: AnnotationKind,
        points: [CGPoint],
        color: RGBAColor,
        lineWidth: CGFloat,
        text: String? = nil,
        fontSize: CGFloat = 24
    ) {
        self.id = id
        self.kind = kind
        self.points = points.map(CodablePoint.init)
        self.color = color
        self.lineWidth = lineWidth
        self.text = text
        self.fontSize = fontSize
    }

    var cgPoints: [CGPoint] { points.map(\.cgPoint) }

    var bounds: CGRect {
        if kind == .text, let origin = cgPoints.first {
            return CGRect(origin: origin, size: AnnotationTextLayout.size(for: text ?? "", fontSize: fontSize))
        }
        guard let first = cgPoints.first else { return .zero }
        return cgPoints.dropFirst().reduce(CGRect(origin: first, size: .zero)) { partial, point in
            partial.union(CGRect(origin: point, size: .zero))
        }
    }

    mutating func translate(by delta: CGSize) {
        points = points.map { CodablePoint(CGPoint(x: $0.x + delta.width, y: $0.y + delta.height)) }
    }
}

enum AnnotationTextLayout {
    static func size(for text: String, fontSize: CGFloat) -> CGSize {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let lines = text.components(separatedBy: "\n")
        let widths = lines.map { ($0.isEmpty ? " " : $0).size(withAttributes: [.font: font]).width }
        return CGSize(
            width: max(12, ceil(widths.max() ?? 0)),
            height: max(fontSize, ceil(font.ascender - font.descender + font.leading) * CGFloat(max(1, lines.count)))
        )
    }
}
