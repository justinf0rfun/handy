import AppKit
import HandyCore
import SwiftUI

@MainActor
enum ContextPasteboardPayload {
    static let pngType = NSPasteboard.PasteboardType("public.png")
    static let fileNamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")

    @discardableResult
    static func write(_ item: ContextItem, to pasteboard: NSPasteboard, markInternal: Bool) -> Bool {
        pasteboard.clearContents()
        let didWrite = writePayload(item, to: pasteboard)
        if didWrite, markInternal {
            pasteboard.setString(item.id, forType: HandyPasteboardWriter.internalCopyType)
        }
        return didWrite
    }

    static func draggingPasteboardItem(for item: ContextItem) -> NSPasteboardItem? {
        let pasteboardItem = NSPasteboardItem()
        var didWrite = false

        switch item.type {
        case .image:
            didWrite = writeImage(item, to: pasteboardItem)
            if !didWrite {
                didWrite = writeString(stringContent(for: item), to: pasteboardItem)
            }
        case .file:
            didWrite = writeFileURL(item.preview, to: pasteboardItem)
            didWrite = writeString(stringContent(for: item), to: pasteboardItem) || didWrite
        case .url:
            didWrite = writeURL(item.preview, to: pasteboardItem)
            didWrite = writeString(stringContent(for: item), to: pasteboardItem) || didWrite
        case .text, .code, .thought:
            didWrite = writeString(stringContent(for: item), to: pasteboardItem)
        }

        if didWrite {
            pasteboardItem.setString(item.id, forType: HandyPasteboardWriter.internalCopyType)
        }
        return didWrite ? pasteboardItem : nil
    }

    static func stringContent(for item: ContextItem) -> String {
        switch item.type {
        case .url, .file:
            item.preview
        case .image:
            FileManager.default.fileExists(atPath: item.preview) ? item.preview : item.title
        case .text, .code, .thought:
            item.preview.isEmpty ? item.title : item.preview
        }
    }

    private static func writePayload(_ item: ContextItem, to pasteboard: NSPasteboard) -> Bool {
        switch item.type {
        case .image:
            guard let image = image(for: item) else {
                return pasteboard.setString(stringContent(for: item), forType: .string)
            }
            if let path = storedImagePath(for: item) {
                return pasteboard.writeObjects([URL(fileURLWithPath: path) as NSURL, image])
            }
            return pasteboard.writeObjects([image])
        case .file:
            let url = URL(fileURLWithPath: item.preview)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return pasteboard.setString(stringContent(for: item), forType: .string)
            }
            return pasteboard.writeObjects([url as NSURL])
        case .url, .text, .code, .thought:
            return pasteboard.setString(stringContent(for: item), forType: .string)
        }
    }

    private static func writeImage(_ item: ContextItem, to pasteboardItem: NSPasteboardItem) -> Bool {
        var didWrite = false
        if let path = storedImagePath(for: item) {
            didWrite = writeFileURL(path, to: pasteboardItem)
        }
        guard let image = image(for: item) else { return false }
        if let tiff = image.tiffRepresentation {
            pasteboardItem.setData(tiff, forType: .tiff)
            didWrite = true
        }
        if let png = pngData(for: image) {
            pasteboardItem.setData(png, forType: pngType)
            didWrite = true
        }
        return didWrite
    }

    private static func writeURL(_ string: String, to pasteboardItem: NSPasteboardItem) -> Bool {
        guard let url = URL(string: string), let scheme = url.scheme, !scheme.isEmpty else { return false }
        pasteboardItem.setString(url.absoluteString, forType: .URL)
        return true
    }

    private static func writeFileURL(_ path: String, to pasteboardItem: NSPasteboardItem) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        pasteboardItem.setString(url.absoluteString, forType: .fileURL)
        pasteboardItem.setPropertyList([url.path], forType: fileNamesType)
        return true
    }

    private static func writeString(_ string: String, to pasteboardItem: NSPasteboardItem) -> Bool {
        guard !string.isEmpty else { return false }
        pasteboardItem.setString(string, forType: .string)
        return true
    }

    static func image(for item: ContextItem) -> NSImage? {
        item.thumbnailPath.flatMap(CachedImageLoader.image(contentsOfFile:))
            ?? (FileManager.default.fileExists(atPath: item.preview) ? CachedImageLoader.image(contentsOfFile: item.preview) : nil)
    }

    private static func storedImagePath(for item: ContextItem) -> String? {
        if FileManager.default.fileExists(atPath: item.preview) {
            return item.preview
        }
        if let thumbnailPath = item.thumbnailPath, FileManager.default.fileExists(atPath: thumbnailPath) {
            return thumbnailPath
        }
        return nil
    }

    private static func pngData(for image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

@MainActor
enum ContextDragPreviewFactory {
    static func preview(for item: ContextItem) -> NSImage {
        let size = CGSize(width: item.dragPreviewIsVisual ? 58 : 50, height: item.dragPreviewIsVisual ? 58 : 50)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = CGRect(origin: .zero, size: size)
        NSGraphicsContext.current?.imageInterpolation = .high

        if item.dragPreviewIsVisual, let sourceImage = ContextPasteboardPayload.image(for: item) {
            drawRoundedImage(sourceImage, in: rect, radius: 9)
        } else {
            drawTypeTile(for: item, in: rect)
        }

        return image
    }

    private static func drawRoundedImage(_ image: NSImage, in rect: CGRect, radius: CGFloat) {
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        NSColor.black.withAlphaComponent(0.18).setStroke()
        let stroke = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
        stroke.lineWidth = 1
        stroke.stroke()
    }

    private static func drawTypeTile(for item: ContextItem, in rect: CGRect) {
        let accent = NSColor(Color(hex: item.accent)).withAlphaComponent(0.70)
        let background = NSColor.white.withAlphaComponent(0.16)
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        background.setFill()
        path.fill()
        accent.setFill()
        path.fill()

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 23, weight: .semibold)
        let symbol = NSImage(systemSymbolName: symbolName(for: item), accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfig)
        let symbolSize = symbol?.size ?? CGSize(width: 24, height: 24)
        let symbolRect = CGRect(
            x: rect.midX - symbolSize.width / 2,
            y: rect.midY - symbolSize.height / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        symbol?.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.92)
    }

    private static func symbolName(for item: ContextItem) -> String {
        switch item.type {
        case .url: "link"
        case .image: "photo"
        case .file: "doc.text"
        case .code: "curlybraces"
        case .thought: "quote.opening"
        case .text: "text.alignleft"
        }
    }
}

