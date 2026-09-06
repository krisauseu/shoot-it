import AppKit
import SwiftUI

struct InlineTextEditor: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let color: NSColor
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> InlineTextEditorContainer {
        let container = InlineTextEditorContainer()
        let scrollView = container.scrollView
        let textView = container.textView
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textContainerInset = CGSize(width: 5, height: 4)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.string = text
        textView.onCommit = onCommit
        textView.onCancel = onCancel

        scrollView.borderType = .lineBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.94)
        scrollView.hasVerticalScroller = true
        return container
    }

    func updateNSView(_ container: InlineTextEditorContainer, context: Context) {
        let scrollView = container.scrollView
        let textView = container.textView
        textView.font = .systemFont(ofSize: fontSize, weight: .semibold)
        textView.textColor = color
        textView.insertionPointColor = color
        scrollView.backgroundColor = editorBackground(for: color)
        textView.onCommit = onCommit
        textView.onCancel = onCancel
        if textView.string != text {
            textView.string = text
        }
        container.needsLayout = true
    }

    private func editorBackground(for color: NSColor) -> NSColor {
        guard let rgb = color.usingColorSpace(.sRGB) else { return .textBackgroundColor }
        let luminance = 0.2126 * rgb.redComponent + 0.7152 * rgb.greenComponent + 0.0722 * rgb.blueComponent
        return luminance > 0.48
            ? NSColor.black.withAlphaComponent(0.86)
            : NSColor.white.withAlphaComponent(0.94)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

final class InlineTextEditorContainer: NSView {
    let scrollView = NSScrollView()
    let textView = KeyHandlingTextView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        scrollView.documentView = textView
        addSubview(scrollView)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds
        let contentSize = scrollView.contentSize
        textView.minSize = CGSize(width: 0, height: contentSize.height)
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.containerSize = CGSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        if let textContainer = textView.textContainer, let layoutManager = textView.layoutManager {
            layoutManager.ensureLayout(for: textContainer)
            let usedHeight = layoutManager.usedRect(for: textContainer).height + textView.textContainerInset.height * 2
            textView.frame = CGRect(
                origin: .zero,
                size: CGSize(width: contentSize.width, height: max(contentSize.height, ceil(usedHeight)))
            )
        }
    }
}

final class KeyHandlingTextView: NSTextView {
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?
    private var needsInitialFocus = true

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard needsInitialFocus, let window else { return }
        needsInitialFocus = false
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window else { return }
            window.makeFirstResponder(self)
            setSelectedRange(NSRange(location: string.utf16.count, length: 0))
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 {
            if event.modifierFlags.contains(.shift) {
                insertNewline(nil)
            } else {
                onCommit?()
            }
        } else if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }
}
