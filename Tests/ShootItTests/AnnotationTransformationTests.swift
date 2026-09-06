import CoreGraphics
import Testing
@testable import ShootIt

struct AnnotationTransformationTests {
    @Test func rectangleHasCornerAndEdgeHandles() {
        let annotation = Annotation(
            kind: .rectangle,
            points: [CGPoint(x: 10, y: 20), CGPoint(x: 110, y: 70)],
            color: .red,
            lineWidth: 4
        )

        let handles = AnnotationSelectionGeometry.handles(for: annotation)

        #expect(handles.count == 8)
        #expect(handles.first(where: { $0.kind == .top })?.position == CGPoint(x: 60, y: 20))
        #expect(handles.first(where: { $0.kind == .right })?.position == CGPoint(x: 110, y: 45))
        #expect(handles.first(where: { $0.kind == .bottomLeft })?.position == CGPoint(x: 10, y: 70))
    }

    @Test func lineHasEndpointHandlesAndTextHasScaleHandle() {
        let line = Annotation(
            kind: .line,
            points: [CGPoint(x: 3, y: 4), CGPoint(x: 40, y: 50)],
            color: .blue,
            lineWidth: 4
        )
        let text = Annotation(
            kind: .text,
            points: [CGPoint(x: 20, y: 30)],
            color: .white,
            lineWidth: 4,
            text: "Text",
            fontSize: 24
        )

        #expect(AnnotationSelectionGeometry.handles(for: line).map(\.kind) == [.start, .end])
        let textHandle = AnnotationSelectionGeometry.handles(for: text)
        #expect(textHandle.count == 1)
        #expect(textHandle[0].kind == .textScale)
        #expect(textHandle[0].position == CGPoint(x: text.bounds.maxX, y: text.bounds.maxY))
    }

    @Test func handleHitTestingUsesAStableDisplayRadius() {
        let annotation = Annotation(
            kind: .rectangle,
            points: [CGPoint(x: 100, y: 200), CGPoint(x: 1_100, y: 1_200)],
            color: .red,
            lineWidth: 4
        )
        let displayPosition: (CGPoint) -> CGPoint = { CGPoint(x: $0.x * 0.1 + 40, y: $0.y * 0.1 + 30) }
        let topLeft = displayPosition(CGPoint(x: 100, y: 200))

        #expect(AnnotationSelectionGeometry.hitTest(
            annotation,
            displayPoint: CGPoint(x: topLeft.x + 10, y: topLeft.y),
            displayPosition: displayPosition
        ) == .topLeft)
        #expect(AnnotationSelectionGeometry.hitTest(
            annotation,
            displayPoint: CGPoint(x: topLeft.x - 13, y: topLeft.y),
            displayPosition: displayPosition
        ) == nil)
    }

    @Test func shiftKeepsRectangleAspectRatio() {
        let annotation = Annotation(
            kind: .rectangle,
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 50)],
            color: .red,
            lineWidth: 4
        )

        let resized = AnnotationTransformer.transform(
            annotation,
            handle: .bottomRight,
            to: CGPoint(x: 160, y: 60),
            preserveAspectRatio: true
        )

        #expect(abs(resized.bounds.width / resized.bounds.height - 2) < 0.001)
    }

    @Test func freehandScalingIsProportional() {
        let annotation = Annotation(
            kind: .freehand,
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 25), CGPoint(x: 100, y: 50)],
            color: .blue,
            lineWidth: 4
        )

        let resized = AnnotationTransformer.transform(
            annotation,
            handle: .bottomRight,
            to: CGPoint(x: 200, y: 80),
            preserveAspectRatio: false
        )

        #expect(abs(resized.bounds.width / resized.bounds.height - 2) < 0.001)
        #expect(resized.cgPoints[1] == CGPoint(x: 100, y: 50))
    }

    @Test func textScaleChangesFontSizeAndKeepsPixelOrigin() {
        let annotation = Annotation(
            kind: .text,
            points: [CGPoint(x: 20, y: 30)],
            color: .white,
            lineWidth: 4,
            text: "Skalieren",
            fontSize: 24
        )
        let scaleHandle = AnnotationSelectionGeometry.handles(for: annotation)[0]
        let vector = CGPoint(
            x: scaleHandle.position.x + annotation.bounds.width,
            y: scaleHandle.position.y + annotation.bounds.height
        )

        let resized = AnnotationTransformer.transform(
            annotation,
            handle: .textScale,
            to: vector,
            preserveAspectRatio: false
        )

        #expect(resized.fontSize == 48)
        #expect(resized.cgPoints == annotation.cgPoints)
    }

    @Test @MainActor func completeTransformationCreatesExactlyOneUndoStep() {
        let annotation = Annotation(
            kind: .rectangle,
            points: [CGPoint(x: 10, y: 20), CGPoint(x: 110, y: 70)],
            color: .red,
            lineWidth: 4
        )
        let store = EditorStore(document: document(annotation))
        store.select(at: CGPoint(x: 50, y: 40))
        store.beginTransform(handle: .bottomRight)
        store.transformSelected(handle: .bottomRight, to: CGPoint(x: 130, y: 80), preserveAspectRatio: false)
        store.transformSelected(handle: .bottomRight, to: CGPoint(x: 150, y: 90), preserveAspectRatio: false)

        store.finishTransform()

        #expect(store.document.annotations[0].bounds == CGRect(x: 10, y: 20, width: 140, height: 70))
        store.undo()
        #expect(store.document.annotations == [annotation])
        #expect(!store.canUndo)
    }

    private func document(_ annotation: Annotation) -> ScreenshotDocument {
        let context = CGContext(
            data: nil,
            width: 200,
            height: 120,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return ScreenshotDocument(sourceImage: context.makeImage()!, annotations: [annotation])
    }
}
