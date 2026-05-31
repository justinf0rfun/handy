import AppKit
import ApplicationServices
import HandyCore

@MainActor
protocol AttentionAnchorResolving {
    func resolve(mouseLocation: CGPoint) -> AttentionAnchor
}

@MainActor
final class AccessibilityAttentionAnchorResolver: AttentionAnchorResolving {
    private let ownBundleIdentifier: String

    init(ownBundleIdentifier: String = Bundle.main.bundleIdentifier ?? "com.justin.handy.native") {
        self.ownBundleIdentifier = ownBundleIdentifier
    }

    func resolve(mouseLocation: CGPoint) -> AttentionAnchor {
        guard AXIsProcessTrusted() else {
            return AttentionAnchorPolicy.resolve(focusedText: nil, focusedElement: nil, mouse: mouseLocation)
        }

        guard let focusedElement = focusedUIElement(), !isOwnElement(focusedElement) else {
            return AttentionAnchorPolicy.resolve(focusedText: nil, focusedElement: nil, mouse: mouseLocation)
        }

        return AttentionAnchorPolicy.resolve(
            focusedText: focusedTextAnchor(in: focusedElement),
            focusedElement: focusedElementAnchor(focusedElement),
            mouse: mouseLocation
        )
    }

    private func focusedUIElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        return copyAttribute(kAXFocusedUIElementAttribute as CFString, from: systemWide) as! AXUIElement?
    }

    private func focusedTextAnchor(in element: AXUIElement) -> CGPoint? {
        guard let rangeValue = copyAttribute(kAXSelectedTextRangeAttribute as CFString, from: element) as! AXValue? else {
            return nil
        }

        var selectedRange = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &selectedRange) else {
            return nil
        }

        var caretRange = CFRange(location: selectedRange.location + selectedRange.length, length: 0)
        guard let caretValue = AXValueCreate(.cfRange, &caretRange) else {
            return nil
        }

        var rawBounds: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            caretValue,
            &rawBounds
        )

        guard result == .success,
              let boundsValue = rawBounds as! AXValue?,
              let bounds = rect(from: boundsValue)
        else {
            return nil
        }

        let rect = appKitRect(fromAccessibilityRect: bounds)
        guard rect.isFiniteAndUsable else { return nil }
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func focusedElementAnchor(_ element: AXUIElement) -> CGPoint? {
        guard let positionValue = copyAttribute(kAXPositionAttribute as CFString, from: element) as! AXValue?,
              let sizeValue = copyAttribute(kAXSizeAttribute as CFString, from: element) as! AXValue?,
              let position = point(from: positionValue),
              let size = size(from: sizeValue)
        else {
            return nil
        }

        let rect = appKitRect(fromAccessibilityRect: CGRect(origin: position, size: size))
        guard rect.isFiniteAndUsable else { return nil }
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func isOwnElement(_ element: AXUIElement) -> Bool {
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success,
              let app = NSRunningApplication(processIdentifier: pid)
        else {
            return false
        }
        return app.bundleIdentifier == ownBundleIdentifier
    }

    private func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value
    }

    private func point(from value: AXValue) -> CGPoint? {
        var point = CGPoint.zero
        guard AXValueGetValue(value, .cgPoint, &point) else { return nil }
        return point
    }

    private func size(from value: AXValue) -> CGSize? {
        var size = CGSize.zero
        guard AXValueGetValue(value, .cgSize, &size) else { return nil }
        return size
    }

    private func rect(from value: AXValue) -> CGRect? {
        var rect = CGRect.zero
        guard AXValueGetValue(value, .cgRect, &rect) else { return nil }
        return rect
    }

    private func appKitRect(fromAccessibilityRect rect: CGRect) -> CGRect {
        let desktopMaxY = NSScreen.screens.reduce(CGFloat.zero) { partial, screen in
            max(partial, screen.frame.maxY)
        }
        return CGRect(
            x: rect.minX,
            y: desktopMaxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}

private extension CGRect {
    var isFiniteAndUsable: Bool {
        origin.x.isFinite &&
        origin.y.isFinite &&
        size.width.isFinite &&
        size.height.isFinite &&
        width >= 0 &&
        height >= 0
    }
}
