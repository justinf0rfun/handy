import AppKit
import HandyCore
import SwiftUI

@MainActor
final class AttentionOverlayController {
    private let window: NSWindow
    private let hosting: NSHostingController<AttentionOverlayView>

    init() {
        hosting = NSHostingController(rootView: AttentionOverlayView(anchor: .zero, attach: .zero))
        window = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        window.contentViewController = hosting
        window.alphaValue = 0
    }

    func show(anchor: CGPoint, placement: PanelPlacement) {
        let bounds = CGRect(
            x: min(anchor.x, placement.attachPoint.x) - 14,
            y: min(anchor.y, placement.attachPoint.y) - 14,
            width: abs(anchor.x - placement.attachPoint.x) + 28,
            height: abs(anchor.y - placement.attachPoint.y) + 28
        )
        window.setFrame(bounds, display: true)
        hosting.rootView = AttentionOverlayView(
            anchor: CGPoint(x: anchor.x - bounds.minX, y: bounds.maxY - anchor.y),
            attach: CGPoint(x: placement.attachPoint.x - bounds.minX, y: bounds.maxY - placement.attachPoint.y)
        )
        window.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window.animator().alphaValue = 1
        }
    }

    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor in
                self.window.orderOut(nil)
            }
        }
    }
}

struct AttentionOverlayView: View {
    let anchor: CGPoint
    let attach: CGPoint

    var body: some View {
        Canvas { context, _ in
            var path = Path()
            path.move(to: anchor)
            path.addLine(to: attach)
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [HandyVisualTokens.Colors.accentPrimary.opacity(0.72), .clear]),
                    startPoint: anchor,
                    endPoint: attach
                ),
                lineWidth: 1
            )
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(HandyVisualTokens.Colors.accentPrimary)
                .frame(width: 10, height: 10)
                .shadow(color: HandyVisualTokens.Colors.accentPrimary.opacity(0.22), radius: 7)
                .position(anchor)
        }
    }
}
