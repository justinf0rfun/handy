import AppKit
import HandyCore

@MainActor
enum HandyPasteboardWriter {
    static let internalCopyType = NSPasteboard.PasteboardType("com.justin.handy.internal-copy")

    @discardableResult
    static func copy(_ item: ContextItem, to pasteboard: NSPasteboard = .general) -> Bool {
        ContextPasteboardPayload.write(item, to: pasteboard, markInternal: true)
    }

    @discardableResult
    static func copyString(_ string: String, id: String = "draft", to pasteboard: NSPasteboard = .general) -> Bool {
        pasteboard.clearContents()
        let didWrite = pasteboard.setString(string, forType: .string)
        if didWrite {
            pasteboard.setString(id, forType: internalCopyType)
        }
        return didWrite
    }

    static func isInternalCopy(_ pasteboard: NSPasteboard = .general) -> Bool {
        pasteboard.string(forType: internalCopyType) != nil
    }

}
