import CoreGraphics
import Foundation

enum SelectionHandleKind: String, CaseIterable, Sendable {
    case start
    case end
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
    case textScale
}

struct SelectionHandle: Equatable, Sendable {
    let kind: SelectionHandleKind
    let position: CGPoint
}

enum AnnotationSelectionGeometry {
    static func handles(for annotation: Annotation) -> [SelectionHandle] {
        let points = annotation.cgPoints
        switch annotation.kind {
        case .line, .arrow:
            guard points.count >= 2 else { return [] }
            return [
                SelectionHandle(kind: .start, position: points[0]),
                SelectionHandle(kind: .end, position: points[1])
            ]
        case .rectangle, .ellipse:
            return rectangleHandles(for: annotation.bounds)
        case .freehand:
            let bounds = annotation.bounds
            return [
                SelectionHandle(kind: .topLeft, position: CGPoint(x: bounds.minX, y: bounds.minY)),
                SelectionHandle(kind: .topRight, position: CGPoint(x: bounds.maxX, y: bounds.minY)),
                SelectionHandle(kind: .bottomRight, position: CGPoint(x: bounds.maxX, y: bounds.maxY)),
                SelectionHandle(kind: .bottomLeft, position: CGPoint(x: bounds.minX, y: bounds.maxY))
            ]
        case .text:
            let bounds = annotation.bounds
            return [SelectionHandle(kind: .textScale, position: CGPoint(x: bounds.maxX, y: bounds.maxY))]
        }
    }

    static func hitTest(
        _ annotation: Annotation,
        displayPoint: CGPoint,
        displayPosition: (CGPoint) -> CGPoint,
        radius: CGFloat = 12
    ) -> SelectionHandleKind? {
        handles(for: annotation)
            .map { ($0.kind, hypot(displayPosition($0.position).x - displayPoint.x, displayPosition($0.position).y - displayPoint.y)) }
            .filter { $0.1 <= radius }
            .min { $0.1 < $1.1 }?.0
    }

    private static func rectangleHandles(for bounds: CGRect) -> [SelectionHandle] {
        [
            SelectionHandle(kind: .topLeft, position: CGPoint(x: bounds.minX, y: bounds.minY)),
            SelectionHandle(kind: .top, position: CGPoint(x: bounds.midX, y: bounds.minY)),
            SelectionHandle(kind: .topRight, position: CGPoint(x: bounds.maxX, y: bounds.minY)),
            SelectionHandle(kind: .right, position: CGPoint(x: bounds.maxX, y: bounds.midY)),
            SelectionHandle(kind: .bottomRight, position: CGPoint(x: bounds.maxX, y: bounds.maxY)),
            SelectionHandle(kind: .bottom, position: CGPoint(x: bounds.midX, y: bounds.maxY)),
            SelectionHandle(kind: .bottomLeft, position: CGPoint(x: bounds.minX, y: bounds.maxY)),
            SelectionHandle(kind: .left, position: CGPoint(x: bounds.minX, y: bounds.midY))
        ]
    }
}
