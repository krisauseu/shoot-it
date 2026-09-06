import AppKit
import SwiftUI

struct HotKeyRecorder: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.onRecord = { key, flags in
            keyCode = key
            modifiers = HotKeyDisplay.carbonModifiers(from: flags)
        }
        button.update(keyCode: keyCode, modifiers: modifiers)
        return button
    }

    func updateNSView(_ nsView: RecorderButton, context: Context) {
        nsView.update(keyCode: keyCode, modifiers: modifiers)
    }
}

final class RecorderButton: NSButton {
    var onRecord: ((UInt32, NSEvent.ModifierFlags) -> Void)?
    private var recording = false
    private var previousTitle = ""

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        previousTitle = title
        recording = true
        title = "Tastenkombination drücken"
        bezelColor = .controlAccentColor
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard recording else { return super.keyDown(with: event) }
        if event.keyCode == 53 {
            recording = false
            bezelColor = nil
            title = previousTitle
            return
        }
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard !flags.isEmpty else {
            NSSound.beep()
            return
        }
        recording = false
        bezelColor = nil
        onRecord?(UInt32(event.keyCode), flags)
    }

    func update(keyCode: UInt32, modifiers: UInt32) {
        guard !recording else { return }
        title = HotKeyDisplay.string(keyCode: keyCode, modifiers: modifiers)
    }
}
