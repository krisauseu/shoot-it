import SwiftUI

struct PreferencesView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section("Aufnahme") {
                LabeledContent("Globale Tastenkombination") {
                    HotKeyRecorder(keyCode: $preferences.hotKeyCode, modifiers: $preferences.hotKeyModifiers)
                        .frame(width: 190, height: 28)
                }
                Text("Klicke auf die Tastenkombination und drücke eine neue Kombination mit mindestens einer Sondertaste.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Ideen") {
                LabeledContent("Zielordner") {
                    HStack {
                        Text(preferences.ideaFolderURL.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 240, alignment: .trailing)
                        Button("Wählen …") { preferences.chooseIdeaFolder() }
                    }
                }
            }

            Section("Editor") {
                LabeledContent("Standardfarbe") {
                    HStack(spacing: 6) {
                        ForEach(Array(RGBAColor.palette.enumerated()), id: \.offset) { _, color in
                            Button {
                                preferences.defaultColor = color
                            } label: {
                                Circle()
                                    .fill(Color(nsColor: color.nsColor))
                                    .overlay(Circle().stroke(.primary.opacity(preferences.defaultColor == color ? 0.9 : 0.2), lineWidth: 2))
                                    .frame(width: 18, height: 18)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                LabeledContent("Standard-Strichstärke") {
                    HStack {
                        Slider(value: $preferences.defaultLineWidth, in: 2...12, step: 1)
                            .frame(width: 150)
                        Text("\(Int(preferences.defaultLineWidth)) px")
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                Toggle("Editor nach dem Kopieren schließen", isOn: $preferences.closeAfterCopy)
            }
        }
        .formStyle(.grouped)
        .padding(8)
    }
}
