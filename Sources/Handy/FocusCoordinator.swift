import Foundation

@MainActor
final class FocusCoordinator {
    private(set) var target: HandyFocusTarget

    init(initialTarget: HandyFocusTarget = .search) {
        target = initialTarget
    }

    func request(_ target: HandyFocusTarget) -> HandyFocusTarget {
        self.target = target
        return target
    }

    func animationCompleted(focus target: HandyFocusTarget) -> HandyFocusTarget {
        request(target)
    }
}
