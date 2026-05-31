import CoreGraphics

public struct PanelPlacement: Equatable, Sendable {
    public let frame: CGRect
    public let attachPoint: CGPoint
    public let transformOrigin: CGPoint
    public let placedRight: Bool
    public let placedBelow: Bool
}

public enum PanelPositioner {
    public static let safeMargin: CGFloat = 18
    public static let pointerGap: CGFloat = 18
    public static let attachmentInset: CGFloat = 26

    public static func place(
        anchor: CGPoint,
        panelSize: CGSize,
        visibleFrame: CGRect,
        safeMargin: CGFloat = safeMargin,
        pointerGap: CGFloat = pointerGap,
        attachmentInset: CGFloat = attachmentInset
    ) -> PanelPlacement {
        let insetFrame = visibleFrame.insetBy(dx: safeMargin, dy: safeMargin)
        let placedRight = anchor.x + pointerGap + panelSize.width <= insetFrame.maxX
        let placedBelow = anchor.y - pointerGap - panelSize.height >= insetFrame.minY

        var x = placedRight ? anchor.x + pointerGap : anchor.x - panelSize.width - pointerGap
        var y = placedBelow ? anchor.y - panelSize.height - pointerGap : anchor.y + pointerGap

        x = clamp(x, insetFrame.minX, insetFrame.maxX - panelSize.width)
        y = clamp(y, insetFrame.minY, insetFrame.maxY - panelSize.height)

        let frame = CGRect(origin: CGPoint(x: x, y: y), size: panelSize)
        let attachPoint = CGPoint(
            x: clamp(anchor.x, frame.minX + attachmentInset, frame.maxX - attachmentInset),
            y: clamp(anchor.y, frame.minY + attachmentInset, frame.maxY - attachmentInset)
        )
        let origin = CGPoint(
            x: placedRight ? 0 : panelSize.width,
            y: placedBelow ? panelSize.height : 0
        )

        return PanelPlacement(
            frame: frame,
            attachPoint: attachPoint,
            transformOrigin: origin,
            placedRight: placedRight,
            placedBelow: placedBelow
        )
    }

    private static func clamp(_ value: CGFloat, _ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
        guard minValue <= maxValue else { return minValue }
        return min(max(value, minValue), maxValue)
    }
}
