import AppKit
import Combine
import Foundation

@MainActor
final class EditorStore: ObservableObject {
    struct TextEditingSession: Equatable {
        let annotationID: UUID?
        let origin: CGPoint
        var text: String
    }

    @Published private(set) var document: ScreenshotDocument
    @Published var tool: EditorTool = .arrow
    @Published var color: RGBAColor
    @Published var lineWidth: CGFloat
    @Published var selectedID: UUID?
    @Published var draft: Annotation?
    @Published var textEditing: TextEditingSession?

    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []
    private var continuousChangeOrigin: [Annotation]?

    init(document: ScreenshotDocument) {
        self.document = document
        color = Preferences.shared.defaultColor
        lineWidth = Preferences.shared.defaultLineWidth
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var hasChanges: Bool {
        !document.annotations.isEmpty || !(textEditing?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    func beginAnnotation(at point: CGPoint) {
        guard let kind = tool.annotationKind, kind != .text else { return }
        let points = kind == .freehand ? [point] : [point, point]
        draft = Annotation(kind: kind, points: points, color: color, lineWidth: lineWidth)
        selectedID = nil
    }

    func updateAnnotation(to point: CGPoint) {
        guard var draft else { return }
        if draft.kind == .freehand {
            draft.points.append(CodablePoint(point))
        } else if draft.points.count == 2 {
            draft.points[1] = CodablePoint(point)
        }
        self.draft = draft
    }

    func finishAnnotation() {
        guard let draft else { return }
        self.draft = nil
        guard draft.bounds.width > 1 || draft.bounds.height > 1 else { return }
        commitChange { $0.append(draft) }
        selectedID = draft.id
    }

    func addText(_ text: String, at point: CGPoint) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        let annotation = Annotation(
            kind: .text,
            points: [point],
            color: color,
            lineWidth: lineWidth,
            text: value,
            fontSize: max(18, lineWidth * 6)
        )
        commitChange { $0.append(annotation) }
        selectedID = annotation.id
    }

    func beginText(at point: CGPoint) {
        textEditing = TextEditingSession(annotationID: nil, origin: point, text: "")
        selectedID = nil
    }

    func beginEditingText(id: UUID) {
        guard let annotation = document.annotations.first(where: { $0.id == id }),
              annotation.kind == .text,
              let origin = annotation.cgPoints.first else { return }
        selectedID = id
        textEditing = TextEditingSession(annotationID: id, origin: origin, text: annotation.text ?? "")
    }

    func updateEditingText(_ text: String) {
        textEditing?.text = text
    }

    func commitTextEditing() {
        guard let session = textEditing else { return }
        textEditing = nil
        let value = session.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = session.annotationID {
            guard let existing = document.annotations.first(where: { $0.id == id }), existing.text != value else { return }
            commitChange { annotations in
                guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
                if value.isEmpty {
                    annotations.remove(at: index)
                } else {
                    annotations[index].text = value
                }
            }
            selectedID = value.isEmpty ? nil : id
        } else if !value.isEmpty {
            addText(value, at: session.origin)
        }
    }

    func cancelTextEditing() {
        textEditing = nil
    }

    func select(at point: CGPoint, tolerance: CGFloat = 10) {
        selectedID = document.annotations.reversed().first(where: {
            AnnotationHitTesting.contains($0, point: point, tolerance: tolerance)
        })?.id
    }

    func beginMove() {
        guard selectedID != nil else { return }
        continuousChangeOrigin = document.annotations
    }

    func moveSelected(by delta: CGSize) {
        guard let id = selectedID, let origin = continuousChangeOrigin,
              let original = origin.first(where: { $0.id == id }),
              let index = document.annotations.firstIndex(where: { $0.id == id }) else { return }
        var moved = original
        moved.translate(by: delta)
        document.annotations[index] = moved
        objectWillChange.send()
    }

    func finishMove() {
        finishContinuousChange()
    }

    func beginTransform(handle _: SelectionHandleKind) {
        guard selectedID != nil else { return }
        continuousChangeOrigin = document.annotations
    }

    func transformSelected(handle: SelectionHandleKind, to point: CGPoint, preserveAspectRatio: Bool) {
        guard let id = selectedID, let origin = continuousChangeOrigin,
              let original = origin.first(where: { $0.id == id }),
              let index = document.annotations.firstIndex(where: { $0.id == id }) else { return }
        document.annotations[index] = AnnotationTransformer.transform(
            original,
            handle: handle,
            to: point,
            preserveAspectRatio: preserveAspectRatio
        )
        objectWillChange.send()
    }

    func finishTransform() {
        finishContinuousChange()
    }

    private func finishContinuousChange() {
        guard let origin = continuousChangeOrigin else { return }
        continuousChangeOrigin = nil
        guard origin != document.annotations else { return }
        undoStack.append(origin)
        redoStack.removeAll()
    }

    func deleteSelected() {
        guard let id = selectedID else { return }
        if textEditing?.annotationID == id { textEditing = nil }
        commitChange { $0.removeAll { $0.id == id } }
        selectedID = nil
    }

    func undo() {
        guard let prior = undoStack.popLast() else { return }
        redoStack.append(document.annotations)
        document.annotations = prior
        selectedID = nil
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(document.annotations)
        document.annotations = next
        selectedID = nil
    }

    private func commitChange(_ change: (inout [Annotation]) -> Void) {
        undoStack.append(document.annotations)
        redoStack.removeAll()
        change(&document.annotations)
    }
}
