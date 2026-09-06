import Foundation

enum EditorTool: String, CaseIterable, Identifiable {
    case pointer
    case arrow
    case line
    case rectangle
    case ellipse
    case freehand
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pointer: "Auswahl"
        case .arrow: "Pfeil"
        case .line: "Linie"
        case .rectangle: "Rechteck"
        case .ellipse: "Ellipse"
        case .freehand: "Stift"
        case .text: "Text"
        }
    }

    var symbol: String {
        switch self {
        case .pointer: "arrow.up.left"
        case .arrow: "arrow.up.right"
        case .line: "line.diagonal"
        case .rectangle: "rectangle"
        case .ellipse: "circle"
        case .freehand: "pencil.tip"
        case .text: "textformat"
        }
    }

    var annotationKind: AnnotationKind? {
        switch self {
        case .pointer: nil
        case .arrow: .arrow
        case .line: .line
        case .rectangle: .rectangle
        case .ellipse: .ellipse
        case .freehand: .freehand
        case .text: .text
        }
    }
}
