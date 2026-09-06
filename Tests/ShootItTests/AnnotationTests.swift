import CoreGraphics
import Testing
@testable import ShootIt

struct AnnotationTests {
    @Test func translationMovesEveryPoint() {
        var annotation = Annotation(
            kind: .rectangle,
            points: [CGPoint(x: 10, y: 20), CGPoint(x: 40, y: 70)],
            color: .red,
            lineWidth: 4
        )

        annotation.translate(by: CGSize(width: 5, height: -3))

        #expect(annotation.cgPoints == [CGPoint(x: 15, y: 17), CGPoint(x: 45, y: 67)])
    }

    @Test func lineHitTestingUsesSegmentDistance() {
        let annotation = Annotation(
            kind: .line,
            points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)],
            color: .blue,
            lineWidth: 4
        )

        #expect(AnnotationHitTesting.contains(annotation, point: CGPoint(x: 50, y: 6), tolerance: 8))
        #expect(!AnnotationHitTesting.contains(annotation, point: CGPoint(x: 50, y: 20), tolerance: 8))
    }
}
