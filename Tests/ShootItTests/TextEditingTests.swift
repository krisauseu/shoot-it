import CoreGraphics
import Testing
@testable import ShootIt

struct TextEditingTests {
    @Test @MainActor func newTextIsOneUndoableChange() {
        let store = EditorStore(document: document())
        store.beginText(at: CGPoint(x: 30, y: 40))
        store.updateEditingText("Erste Zeile\nZweite Zeile")

        store.commitTextEditing()

        #expect(store.document.annotations.count == 1)
        #expect(store.document.annotations[0].text == "Erste Zeile\nZweite Zeile")
        #expect(store.document.annotations[0].fontSize == 24)
        store.undo()
        #expect(store.document.annotations.isEmpty)
    }

    @Test @MainActor func editingExistingTextCanBeUndoneInOneStep() {
        let annotation = Annotation(
            kind: .text,
            points: [CGPoint(x: 10, y: 20)],
            color: .white,
            lineWidth: 4,
            text: "Alt",
            fontSize: 30
        )
        let store = EditorStore(document: document(annotations: [annotation]))
        store.beginEditingText(id: annotation.id)
        store.updateEditingText("Neu")

        store.commitTextEditing()

        #expect(store.document.annotations[0].text == "Neu")
        store.undo()
        #expect(store.document.annotations[0].text == "Alt")
        #expect(!store.canUndo)
    }

    @Test @MainActor func escapeStyleCancellationLeavesExistingTextUntouched() {
        let annotation = Annotation(
            kind: .text,
            points: [CGPoint(x: 10, y: 20)],
            color: .white,
            lineWidth: 4,
            text: "Bleibt"
        )
        let store = EditorStore(document: document(annotations: [annotation]))
        store.beginEditingText(id: annotation.id)
        store.updateEditingText("Verworfen")

        store.cancelTextEditing()

        #expect(store.document.annotations[0].text == "Bleibt")
        #expect(!store.canUndo)
    }

    private func document(annotations: [Annotation] = []) -> ScreenshotDocument {
        let context = CGContext(
            data: nil,
            width: 200,
            height: 120,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return ScreenshotDocument(sourceImage: context.makeImage()!, annotations: annotations)
    }
}