private extension ContextItem {
    var dragPreviewIsVisual: Bool {
        switch type {
        case .image, .url, .file:
            true
        case .text, .code, .thought:
            false
        }
    }
}

struct ContextCardDragBridge: NSViewRepresentable {
    let item: ContextItem
    let onClick: @MainActor () -> Void
    let onDragBegan: @MainActor () -> Void
    let onDragEnded: @MainActor (Bool) -> Void

    func makeNSView(context: Context) -> DragSourceView {
        let view = DragSourceView()
        view.configure(
            item: item,
            onClick: onClick,
            onDragBegan: onDragBegan,
            onDragEnded: onDragEnded
        )
        return view
    }

    func updateNSView(_ nsView: DragSourceView, context: Context) {
        nsView.configure(
            item: item,
            onClick: onClick,
            onDragBegan: onDragBegan,
            onDragEnded: onDragEnded
        )
    }
}

@MainActor
final class DragSourceView: NSView, NSDraggingSource {
    private var item: ContextItem?
    private var onClick: (@MainActor () -> Void)?
    private var onDragBegan: (@MainActor () -> Void)?
    private var onDragEnded: (@MainActor (Bool) -> Void)?
    private var mouseDownEvent: NSEvent?
    private var didStartDrag = false

    override var acceptsFirstResponder: Bool { false }

    func configure(
        item: ContextItem,
        onClick: @escaping @MainActor () -> Void,
        onDragBegan: @escaping @MainActor () -> Void,
        onDragEnded: @escaping @MainActor (Bool) -> Void
    ) {
        self.item = item
        self.onClick = onClick
        self.onDragBegan = onDragBegan
        self.onDragEnded = onDragEnded
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didStartDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !didStartDrag,
              let mouseDownEvent,
              let item,
              hypot(event.locationInWindow.x - mouseDownEvent.locationInWindow.x, event.locationInWindow.y - mouseDownEvent.locationInWindow.y) >= 4,
              let pasteboardItem = ContextPasteboardPayload.draggingPasteboardItem(for: item)
        else { return }

        didStartDrag = true
        onDragBegan?()

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let preview = ContextDragPreviewFactory.preview(for: item)
        let localPoint = convert(mouseDownEvent.locationInWindow, from: nil)
        let previewSize = preview.size
        let previewRect = CGRect(
            x: localPoint.x - previewSize.width / 2,
            y: localPoint.y - previewSize.height / 2,
            width: previewSize.width,
            height: previewSize.height
        )
        draggingItem.setDraggingFrame(previewRect, contents: preview)
        let session = beginDraggingSession(with: [draggingItem], event: mouseDownEvent, source: self)
        session.draggingFormation = .none
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func mouseUp(with event: NSEvent) {
        guard !didStartDrag else { return }
        onClick?()
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        let succeeded = operation.contains(.copy) || operation.contains(.generic) || operation.contains(.move)
        onDragEnded?(succeeded)
        mouseDownEvent = nil
        didStartDrag = false
    }
}
