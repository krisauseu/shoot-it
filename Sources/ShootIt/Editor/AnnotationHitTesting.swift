import CoreGraphics
import Foundation

enum AnnotationHitTesting {
    static func contains(_ annotation: Annotation, point: CGPoint, tolerance: CGFloat) -> Bool {
        let points = annotation.cgPoints
        switch annotation.kind {
        case .text:
            return annotation.bounds
                .insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        case .rectangle, .ellipse:
            return annotation.bounds.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        case .line, .arrow:
            guard points.count >= 2 else { return false }
            return distanceFromSegment(point, points[0], points[1]) <= tolerance
        case .freehand:
            return zip(points, points.dropFirst()).contains { distanceFromSegment(point, $0, $1) <= tolerance }
        }
    }

    private static func distanceFromSegment(_ point: CGPoint, _ start: CGPoint, _ end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(point.x - start.x, point.y - start.y) }
        let t = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared))
        let projection = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        return hypot(point.x - projection.x, point.y - projection.y)
    }
}
