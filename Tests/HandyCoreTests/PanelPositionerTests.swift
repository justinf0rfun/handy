import CoreGraphics
import Foundation
import Testing
@testable import HandyCore

@Test func panelStaysInsideVisibleFrameAcrossEdges() {
    let visible = CGRect(x: 0, y: 0, width: 1280, height: 800)
    let size = CGSize(width: 760, height: 764)
    let anchors = [
        CGPoint(x: 34, y: 766),
        CGPoint(x: 1246, y: 766),
        CGPoint(x: 34, y: 34),
        CGPoint(x: 1246, y: 34)
    ]

    for anchor in anchors {
        let placement = PanelPositioner.place(anchor: anchor, panelSize: size, visibleFrame: visible)
        #expect(visible.insetBy(dx: 18, dy: 18).contains(placement.frame.origin))
        #expect(placement.frame.maxX <= visible.maxX - 18 + 0.001)
        #expect(placement.frame.maxY <= visible.maxY - 18 + 0.001)
        #expect(placement.frame.minX >= visible.minX + 18 - 0.001)
        #expect(placement.frame.minY >= visible.minY + 18 - 0.001)
    }
}

@Test func promptComposerProducesDeterministicPrompt() {
    let selected = HandyFixtures.contextItems.filter { HandyFixtures.defaultSelectedIDs.contains($0.id) }
    let draft = PromptComposer.compose(
        goal: HandyFixtures.defaultGoal,
        intent: HandyFixtures.defaultIntent,
        selectedItems: selected
    )

    #expect(draft.contains("Intent: Implement this"))
    #expect(draft.contains("Positioning branch"))
    #expect(draft.contains("Dark surface reference"))
    #expect(draft.contains("Request:"))
}

@Test func externalPointerDownDoesNotDismissVisiblePanel() {
    #expect(PanelInteractionPolicy.shouldDismissForExternalPointerDown() == false)
    #expect(PanelInteractionPolicy.shortcutActionWhenVisible(pointerInsidePanel: true) == .dismiss)
    #expect(PanelInteractionPolicy.shortcutActionWhenVisible(pointerInsidePanel: false) == .reposition)
}

@Test func attentionAnchorPrefersFocusedTextThenFocusedElementBeforeMouse() {
    let mouse = CGPoint(x: 30, y: 40)
    let element = CGPoint(x: 300, y: 400)
    let text = CGPoint(x: 500, y: 600)

    #expect(AttentionAnchorPolicy.resolve(focusedText: text, focusedElement: element, mouse: mouse) == AttentionAnchor(point: text, source: .focusedText))
    #expect(AttentionAnchorPolicy.resolve(focusedText: nil, focusedElement: element, mouse: mouse) == AttentionAnchor(point: element, source: .focusedElement))
    #expect(AttentionAnchorPolicy.resolve(focusedText: nil, focusedElement: nil, mouse: mouse) == AttentionAnchor(point: mouse, source: .mouse))
}

@Test func referenceMeasurementsMatchPrimaryNativeConstants() {
    #expect(ReferenceMeasurements1280x800.shell.width == 760)
    #expect(ReferenceMeasurements1280x800.shell.height == 775)
    #expect(ReferenceMeasurements1280x800.gallery.width == 702)
    #expect(ReferenceMeasurements1280x800.firstCard.width == 270)
    #expect(ReferenceMeasurements1280x800.defaultSelectedIDs == HandyFixtures.defaultSelectedIDs)
}

@Test func contextRepositoryPersistsAndDeduplicatesItems() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let repository = CoreDataContextRepository(storeDirectory: directory, retentionLimit: 2, inMemory: true)
    let item = ContextItem(
        id: "ctx-live-text",
        type: .text,
        title: "Copied note",
        preview: "Copied note body",
        source: "Clipboard",
        age: "now",
        accent: "#8bc7b2",
        detail: "Copied text",
        capturedAt: Date(timeIntervalSince1970: 1_780_000_000)
    )

    try repository.prepend(item)
    try repository.prepend(ContextItem(
        id: "ctx-live-text-new-id",
        type: .text,
        title: "Copied note",
        preview: "Copied note body",
        source: "Clipboard",
        age: "now",
        accent: "#8bc7b2",
        detail: "Copied text",
        capturedAt: Date(timeIntervalSince1970: 1_780_000_001)
    ))

    let loaded = try repository.loadItems()
    #expect(loaded.count == 1)
    #expect(loaded[0].id == "ctx-live-text-new-id")
    #expect(loaded[0].displayAge(now: Date(timeIntervalSince1970: 1_780_000_121)) == "2m")

    let updated = try repository.update(ContextItem(
        id: "ctx-live-text-new-id",
        type: .text,
        title: "Enriched note",
        preview: "Copied note body",
        source: "Clipboard",
        age: "now",
        accent: "#8bc7b2",
        detail: "Enriched text",
        thumbnailPath: "/tmp/thumb.png",
        capturedAt: Date(timeIntervalSince1970: 1_780_000_001)
    ))
    #expect(updated.count == 1)
    #expect(updated[0].title == "Enriched note")
    #expect(updated[0].thumbnailPath == "/tmp/thumb.png")

    let remaining = try repository.delete(id: "ctx-live-text-new-id")
    #expect(remaining.isEmpty)
    #expect(try repository.loadItems().isEmpty)

    let uncappedDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let uncappedRepository = CoreDataContextRepository(storeDirectory: uncappedDirectory, inMemory: true)
    for index in 0..<3 {
        try uncappedRepository.prepend(ContextItem(
            id: "ctx-\(index)",
            type: .text,
            title: "Copied note \(index)",
            preview: "Body \(index)",
            source: "Clipboard",
            age: "now",
            accent: "#8bc7b2",
            detail: "Copied text \(index)",
            capturedAt: Date(timeIntervalSince1970: Double(1_780_000_000 + index))
        ))
    }

    #expect(try uncappedRepository.loadItems().map(\.id) == ["ctx-2", "ctx-1", "ctx-0"])

    let page = try uncappedRepository.loadPage(offset: 1, limit: 1, filter: .all, search: "")
    #expect(page.items.map(\.id) == ["ctx-1"])
    #expect(page.hasMore == true)
    #expect(try uncappedRepository.countItems(filter: .type(.text), search: "note") == 3)
    #expect(try uncappedRepository.countItems(filter: .type(.code), search: "note") == 0)
}
