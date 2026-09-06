import SwiftUI

struct EditorCanvas: View {
    @ObservedObject var store: EditorStore
    let requestText: (CGPoint) -> Void

    @State private var dragStarted = false

    var body: some View {
        GeometryReader { proxy in
            let imageRect = fittedRect(imageSize: store.document.imageSize, in: proxy.size)
            Canvas { context, _ in
                let image = Image(decorative: store.document.sourceImage, scale: 1)
                context.draw(image, in: imageRect)
                for annotation in store.document.annotations {
                    draw(annotation, selected: annotation.id == store.selectedID, in: &context, imageRect: imageRect)
                }
                if let draft = store.draft {
                    draw(draft, selected: false, in: &context, imageRect: imageRect)
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(imageRect: imageRect))
            .background(Color.black.opacity(0.32))
        }
    }

    private func dragGesture(imageRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard imageRect.contains(value.startLocation),
                      let start = imagePoint(value.startLocation, imageRect: imageRect),
                      let current = imagePoint(value.location, imageRect: imageRect) else { return }

                if !dragStarted {
                    dragStarted = true
                    switch store.tool {
                    case .pointer:
                        store.select(at: start, tolerance: 10 / imageScale(imageRect))
                        store.beginMove()
                    case .text:
                        break
                    default:
                        store.beginAnnotation(at: start)
                    }
                }

                switch store.tool {
                case .pointer:
                    store.moveSelected(by: CGSize(width: current.x - start.x, height: current.y - start.y))
                case .text:
                    break
                default:
                    store.updateAnnotation(to: current)
                }
            }
            .onEnded { value in
                defer { dragStarted = false }
                guard imageRect.contains(value.startLocation),
                      let point = imagePoint(value.startLocation, imageRect: imageRect) else { return }
                switch store.tool {
                case .pointer:
                    store.finishMove()
                case .text:
                    requestText(point)
                default:
                    store.finishAnnotation()
                }
            }
    }

    private func draw(_ annotation: Annotation, selected: Bool, in context: inout GraphicsContext, imageRect: CGRect) {
        let scale = imageScale(imageRect)
        let points = annotation.cgPoints.map { displayPoint($0, imageRect: imageRect) }
        guard let first = points.first else { return }
        let color = Color(nsColor: annotation.color.nsColor)
        let stroke = StrokeStyle(lineWidth: annotation.lineWidth * scale, lineCap: .round, lineJoin: .round)

        switch annotation.kind {
        case .line:
            guard points.count >= 2 else { break }
            var path = Path()
            path.move(to: points[0])
            path.addLine(to: points[1])
            context.stroke(path, with: .color(color), style: stroke)
        case .arrow:
            guard points.count >= 2 else { break }
            drawArrow(from: points[0], to: points[1], color: color, lineWidth: annotation.lineWidth * scale, in: &context)
        case .rectangle:
            guard points.count >= 2 else { break }
            context.stroke(Path(standardRect(points[0], points[1])), with: .color(color), style: stroke)
        case .ellipse:
            guard points.count >= 2 else { break }
            context.stroke(Path(ellipseIn: standardRect(points[0], points[1])), with: .color(color), style: stroke)
        case .freehand:
            var path = Path()
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
            context.stroke(path, with: .color(color), style: stroke)
        case .text:
            let fontSize = max(18, annotation.lineWidth * 6) * scale
            context.draw(
                Text(annotation.text ?? "").font(.system(size: fontSize, weight: .semibold)).foregroundStyle(color),
                at: first,
                anchor: .topLeading
            )
        }

        if selected {
            let imageBounds = annotation.bounds
            let topLeft = displayPoint(CGPoint(x: imageBounds.minX, y: imageBounds.minY), imageRect: imageRect)
            let bottomRight = displayPoint(CGPoint(x: imageBounds.maxX, y: imageBounds.maxY), imageRect: imageRect)
            let rect = standardRect(topLeft, bottomRight).insetBy(dx: -6, dy: -6)
            context.stroke(Path(rect), with: .color(.white.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    private func drawArrow(from start: CGPoint, to end: CGPoint, color: Color, lineWidth: CGFloat, in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = max(12, lineWidth * 4.5)
        let spread = CGFloat.pi / 7
        path.move(to: end)
        path.addLine(to: CGPoint(x: end.x - length * cos(angle - spread), y: end.y - length * sin(angle - spread)))
        path.move(to: end)
        path.addLine(to: CGPoint(x: end.x - length * cos(angle + spread), y: end.y - length * sin(angle + spread)))
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }

    private func fittedRect(imageSize: CGSize, in available: CGSize) -> CGRect {
        let scale = min(available.width / imageSize.width, available.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: (available.width - size.width) / 2, y: (available.height - size.height) / 2,
                      width: size.width, height: size.height)
    }

    private func imageScale(_ rect: CGRect) -> CGFloat {
        rect.width / store.document.imageSize.width
    }

    private func imagePoint(_ point: CGPoint, imageRect: CGRect) -> CGPoint? {
        guard imageRect.contains(point) else { return nil }
        let scale = imageScale(imageRect)
        return CGPoint(x: (point.x - imageRect.minX) / scale, y: (point.y - imageRect.minY) / scale)
    }

    private func displayPoint(_ point: CGPoint, imageRect: CGRect) -> CGPoint {
        let scale = imageScale(imageRect)
        return CGPoint(x: imageRect.minX + point.x * scale, y: imageRect.minY + point.y * scale)
    }

    private func standardRect(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
    }
}
