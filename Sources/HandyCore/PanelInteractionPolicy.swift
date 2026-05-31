public enum VisibleShortcutAction: Equatable, Sendable {
    case dismiss
    case reposition
}

public enum PanelInteractionPolicy {
    public static func shortcutActionWhenVisible(pointerInsidePanel: Bool) -> VisibleShortcutAction {
        pointerInsidePanel ? .dismiss : .reposition
    }

    public static func shouldDismissForExternalPointerDown() -> Bool {
        false
    }
}
