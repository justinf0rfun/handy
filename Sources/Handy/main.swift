import AppKit
import HandyCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let repository = CoreDataContextRepository()
    private lazy var panelController = SummonPanelController(repository: repository)
    private lazy var clipboardCapture = ClipboardCaptureService(repository: repository)
    private let shortcutManager = ShortcutManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        shortcutManager.start { [weak self] in
            self?.panelController.toggleFromShortcut()
        }
        clipboardCapture.onItemsChanged = { [weak self] _ in
            self?.panelController.reloadContext()
        }
        clipboardCapture.start()

        if let demoState = demoStateArgument() {
            DispatchQueue.main.async { [self] in
                self.panelController.show(anchor: self.demoAnchor(for: demoState), demoState: demoState)
            }
        }
    }

    private func demoStateArgument() -> String? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "--demo") else { return nil }
        let next = args.index(after: index)
        return args.indices.contains(next) ? args[next] : "default"
    }

    private func demoAnchor(for state: String) -> CGPoint {
        guard let visible = NSScreen.main?.visibleFrame else { return NSEvent.mouseLocation }
        switch state {
        case "mouse":
            return NSEvent.mouseLocation
        case "edge-top-left":
            return CGPoint(x: visible.minX + 34, y: visible.maxY - 34)
        case "edge-top-right":
            return CGPoint(x: visible.maxX - 34, y: visible.maxY - 34)
        case "edge-bottom-left":
            return CGPoint(x: visible.minX + 34, y: visible.minY + 34)
        case "edge-bottom-right":
            return CGPoint(x: visible.maxX - 34, y: visible.minY + 34)
        default:
            return CGPoint(x: visible.minX + visible.width * 0.68, y: visible.minY + visible.height * 0.66)
        }
    }
}

let delegate = AppDelegate()
let app = NSApplication.shared
app.appearance = NSAppearance(named: .darkAqua)
app.delegate = delegate
app.run()
