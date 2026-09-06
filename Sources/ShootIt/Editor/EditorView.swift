import AppKit
import SwiftUI

struct EditorActions {
    let copy: () -> Void
    let save: () -> Void
    let archiveIdea: () -> Void
    let discard: () -> Void
}

struct EditorView: View {
    @ObservedObject var store: EditorStore
    let actions: EditorActions

    var body: some View {
        VStack(spacing: 0) {
            EditorCanvas(store: store)
                .frame(minWidth: 640, minHeight: 400)
            Divider().opacity(0.35)
            toolbar
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDeleteCommand { store.deleteSelected() }
        .onChange(of: store.tool) { _, _ in store.commitTextEditing() }
    }

    private var toolbar: some View {
        HStack(spacing: 7) {
            ForEach(EditorTool.allCases) { tool in
                Button {
                    store.tool = tool
                } label: {
                    Image(systemName: tool.symbol)
                        .frame(width: 25, height: 25)
                }
                .buttonStyle(ToolButtonStyle(isSelected: store.tool == tool))
                .help(tool.title)
            }

            Divider().frame(height: 24)

            HStack(spacing: 5) {
                ForEach(Array(RGBAColor.palette.enumerated()), id: \.offset) { _, color in
                    Button {
                        store.color = color
                    } label: {
                        Circle()
                            .fill(Color(nsColor: color.nsColor))
                            .overlay(Circle().stroke(.white.opacity(store.color == color ? 1 : 0.25), lineWidth: store.color == color ? 2 : 1))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .help("Farbe wählen")
                }
            }

            Slider(value: $store.lineWidth, in: 2...12, step: 1)
                .frame(width: 82)
                .help("Strichstärke")
            Text("\(Int(store.lineWidth))")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Divider().frame(height: 24)

            Button(action: store.undo) { Image(systemName: "arrow.uturn.backward") }
                .disabled(!store.canUndo)
                .keyboardShortcut("z", modifiers: .command)
                .help("Rückgängig")
            Button(action: store.redo) { Image(systemName: "arrow.uturn.forward") }
                .disabled(!store.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .help("Wiederholen")

            Spacer(minLength: 12)

            Button("Idee", systemImage: "lightbulb", action: actions.archiveIdea)
                .help("Im Ideen-Ordner archivieren")
            Button("Verwerfen", action: actions.discard)
                .keyboardShortcut(.cancelAction)
            Button("Kopieren", action: actions.copy)
                .keyboardShortcut("c", modifiers: .command)
            Button("Sichern", action: actions.save)
                .keyboardShortcut("s", modifiers: .command)
                .buttonStyle(.borderedProminent)
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

}

private struct ToolButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(configuration.isPressed ? 0.12 : 0.001))
            )
    }
}
