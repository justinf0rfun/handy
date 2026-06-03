import AppKit
import HandyCore
import SwiftUI

enum HandyFocusTarget: Hashable {
    case search
    case card(String)
    case peekClose
    case peekPrimary
    case peekCompose
    case draftCopy
}

@MainActor
final class PanelState: ObservableObject {
    enum QueryChangeReason {
        case filter
        case search
        case clearSearch
    }

    @Published var isVisible = false
    @Published var revealContent = false
    @Published var activeFilter: ContextFilter = .all
    @Published var search = ""
    @Published var goal = HandyFixtures.defaultGoal
    @Published var selectedIDs = HandyFixtures.defaultSelectedIDs
    @Published var intent = HandyFixtures.defaultIntent
    @Published var activeItemID = HandyFixtures.defaultActiveID
    @Published var peekItemID: String?
    @Published var draft: String?
    @Published var copied = false
    @Published var focusTarget: HandyFocusTarget = .search
    @Published var demoHoverID: String?
    @Published var railOffset: CGFloat = 0
    @Published var galleryResetToken = 0
    @Published var invalidComposeNudge = 0
    @Published var selectionPulseID: String?
    @Published var selectionPulseToken = 0
    @Published var copiedItemID: String?
    @Published var draggingItemID: String?

    var onRequestClose: (() -> Void)?
    var onFocusChange: ((HandyFocusTarget) -> Void)?
    var onDeleteItem: ((String) -> Void)?
    var onQueryChanged: ((QueryChangeReason) -> Void)?
    var onLoadMore: (() -> Void)?

    private let focusCoordinator = FocusCoordinator()
    private var clearCopiedItemTask: Task<Void, Never>?

    @Published private(set) var items: [ContextItem]
    @Published private(set) var hasMoreItems = false
    @Published private(set) var isLoadingMoreItems = false
    @Published private(set) var filterCounts: [ContextFilter: Int] = [:]
    let intents = HandyFixtures.intents

    init(initialItems: [ContextItem] = [], hasMoreItems: Bool = false, filterCounts: [ContextFilter: Int] = [:]) {
        items = initialItems
        self.hasMoreItems = hasMoreItems
        self.filterCounts = filterCounts
        selectedIDs = selectedIDs.intersection(Set(initialItems.map(\.id)))
        syncActiveItem()
    }

    var filteredItems: [ContextItem] {
        items
    }

    var selectedItems: [ContextItem] {
        items.filter { selectedIDs.contains($0.id) }
    }

    var activePeekItem: ContextItem? {
        guard let peekItemID else { return nil }
        return items.first { $0.id == peekItemID }
    }

    func count(for filter: ContextFilter) -> Int {
        filterCounts[filter] ?? 0
    }

    func replaceItems(_ newItems: [ContextItem], hasMore: Bool = false, counts: [ContextFilter: Int]? = nil) {
        items = newItems
        hasMoreItems = hasMore
        isLoadingMoreItems = false
        if let counts {
            filterCounts = counts
        }
        selectedIDs = selectedIDs.intersection(Set(items.map(\.id)))
        if let copiedItemID, !items.contains(where: { $0.id == copiedItemID }) {
            self.copiedItemID = nil
        }
        if let draggingItemID, !items.contains(where: { $0.id == draggingItemID }) {
            self.draggingItemID = nil
        }
        clearDraft()
        closePeek()
        resetGalleryScroll()
        syncActiveItem()
    }

    func appendItems(_ nextItems: [ContextItem], hasMore: Bool, counts: [ContextFilter: Int]? = nil) {
        let existingIDs = Set(items.map(\.id))
        items.append(contentsOf: nextItems.filter { !existingIDs.contains($0.id) })
        hasMoreItems = hasMore
        isLoadingMoreItems = false
        if let counts {
            filterCounts = counts
        }
        syncActiveItem()
    }

    func markLoadingMore(_ loading: Bool) {
        isLoadingMoreItems = loading
    }

