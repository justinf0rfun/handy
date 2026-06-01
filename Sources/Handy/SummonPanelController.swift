import AppKit
import HandyCore
import SwiftUI

private struct PageQueryResult: Sendable {
    let items: [ContextItem]
    let hasMore: Bool
    let counts: [ContextFilter: Int]?
}

@MainActor
final class SummonPanelController {
    private let repository: any ContextRepository
    private let anchorResolver: any AttentionAnchorResolving
    private let state: PanelState
    private let panel: HandyPanel
    private let hostingController: NSHostingController<HandyPanelView>
    private let overlayController = AttentionOverlayController()
    private var previousApp: NSRunningApplication?
    private var localKeyMonitor: Any?
    private var currentPanelSize = HandyMetric.preferredPanelSize
    private var pendingQueryTask: Task<Void, Never>?
    private var queryRevision = 0
    private let pageSize = 24

    init(
        repository: any ContextRepository = CoreDataContextRepository(),
        anchorResolver: any AttentionAnchorResolving = AccessibilityAttentionAnchorResolver()
    ) {
        self.repository = repository
        self.anchorResolver = anchorResolver
        let initialPage = (try? repository.loadPage(offset: 0, limit: 24, filter: .all, search: "")) ?? ContextPage(items: [], hasMore: false)
        state = PanelState(
            initialItems: Self.normalizedItems(initialPage.items, repository: repository),
            hasMoreItems: initialPage.hasMore,
            filterCounts: Self.counts(search: "", repository: repository)
        )
        panel = HandyPanel(contentRect: CGRect(origin: .zero, size: HandyMetric.preferredPanelSize))
        hostingController = NSHostingController(
            rootView: HandyPanelView(
                state: state,
                panelSize: HandyMetric.preferredPanelSize,
                close: {}
            )
        )
        panel.contentViewController = hostingController
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        panel.delegate = panel

        state.onRequestClose = { [weak self] in
            self?.dismiss()
        }
        state.onFocusChange = { [weak self] target in
            self?.syncFirstResponder(for: target)
        }
        state.onDeleteItem = { [weak self] id in
            self?.deleteContextItem(id)
        }
        state.onQueryChanged = { [weak self] reason in
            self?.handleQueryChanged(reason)
        }
        state.onLoadMore = { [weak self] in
            self?.loadNextPage()
        }
        updateRootView()
    }

    func reloadContext() {
        pendingQueryTask?.cancel()
        reloadFirstPage(recomputeCounts: true)
    }

    nonisolated private static func normalizedItems(_ items: [ContextItem], repository: any ContextRepository) -> [ContextItem] {
        items.map { item in
            ClipboardCaptureService.normalizedStoredImageFile(item, repository: repository) ?? item
        }
    }

    private func deleteContextItem(_ id: String) {
        pendingQueryTask?.cancel()
        _ = try? repository.delete(id: id)
        reloadFirstPage(recomputeCounts: true)
    }

    private func handleQueryChanged(_ reason: PanelState.QueryChangeReason) {
        pendingQueryTask?.cancel()
        switch reason {
        case .filter:
            reloadFirstPage(recomputeCounts: false)
        case .clearSearch:
            reloadFirstPage(recomputeCounts: true)
        case .search:
            reloadFirstPage(recomputeCounts: true, debounceNanoseconds: 120_000_000)
        }
    }

    private func reloadFirstPage(recomputeCounts: Bool, debounceNanoseconds: UInt64 = 0) {
        pendingQueryTask?.cancel()
        queryRevision += 1

        let revision = queryRevision
        let filter = state.activeFilter
        let search = state.search
        let pageSize = pageSize
        let repository = repository

        pendingQueryTask = Task { [weak self] in
            if debounceNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: debounceNanoseconds)
            }
            guard !Task.isCancelled else { return }

            let result = await Task.detached(priority: .userInitiated) {
                Self.loadFirstPageResult(
                    repository: repository,
                    pageSize: pageSize,
                    filter: filter,
                    search: search,
                    recomputeCounts: recomputeCounts
                )
            }.value

