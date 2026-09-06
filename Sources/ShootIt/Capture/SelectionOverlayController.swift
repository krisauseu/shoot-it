import AppKit
import Foundation

@MainActor
final class SelectionOverlayController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var completion: ((CGRect?) -> Void)?

    func begin(completion: @escaping (CGRect?) -> Void) {
        guard window == nil else { return }
        guard let union = NSScreen.screens.map(\.frame).reduce(nil, { partial, frame in
            partial.map { $0.union(frame) } ?? frame
        }) else {
            completion(nil)
            return
        }

        self.completion = completion
        let overlay = SelectionOverlayView(frame: CGRect(origin: .zero, size: union.size))
        overlay.onFinish = { [weak self] localRect in
            guard let self else { return }
            let globalRect = localRect.map {
                CGRect(x: $0.minX + union.minX, y: $0.minY + union.minY, width: $0.width, height: $0.height)
            }
            self.finish(globalRect)
        }

        let window = NSWindow(
            contentRect: union,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = overlay
        window.delegate = self
        window.acceptsMouseMovedEvents = true
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    private func finish(_ selection: CGRect?) {
        guard let completion else { return }
        self.completion = nil
        window?.orderOut(nil)
        window = nil
        NSCursor.pop()
        completion(selection)
    }
}

private final class SelectionOverlayView: NSView {
    var onFinish: ((CGRect?) -> Void)?
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var cursorPushed = false

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        if !cursorPushed {
            NSCursor.crosshair.push()
            cursorPushed = true
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        if let rect = selectionRect, rect.width >= 3, rect.height >= 3 {
            onFinish?(rect)
        } else {
            startPoint = nil
            currentPoint = nil
            needsDisplay = true
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onFinish?(nil)
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.38).setFill()
        bounds.fill()

        guard let rect = selectionRect else {
            drawHint()
            return
        }

        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: rect).addClip()
        NSColor.clear.setFill()
        rect.fill(using: .copy)
        NSGraphicsContext.current?.restoreGraphicsState()

        let outline = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        outline.lineWidth = 1
        NSColor.white.withAlphaComponent(0.95).setStroke()
        outline.stroke()
        drawSizeLabel(for: rect)
    }

    private var selectionRect: CGRect? {
        guard let startPoint, let currentPoint else { return nil }
        return CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }

    private func drawHint() {
        let text = "Bereich aufziehen  •  Esc zum Abbrechen"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        let rect = CGRect(x: bounds.midX - size.width / 2 - 14, y: bounds.midY - size.height / 2 - 9,
                          width: size.width + 28, height: size.height + 18)
        NSColor.black.withAlphaComponent(0.65).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()
        text.draw(at: CGPoint(x: rect.minX + 14, y: rect.minY + 9), withAttributes: attributes)
    }

    private func drawSizeLabel(for rect: CGRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        var origin = CGPoint(x: rect.minX, y: rect.minY - size.height - 12)
        if origin.y < 8 { origin.y = rect.maxY + 8 }
        let background = CGRect(origin: CGPoint(x: origin.x - 7, y: origin.y - 4),
                                size: CGSize(width: size.width + 14, height: size.height + 8))
        NSColor.black.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: background, xRadius: 5, yRadius: 5).fill()
        text.draw(at: origin, withAttributes: attributes)
    }
}