    func prepareForOpen() {
        isVisible = true
        revealContent = false
        resetGalleryScroll()
        syncActiveItem()
        requestFocus(.search)
    }

    func beginReveal() {
        revealContent = true
    }

    func panelEntryAnimationDidComplete() {
        requestFocus(focusCoordinator.animationCompleted(focus: .search))
    }

    func markClosed() {
        isVisible = false
        revealContent = false
        copiedItemID = nil
        draggingItemID = nil
        clearCopiedItemTask?.cancel()
        requestFocus(.search)
    }

    func setFilter(_ filter: ContextFilter) {
        guard activeFilter != filter else { return }
        activeFilter = filter
        clearDraft()
        closePeek()
        resetGalleryScroll()
        onQueryChanged?(.filter)
    }

    func searchChanged() {
        clearDraft()
        closePeek()
        onQueryChanged?(.search)
    }

    func loadMoreIfNeeded(visibleEndIndex: Int) {
        guard hasMoreItems, !isLoadingMoreItems else { return }
        let preloadThreshold = max(items.count - 6, 0)
        guard visibleEndIndex >= preloadThreshold else { return }
        isLoadingMoreItems = true
        onLoadMore?()
    }

    func syncActiveItem() {
        if filteredItems.contains(where: { $0.id == activeItemID }) { return }
        activeItemID = filteredItems.first?.id ?? ""
    }