            guard !Task.isCancelled else { return }
            self?.applyFirstPageResult(result, revision: revision)
        }
    }

    private func loadNextPage() {
        let revision = queryRevision
        let offset = state.items.count
        let filter = state.activeFilter
        let search = state.search
        let pageSize = pageSize
        let repository = repository

        Task { [weak self] in
            let result = await Task.detached(priority: .utility) {
                Self.loadPageResult(
                    repository: repository,
                    offset: offset,
                    pageSize: pageSize,
                    filter: filter,
                    search: search,
                    recomputeCounts: false
                )
            }.value

            guard let self, revision == self.queryRevision else { return }
            if let result {
                self.state.appendItems(result.items, hasMore: result.hasMore, counts: nil)
            } else {
                self.state.markLoadingMore(false)
            }
        }
    }

    nonisolated private static func loadFirstPageResult(
        repository: any ContextRepository,
        pageSize: Int,
        filter: ContextFilter,
        search: String,
        recomputeCounts: Bool
    ) -> PageQueryResult? {
        loadPageResult(
            repository: repository,
            offset: 0,
            pageSize: pageSize,
            filter: filter,
            search: search,
            recomputeCounts: recomputeCounts
        )
    }

    nonisolated private static func loadPageResult(
        repository: any ContextRepository,
        offset: Int,
        pageSize: Int,
        filter: ContextFilter,
        search: String,
        recomputeCounts: Bool
    ) -> PageQueryResult? {
        do {
            let page = try repository.loadPage(offset: offset, limit: pageSize, filter: filter, search: search)
            return PageQueryResult(
                items: normalizedItems(page.items, repository: repository),
                hasMore: page.hasMore,
                counts: recomputeCounts ? counts(search: search, repository: repository) : nil
            )
        } catch {
            return nil
        }
    }

    private func applyFirstPageResult(_ result: PageQueryResult?, revision: Int) {
        guard revision == queryRevision else { return }
        if let result {
            state.replaceItems(result.items, hasMore: result.hasMore, counts: result.counts)
        } else {
            state.replaceItems([], hasMore: false, counts: [:])
        }
    }

    nonisolated private static func counts(search: String, repository: any ContextRepository) -> [ContextFilter: Int] {
        Dictionary(uniqueKeysWithValues: ContextFilter.allCases.map { filter in
            (filter, (try? repository.countItems(filter: filter, search: search)) ?? 0)
        })
    }

    func toggleFromShortcut() {
        let mouse = NSEvent.mouseLocation
        if panel.isVisible {
            switch PanelInteractionPolicy.shortcutActionWhenVisible(pointerInsidePanel: panel.frame.contains(mouse)) {
            case .dismiss:
                dismiss()
            case .reposition:
                show(anchor: mouse, demoState: nil)
            }
            return
        }
        show(anchor: anchorResolver.resolve(mouseLocation: mouse).point, demoState: nil)
    }

    func show(anchor: CGPoint = NSEvent.mouseLocation, demoState: String? = nil) {
        previousApp = NSWorkspace.shared.frontmostApplication
        currentPanelSize = preferredPanelSize(for: anchor)
        let screen = screen(containing: anchor)
        let placement = PanelPositioner.place(
            anchor: anchor,
            panelSize: currentPanelSize,
            visibleFrame: screen.visibleFrame
        )

        panel.setFrame(placement.frame, display: false)
        updateRootView()
        overlayController.show(anchor: anchor, placement: placement)
        installEventMonitors()

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()
        state.prepareForOpen()

        if let demoState {
            state.applyDemoState(demoState)
        }

        state.beginReveal()
        animatePanelIn(placement: placement)
    }

    func dismiss() {
        guard panel.isVisible else { return }
        removeEventMonitors()
        state.markClosed()
        overlayController.hide()
        animatePanelOut()
    }

    private func preferredPanelSize(for anchor: CGPoint) -> CGSize {
        if let viewportSize = demoViewportSize() {
            return CGSize(
                width: min(HandyMetric.preferredPanelSize.width, viewportSize.width - 36),
                height: min(HandyMetric.preferredPanelSize.height, viewportSize.height - 36)
            )
        }

        let visible = screen(containing: anchor).visibleFrame
        return CGSize(
            width: min(HandyMetric.preferredPanelSize.width, visible.width - 36),
            height: min(HandyMetric.preferredPanelSize.height, visible.height - 36)
        )
    }

    private func demoViewportSize() -> CGSize? {
        let raw = ProcessInfo.processInfo.environment["HANDY_DEMO_VIEWPORT"]
        guard let raw, !raw.isEmpty else { return nil }
        let parts = raw.lowercased().split(separator: "x")
        guard parts.count == 2,
              let width = Double(parts[0]),
              let height = Double(parts[1])
        else { return nil }
        return CGSize(width: width, height: height)
    }

    private func updateRootView() {
        hostingController.rootView = HandyPanelView(
            state: state,
            panelSize: currentPanelSize,
            close: { [weak self] in self?.dismiss() }
        )
    }

    private func animatePanelIn(placement: PanelPlacement) {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.alphaValue = 1
            state.panelEntryAnimationDidComplete()
            return
        }

        guard let contentView = panel.contentView else {
            panel.alphaValue = 1
            state.panelEntryAnimationDidComplete()
            return
        }

        contentView.wantsLayer = true
        contentView.layoutSubtreeIfNeeded()

        if let layer = contentView.layer {
            setTransformOrigin(for: layer, placement: placement)
        }

        let xDrift: CGFloat = placement.placedRight ? -20 : 20
        let yDrift: CGFloat = placement.placedBelow ? 18 : -18
        let startingTransform = CATransform3DTranslate(CATransform3DMakeScale(0.925, 0.925, 1), xDrift, yDrift, 0)
        contentView.layer?.transform = startingTransform

        if let layer = contentView.layer {
            LayerAnimator.animateSpring(
                layer: layer,
                keyPath: "transform",
                from: startingTransform,
                to: CATransform3DIdentity,
                config: HandyMotionTokens.springSmooth,
                mass: 0.9,
                initialVelocity: 0.18
            )
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
            panel.animator().alphaValue = 1
        } completionHandler: {
            Task { @MainActor in
                self.state.panelEntryAnimationDidComplete()
            }
        }
    }

    private func animatePanelOut() {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.alphaValue = 0
            panel.orderOut(nil)
            panel.makeFirstResponder(nil)
            previousApp?.activate(options: [])
            return
        }

        let contentView = panel.contentView
        contentView?.wantsLayer = true
        let endingTransform = CATransform3DTranslate(CATransform3DMakeScale(0.985, 0.985, 1), 0, -8, 0)
        if let layer = contentView?.layer {
            LayerAnimator.animate(
                layer: layer,
                keyPath: "transform",
                from: layer.transform,
                to: endingTransform,
                duration: HandyMotionTokens.Duration.exit,
                timingFunction: CAMediaTimingFunction(name: .easeIn)
            )
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor in
                self.panel.orderOut(nil)
                self.panel.makeFirstResponder(nil)
                self.panel.contentView?.layer?.transform = CATransform3DIdentity
                self.previousApp?.activate(options: [])
            }
        }
    }

    private func setTransformOrigin(for layer: CALayer, placement: PanelPlacement) {
        let width = max(currentPanelSize.width, 1)
        let height = max(currentPanelSize.height, 1)
        let anchor = CGPoint(
            x: min(max(placement.transformOrigin.x / width, 0), 1),
            y: min(max(placement.transformOrigin.y / height, 0), 1)
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let frame = layer.frame
        layer.anchorPoint = anchor
        layer.frame = frame
        CATransaction.commit()
    }

    private func syncFirstResponder(for target: HandyFocusTarget) {
        guard target != .search else { return }
        DispatchQueue.main.async { [weak panel] in
            panel?.makeFirstResponder(nil)
        }
    }

    private func installEventMonitors() {
        removeEventMonitors()
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            guard event.type == .keyDown else { return event }
            if self.handlePanelKeyDown(event) {
                return nil
            }
            return event
        }
    }

    private func handlePanelKeyDown(_ event: NSEvent) -> Bool {
        let commandPrimary = isReturnKey(event) && (event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control))
        if commandPrimary {
            state.runPrimaryAction()
            return true
        }

        if event.keyCode == 53 {
            state.handleEscape()
            return true
        }

        if state.peekItemID == nil, state.draft != nil, isActivationKey(event) {
            state.copyDraft()
            return true
        }

        if state.peekItemID != nil, event.keyCode == 48 {
            state.cyclePeekFocus(backward: event.modifierFlags.contains(.shift))
            return true
        }

        if state.draft != nil, event.keyCode == 48 {
            state.requestFocus(.draftCopy)
            return true
        }

        switch state.focusTarget {
        case .search:
            if event.keyCode == 125 {
                state.focusActiveCard()
                return true
            }
            if isReturnKey(event) {
                state.handleSearchEnter()
                return true
            }
        case .card:
            switch event.keyCode {
            case 123:
                state.moveActiveCard(by: -1)
                return true
            case 124:
                state.moveActiveCard(by: 1)
                return true
            case 126:
                state.requestFocus(.search)
                return true
            case 115:
                state.focusRailEdge(end: false)
                return true
            case 119:
                state.focusRailEdge(end: true)
                return true
            case 35:
                state.openActivePeek()
                return true
            case 36, 49, 76:
                state.toggleActiveSelection()
                return true
            default:
                return false
            }
        case .peekClose, .peekPrimary, .peekCompose:
            if isActivationKey(event) {
                switch state.focusTarget {
                case .peekClose:
                    state.closePeek(restoreFocus: true)
                case .peekPrimary:
                    if let id = state.peekItemID {
                        state.toggleSelection(id, focusCard: false)
                        state.requestFocus(.peekPrimary)
                    }
                case .peekCompose:
                    if let id = state.peekItemID, !state.selectedIDs.contains(id) {
                        state.toggleSelection(id, focusCard: false)
                    }
                    state.composeDraft()
                default:
                    break
                }
                return true
            }
            if event.keyCode == 35 {
                state.openActivePeek()
                return true
            }
        case .draftCopy:
            if isActivationKey(event) {
                state.copyDraft()
                return true
            }
            return false
        }

        if event.keyCode == 35, !event.modifierFlags.contains(.command), !event.modifierFlags.contains(.control), !event.modifierFlags.contains(.option) {
            state.openActivePeek()
            return true
        }

        return false
    }

    private func isActivationKey(_ event: NSEvent) -> Bool {
        isReturnKey(event) || event.keyCode == 49
    }

    private func isReturnKey(_ event: NSEvent) -> Bool {
        event.keyCode == 36 || event.keyCode == 76 || event.charactersIgnoringModifiers == "\r" || event.charactersIgnoringModifiers == "\n"
    }

    private func removeEventMonitors() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }

    private func screen(containing point: CGPoint) -> NSScreen {
        NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main ?? NSScreen.screens[0]
    }
}

final class HandyPanel: NSPanel, NSWindowDelegate {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        canHide = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
