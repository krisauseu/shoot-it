import AppKit
import Combine
import Foundation

@MainActor
final class EditorStore: ObservableObject {
    @Published private(set) var document: ScreenshotDocument
    @Published var tool: EditorTool = .arrow
    @Published var color: RGBAColor
    @Published var lineWidth: CGFloat
    @Published var selectedID: UUID?
    @Published var draft: Annotation?

    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []
    private var moveOrigin: [Annotation]?

    init(document: ScreenshotDocument) {
        self.document = document
        color = Preferences.shared.defaultColor
        lineWidth = Preferences.shared.defaultLineWidth
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var hasChanges: Bool { !document.annotations.isEmpty }

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
            text: value
        )
        commitChange { $0.append(annotation) }
        selectedID = annotation.id
    }

    func select(at point: CGPoint, tolerance: CGFloat = 10) {
        selectedID = document.annotations.reversed().first(where: {
            AnnotationHitTesting.contains($0, point: point, tolerance: tolerance)
        })?.id
    }

    func beginMove() {
        guard selectedID != nil else { return }
        moveOrigin = document.annotations
    }

    func moveSelected(by delta: CGSize) {
        guard let id = selectedID, let origin = moveOrigin,
              let original = origin.first(where: { $0.id == id }),
              let index = document.annotations.firstIndex(where: { $0.id == id }) else { return }
        var moved = original
        moved.translate(by: delta)
        document.annotations[index] = moved
        objectWillChange.send()
    }

    func finishMove() {
        guard let origin = moveOrigin else { return }
        moveOrigin = nil
        guard origin != document.annotations else { return }
        undoStack.append(origin)
        redoStack.removeAll()
    }

    func deleteSelected() {
        guard let id = selectedID else { return }
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