    func activateItemFromHover(_ id: String) {
        guard activeItemID != id else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.activeItemID != id else { return }
            self.activeItemID = id
        }
    }

    func toggleSelection(_ id: String, focusCard: Bool = true) {
        activeItemID = id
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
            triggerSelectionPulse(id)
        }
        clearDraft()
        if focusCard {
            requestFocus(.card(id))
        }
    }

    func removeSelection(_ id: String) {
        selectedIDs.remove(id)
        clearDraft()
        if let next = selectedItems.first?.id {
            requestFocus(.card(next))
        } else {
            requestFocus(.search)
        }
    }

    func deleteItem(_ id: String) {
        onDeleteItem?(id)
    }

    func openPeek(_ id: String) {
        activeItemID = id
        peekItemID = id
        requestFocus(.peekPrimary)
    }

    @discardableResult
    func closePeek(restoreFocus: Bool = false) -> Bool {
        guard let closingID = peekItemID else { return false }
        peekItemID = nil
        if restoreFocus {
            requestFocus(.card(closingID))
        }
        return true
    }

    func focusActiveCard() {
        guard !activeItemID.isEmpty else { return }
        requestFocus(.card(activeItemID))
    }

    func handleSearchEnter() {
        guard !activeItemID.isEmpty else { return }
        if selectedIDs.contains(activeItemID) {
            requestFocus(.card(activeItemID))
        } else {
            toggleSelection(activeItemID)
        }
    }

    func moveActiveCard(by delta: Int) {
        let items = filteredItems
        guard let currentIndex = items.firstIndex(where: { $0.id == activeItemID }) else {
            syncActiveItem()
            focusActiveCard()
            return
        }
        let nextIndex = min(max(currentIndex + delta, 0), items.count - 1)
        activeItemID = items[nextIndex].id
        requestFocus(.card(activeItemID))
    }

    func focusRailEdge(end: Bool) {
        guard let item = end ? filteredItems.last : filteredItems.first else { return }
        activeItemID = item.id
        requestFocus(.card(item.id))
    }

    func toggleActiveSelection() {
        guard !activeItemID.isEmpty else { return }
        toggleSelection(activeItemID)
    }

    func copyItem(_ id: String) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        activeItemID = id
        guard HandyPasteboardWriter.copy(item) else { return }
        markItemCopied(id)
    }

    func beginDraggingItem(_ id: String) {
        activeItemID = id
        draggingItemID = id
        clearCopiedItemTask?.cancel()
        copiedItemID = nil
    }

    func finishDraggingItem(_ id: String, succeeded: Bool) {
        if draggingItemID == id {
            draggingItemID = nil
        }
        guard succeeded else { return }
        markItemCopied(id)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 160_000_000)
            guard !Task.isCancelled else { return }
            self?.onRequestClose?()
        }
    }

    private func markItemCopied(_ id: String) {
        copiedItemID = id
        clearCopiedItemTask?.cancel()
        clearCopiedItemTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self?.copiedItemID == id {
                    self?.copiedItemID = nil
                }
            }
        }
    }

    func openActivePeek() {
        guard !activeItemID.isEmpty else { return }
        openPeek(activeItemID)
    }

    func cyclePeekFocus(backward: Bool) {
        guard peekItemID != nil else { return }
        let order: [HandyFocusTarget] = [.peekClose, .peekPrimary, .peekCompose]
        let currentIndex = order.firstIndex(of: focusTarget) ?? 1
        let nextIndex = backward
            ? (currentIndex + order.count - 1) % order.count
            : (currentIndex + 1) % order.count
        requestFocus(order[nextIndex])
    }

    func composeDraft() {
        guard !selectedIDs.isEmpty, !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            triggerInvalidComposeFeedback()
            return
        }
        closePeek()
        draft = PromptComposer.compose(goal: goal, intent: intent, selectedItems: selectedItems)
        copied = false
        requestFocus(.draftCopy)
    }

    func copyDraft() {
        guard let draft else { return }
        copied = HandyPasteboardWriter.copyString(draft)
        requestFocus(.draftCopy)
    }

    func runPrimaryAction() {
        if draft != nil {
            closePeek()
            copyDraft()
        } else {
            composeDraft()
        }
    }

    func clearDraft() {
        draft = nil
        copied = false
    }

    func clearSearch() {
        search = ""
        clearDraft()
        closePeek()
        resetGalleryScroll()
        onQueryChanged?(.clearSearch)
        requestFocus(.search)
    }

    func handleEscape() {
        if closePeek(restoreFocus: true) { return }
        if draft != nil {
            clearDraft()
            requestFocus(.search)
            return
        }
        if !search.isEmpty {
            clearSearch()
            return
        }
        onRequestClose?()
    }

    func applyDemoState(_ state: String) {
        guard state != "mouse", state != "default" else { return }
        resetDemoBaseline()
        switch state {
        case "hover":
            demoHoverID = "ctx-clip-error"
        case "peek":
            openPeek("ctx-code-position")
        case "draft":
            composeDraft()
        case "copied":
            composeDraft()
            copyDraft()
        case "filter":
            search = "panel"
            searchChanged()
        case "empty":
            search = "zzzz"
            searchChanged()
        case "scroll":
            railOffset = -560
        case "selection":
            selectedIDs = HandyFixtures.defaultSelectedIDs.union(["ctx-clip-error"])
        default:
            break
        }
    }

    private func resetDemoBaseline() {
        activeFilter = .all
        search = ""
        goal = HandyFixtures.defaultGoal
        selectedIDs = HandyFixtures.defaultSelectedIDs
        intent = HandyFixtures.defaultIntent
        activeItemID = HandyFixtures.defaultActiveID
        peekItemID = nil
        draft = nil
        copied = false
        demoHoverID = nil
        railOffset = 0
        galleryResetToken += 1
        invalidComposeNudge = 0
        selectionPulseID = nil
        selectionPulseToken = 0
        copiedItemID = nil
        draggingItemID = nil
        clearCopiedItemTask?.cancel()
        requestFocus(.search)
    }

    func requestFocus(_ target: HandyFocusTarget) {
        focusTarget = focusCoordinator.request(target)
        onFocusChange?(target)
    }

    private func triggerInvalidComposeFeedback() {
        invalidComposeNudge += 1
        requestFocus(.search)
    }

    private func triggerSelectionPulse(_ id: String) {
        selectionPulseID = id
        selectionPulseToken += 1
    }

    private func resetGalleryScroll() {
        railOffset = 0
        galleryResetToken += 1
    }
}
