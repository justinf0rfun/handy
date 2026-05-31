import Foundation

public enum AttentionAnchorSource: Sendable, Equatable {
    case focusedText
    case focusedElement
    case mouse
}

public struct AttentionAnchor: Sendable, Equatable {
    public let point: CGPoint
    public let source: AttentionAnchorSource

    public init(point: CGPoint, source: AttentionAnchorSource) {
        self.point = point
        self.source = source
    }
}

public enum AttentionAnchorPolicy {
    public static func resolve(
        focusedText: CGPoint?,
        focusedElement: CGPoint?,
        mouse: CGPoint
    ) -> AttentionAnchor {
        if let focusedText {
            return AttentionAnchor(point: focusedText, source: .focusedText)
        }
        if let focusedElement {
            return AttentionAnchor(point: focusedElement, source: .focusedElement)
        }
        return AttentionAnchor(point: mouse, source: .mouse)
    }
}
