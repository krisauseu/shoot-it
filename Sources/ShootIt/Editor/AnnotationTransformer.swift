import CoreGraphics
import Foundation

enum AnnotationTransformer {
    static func transform(
        _ annotation: Annotation,
        handle: SelectionHandleKind,
        to point: CGPoint,
        preserveAspectRatio: Bool
    ) -> Annotation {
        var result = annotation
        switch annotation.kind {
        case .line, .arrow:
            result = transformLine(annotation, handle: handle, to: point, constrainAngle: preserveAspectRatio)
        case .rectangle, .ellipse:
            result.points = rectanglePoints(
                bounds: annotation.bounds,
                handle: handle,
                point: point,
                preserveAspectRatio: preserveAspectRatio
            ).map(CodablePoint.init)
        case .freehand:
            result = scaleFreehand(annotation, handle: handle, to: point)
        case .text:
            result = scaleText(annotation, handle: handle, to: point)
        }
        return result
    }

    private static func transformLine(
        _ annotation: Annotation,
        handle: SelectionHandleKind,
        to point: CGPoint,
        constrainAngle: Bool
    ) -> Annotation {
        guard annotation.cgPoints.count >= 2, handle == .start || handle == .end else { return annotation }
        var result = annotation
        let movingIndex = handle == .start ? 0 : 1
        let anchor = annotation.cgPoints[handle == .start ? 1 : 0]
        result.points[movingIndex] = CodablePoint(constrainAngle ? snapped(point, around: anchor) : point)
        return result
    }

    private static func snapped(_ point: CGPoint, around anchor: CGPoint) -> CGPoint {
        let vector = CGPoint(x: point.x - anchor.x, y: point.y - anchor.y)
        let length = hypot(vector.x, vector.y)
        guard length > 0 else { return point }
        let step = CGFloat.pi / 4
        let angle = (atan2(vector.y, vector.x) / step).rounded() * step
        return CGPoint(x: anchor.x + cos(angle) * length, y: anchor.y + sin(angle) * length)
    }

    private static func rectanglePoints(
        bounds: CGRect,
        handle: SelectionHandleKind,
        point: CGPoint,
        preserveAspectRatio: Bool
    ) -> [CGPoint] {
        guard bounds.width > 0, bounds.height > 0 else { return [bounds.origin, point] }
        var minX = bounds.minX
        var maxX = bounds.maxX
        var minY = bounds.minY
        var maxY = bounds.maxY

        if [.topLeft, .left, .bottomLeft].contains(handle) { minX = min(point.x, maxX - 1) }
        if [.topRight, .right, .bottomRight].contains(handle) { maxX = max(point.x, minX + 1) }
        if [.topLeft, .top, .topRight].contains(handle) { minY = min(point.y, maxY - 1) }
        if [.bottomLeft, .bottom, .bottomRight].contains(handle) { maxY = max(point.y, minY + 1) }

        if preserveAspectRatio {
            let ratio = bounds.width / bounds.height
            let isCorner = [.topLeft, .topRight, .bottomRight, .bottomLeft].contains(handle)
            if isCorner {
                let anchorX = [.topLeft, .bottomLeft].contains(handle) ? maxX : minX
                let anchorY = [.topLeft, .topRight].contains(handle) ? maxY : minY
                var width = abs(point.x - anchorX)
                var height = abs(point.y - anchorY)
                if width / max(height, 1) > ratio { height = width / ratio } else { width = height * ratio }
                minX = [.topLeft, .bottomLeft].contains(handle) ? anchorX - width : anchorX
                maxX = [.topLeft, .bottomLeft].contains(handle) ? anchorX : anchorX + width
                minY = [.topLeft, .topRight].contains(handle) ? anchorY - height : anchorY
                maxY = [.topLeft, .topRight].contains(handle) ? anchorY : anchorY + height
            } else if handle == .left || handle == .right {
                let height = (maxX - minX) / ratio
                let center = bounds.midY
                minY = center - height / 2
                maxY = center + height / 2
            } else if handle == .top || handle == .bottom {
                let width = (maxY - minY) * ratio
                let center = bounds.midX
                minX = center - width / 2
                maxX = center + width / 2
            }
        }
        return [CGPoint(x: minX, y: minY), CGPoint(x: maxX, y: maxY)]
    }

    private static func scaleFreehand(_ annotation: Annotation, handle: SelectionHandleKind, to point: CGPoint) -> Annotation {
        let oldBounds = annotation.bounds
        guard oldBounds.width > 0, oldBounds.height > 0,
              [.topLeft, .topRight, .bottomRight, .bottomLeft].contains(handle) else { return annotation }
        let newPoints = rectanglePoints(bounds: oldBounds, handle: handle, point: point, preserveAspectRatio: true)
        let newBounds = CGRect(
            x: min(newPoints[0].x, newPoints[1].x),
            y: min(newPoints[0].y, newPoints[1].y),
            width: abs(newPoints[1].x - newPoints[0].x),
            height: abs(newPoints[1].y - newPoints[0].y)
        )
        var result = annotation
        result.points = annotation.cgPoints.map { source in
            CodablePoint(CGPoint(
                x: newBounds.minX + (source.x - oldBounds.minX) / oldBounds.width * newBounds.width,
                y: newBounds.minY + (source.y - oldBounds.minY) / oldBounds.height * newBounds.height
            ))
        }
        return result
    }

    private static func scaleText(_ annotation: Annotation, handle: SelectionHandleKind, to point: CGPoint) -> Annotation {
        guard handle == .textScale, let origin = annotation.cgPoints.first else { return annotation }
        let originalSize = annotation.bounds.size
        let vector = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        let denominator = originalSize.width * originalSize.width + originalSize.height * originalSize.height
        guard denominator > 0 else { return annotation }
        let scale = (vector.x * originalSize.width + vector.y * originalSize.height) / denominator
        var result = annotation
        result.fontSize = min(512, max(6, annotation.fontSize * scale))
        return result
    }
}
