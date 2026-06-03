import AppKit
import HandyCore
import SwiftUI

struct ContextGalleryView: View {
    @ObservedObject var state: PanelState
    let cardHeight: CGFloat
    let galleryHeight: CGFloat
    var focused: FocusState<HandyFocusTarget?>.Binding
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .leading) {
            if state.filteredItems.isEmpty {
                emptyState
            } else {
                GeometryReader { proxy in
                    HorizontalGalleryScrollView(
                        railOffset: $state.railOffset,
                        resetToken: state.galleryResetToken,
                        contentRevision: contentRevision,
                        contentWidth: contentWidth,
                        viewportHeight: proxy.size.height,
                        scrollingDisabled: state.peekItemID != nil || state.draft != nil,
                        itemCount: state.filteredItems.count,
                        preloadThreshold: 6,
                        onPrefetch: state.loadMoreIfNeeded
                    ) {
                        railContent
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .overlay(alignment: .leading) {
                        LinearGradient(colors: [HandyVisualTokens.Colors.panelBackground.opacity(0.92), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: state.railOffset < 0 ? 42 : 0)
                            .allowsHitTesting(false)
                    }
                    .overlay(alignment: .trailing) {
                        LinearGradient(colors: [.clear, HandyVisualTokens.Colors.panelBackground.opacity(0.92)], startPoint: .leading, endPoint: .trailing)
                            .frame(width: trailingFadeWidth(viewportWidth: proxy.size.width))
                            .allowsHitTesting(false)
                    }
                }
                .clipped()
            }
        }
        .frame(height: galleryHeight)
    }

    private var railContent: some View {
        HStack(spacing: 12) {
            ForEach(Array(state.filteredItems.enumerated()), id: \.element.id) { index, item in
                ContextCardView(
                    item: item,
                    selected: state.selectedIDs.contains(item.id),
                    active: state.activeItemID == item.id,
                    demoHovered: state.demoHoverID == item.id,
                    state: state,
                    revealed: state.revealContent,
                    revealIndex: index,
                    reduceMotion: reduceMotion
                )
                .focused(focused, equals: .card(item.id))
                .frame(width: HandyMetric.cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous))
                .clipped()
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.32), value: state.filteredItems.map(\.id))
    }

    private var contentWidth: CGFloat {
        CGFloat(state.filteredItems.count) * HandyMetric.cardWidth + CGFloat(max(state.filteredItems.count - 1, 0)) * 12
    }

    private var contentRevision: Int {
        var hasher = Hasher()
        for item in state.filteredItems {
            hasher.combine(item.id)
            hasher.combine(item.title)
            hasher.combine(item.thumbnailPath)
        }
        for id in state.selectedIDs.sorted() {
            hasher.combine(id)
        }
        hasher.combine(state.copiedItemID)
        hasher.combine(state.draggingItemID)
        hasher.combine(state.activeItemID)
        hasher.combine(state.demoHoverID)
        hasher.combine(state.revealContent)
        hasher.combine(state.peekItemID)
        hasher.combine(state.draft != nil)
        return hasher.finalize()
    }

    private func trailingFadeWidth(viewportWidth: CGFloat) -> CGFloat {
        contentWidth + state.railOffset > viewportWidth + 1 ? 42 : 0
    }

    private var emptyState: some View {
        Text(state.items.isEmpty ? "No captured context yet." : "No matching context.")
            .font(.handyDisplay(size: 13))
            .foregroundStyle(HandyVisualTokens.Colors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: min(260, galleryHeight - 24))
            .background(Color.white.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                    .foregroundStyle(Color.white.opacity(0.14))
            )
    }
}

struct ContextCardView: View {
    let item: ContextItem
    let selected: Bool
    let active: Bool
    let demoHovered: Bool
    @ObservedObject var state: PanelState
    let revealed: Bool
    let revealIndex: Int
    let reduceMotion: Bool

    @State private var hovered = false

    private var accent: Color { Color(hex: item.accent) }
    private var copied: Bool { state.copiedItemID == item.id }
    private var dragging: Bool { state.draggingItemID == item.id }
    private var cardEngaged: Bool { hovered || selected || active || demoHovered || dragging }
    private var toolbarVisible: Bool { (hovered || demoHovered) && !dragging }
    private var typeBadgeVisible: Bool { hovered || demoHovered || copied || dragging }
    private var hoverAnimation: Animation? {
        reduceMotion ? nil : .timingCurve(0.16, 1, 0.3, 1, duration: 0.16)
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = ContextCardMetrics(size: proxy.size, isVisualAsset: item.isVisualAsset)

            ZStack(alignment: .topLeading) {
                cardContent(metrics)

                ContextCardDragBridge(
                    item: item,
                    onClick: {
                        state.copyItem(item.id)
                    },
                    onDragBegan: {
                        hovered = false
                        state.beginDraggingItem(item.id)
                    },
                    onDragEnded: { succeeded in
                        hovered = false
                        state.finishDraggingItem(item.id, succeeded: succeeded)
                    }
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                .zIndex(2.5)

                TypeIconBadge(item: item, selected: selected, copied: copied, size: metrics.typeIconSize)
                    .frame(width: metrics.badgeWidth(copied: copied), height: metrics.typeIconSize)
                    .offset(x: metrics.chromeInset, y: metrics.chromeInset)
                    .opacity(typeBadgeVisible ? 1 : 0)
                    .scaleEffect(typeBadgeVisible ? 1 : 0.92, anchor: .topLeading)
                    .zIndex(3)
                    .allowsHitTesting(false)
                    .animation(hoverAnimation, value: typeBadgeVisible)

                CardSourceAgeRow(item: item, compact: metrics.isCompact)
                    .padding(.horizontal, metrics.footerHorizontalPadding)
                    .padding(.bottom, metrics.footerBottomInset)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottomLeading)
                    .zIndex(2)
                    .allowsHitTesting(false)

                CardToolbarView(item: item, selected: selected, visible: toolbarVisible, state: state, reduceMotion: reduceMotion)
                    .position(x: metrics.toolbarCenter.x, y: metrics.toolbarCenter.y)
                    .zIndex(4)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous))
            .onTapGesture {
                state.copyItem(item.id)
            }
        }
        .focusable(true)
        .focusEffectDisabled()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .overlay(selectedAffordance)
        .shadow(color: shadowStyle.color, radius: shadowStyle.radius, x: shadowStyle.x, y: shadowStyle.y)
        .opacity(revealed ? (dragging ? 0.72 : 1) : 0)
        .scaleEffect(reduceMotion ? 1 : (revealed ? 1 : 0.982), anchor: .center)
        .animation(reduceMotion ? nil : .timingCurve(0.16, 1, 0.3, 1, duration: 0.28).delay(Double(revealIndex) * 0.035), value: revealed)
        .animation(reduceMotion ? nil : .timingCurve(0.16, 1, 0.3, 1, duration: 0.18), value: selected)
        .onHover { value in
            DispatchQueue.main.async {
                hovered = value
                if value {
                    state.activateItemFromHover(item.id)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func cardContent(_ metrics: ContextCardMetrics) -> some View {
        Group {
            if item.isVisualAsset {
                visualAssetSurface(metrics)
            } else {
                textAssetSurface(metrics)
            }
        }
    }

    @ViewBuilder
    private func textAssetSurface(_ metrics: ContextCardMetrics) -> some View {
        Group {
            if item.type == .code {
                boundedContent(metrics) {
                    codeContent(metrics)
                }
            } else {
                plainTextSurface(metrics)
            }
        }
    }

    private func codeContent(_ metrics: ContextCardMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.contentSpacing) {
            CodePreviewBlock(item: item, accent: accent, elevated: cardEngaged, reduceMotion: reduceMotion)
                .frame(height: metrics.codePreviewHeight)

            VStack(alignment: .leading, spacing: metrics.textSpacing) {
                Text(item.title)
                    .font(.handyDisplay(size: metrics.titleFontSize, weight: .bold))
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(item.preview)
                    .font(.handyDisplay(size: metrics.previewFontSize))
                    .lineSpacing(metrics.previewLineSpacing)
                    .foregroundStyle(HandyVisualTokens.Colors.textSecondary.opacity(0.94))
                    .lineLimit(metrics.codePreviewLineLimit)
                    .truncationMode(.tail)
                    .opacity(metrics.showsCodeDescription ? 1 : 0)
                    .frame(height: metrics.showsCodeDescription ? nil : 0)
            }
            .frame(width: metrics.contentSize.width, height: metrics.codeTextHeight, alignment: .topLeading)
            .clipped()

            Spacer(minLength: 0)
        }
        .frame(width: metrics.contentSize.width, height: metrics.contentSize.height, alignment: .topLeading)
        .clipped()
    }

    private func plainTextSurface(_ metrics: ContextCardMetrics) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.16), Color.white.opacity(0.026), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            boundedContent(metrics) {
                VStack(alignment: .leading, spacing: metrics.contentSpacing) {
                    Text(item.title)
                        .font(.handyDisplay(size: metrics.titleFontSize, weight: .bold))
                        .foregroundStyle(HandyVisualTokens.Colors.textPrimary)
                        .lineLimit(metrics.titleLineLimit)
                        .truncationMode(.tail)

                    Text(item.preview)
                        .font(.handyDisplay(size: metrics.bodyFontSize, weight: item.type == .thought ? .medium : .regular))
                        .lineSpacing(metrics.bodyLineSpacing)
                        .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.78))
                        .lineLimit(metrics.bodyLineLimit)
                        .truncationMode(.tail)

                    Spacer(minLength: 0)
                }
                .frame(width: metrics.contentSize.width, height: metrics.contentSize.height, alignment: .topLeading)
                .clipped()
            }
        }
    }

    private func boundedContent<Content: View>(_ metrics: ContextCardMetrics, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: metrics.contentSize.width, height: metrics.contentSize.height, alignment: .topLeading)
            .clipped()
            .position(metrics.contentCenter)
    }

    @ViewBuilder
    private func visualAssetSurface(_ metrics: ContextCardMetrics) -> some View {
        Group {
            if item.type == .image {
                imageAssetSurface(metrics)
            } else {
                linkedAssetSurface(metrics)
            }
        }
    }

    private func imageAssetSurface(_ metrics: ContextCardMetrics) -> some View {
        ZStack(alignment: .bottomLeading) {
            VisualAssetPreview(item: item, accent: accent, elevated: cardEngaged, reduceMotion: reduceMotion)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.34), Color.black.opacity(0.76), Color.black.opacity(0.90)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            Text(item.title)
                .font(.handyDisplay(size: metrics.titleFontSize, weight: .bold))
                .foregroundStyle(HandyVisualTokens.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: metrics.contentSize.width, alignment: .leading)
                .position(
                    x: metrics.contentCenter.x,
                    y: metrics.visualTitleBaselineY
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous))
    }

    private func linkedAssetSurface(_ metrics: ContextCardMetrics) -> some View {
        ZStack(alignment: .bottomLeading) {
            VisualAssetPreview(item: item, accent: accent, elevated: cardEngaged, reduceMotion: reduceMotion)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.58), Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                Spacer(minLength: 0)

                Text(item.title)
                    .font(.handyDisplay(size: metrics.titleFontSize, weight: .bold))
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                if item.type == .url {
                    Text(item.preview)
                        .font(.handyDisplay(size: metrics.captionFontSize, weight: .medium))
                        .foregroundStyle(HandyVisualTokens.Colors.textSecondary.opacity(0.76))
                        .lineLimit(metrics.captionLineLimit)
                        .truncationMode(.tail)
                }
            }
            .frame(width: metrics.contentSize.width, height: metrics.contentSize.height, alignment: .bottomLeading)
            .clipped()
            .position(x: metrics.contentCenter.x, y: metrics.contentCenter.y)
        }
        .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card, style: .continuous)
            .fill(cardEngaged ? HandyVisualTokens.Colors.cardHoverBackground : HandyVisualTokens.Colors.cardBackground)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(cardEngaged ? 0.050 : 0.030), Color.white.opacity(0.010)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                if selected {
                    LinearGradient(
                        colors: [accent.opacity(0.12), Color.clear, Color.black.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .allowsHitTesting(false)
                }
            }
    }

    private var selectedAffordance: some View {
        ZStack(alignment: .leading) {
            if selected {
                RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.card - 2, style: .continuous)
                    .stroke(accent.opacity(0.22), lineWidth: 1)
                    .padding(2)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accent.opacity(0.62))
                    .frame(width: 3)
                    .padding(.vertical, 42)
                    .shadow(color: accent.opacity(0.22), radius: 8, x: 0, y: 0)
            }
        }
        .allowsHitTesting(false)
        .animation(hoverAnimation, value: selected)
    }

    private var shadowStyle: ShadowStyle {
        if selected { return HandyVisualTokens.Shadows.cardSelected }
        if cardEngaged { return HandyVisualTokens.Shadows.cardHover }
        return HandyVisualTokens.Shadows.cardDefault
    }

    private var borderColor: Color {
        if selected { accent.opacity(0.32) }
        else if active || hovered || demoHovered { accent.opacity(0.24) }
        else { HandyVisualTokens.Colors.borderSubtle }
    }

}

private struct ContextCardMetrics {
    let size: CGSize
    let isVisualAsset: Bool

    var isCompact: Bool {
        size.width <= 240 || size.height <= 230
    }

    var chromeInset: CGFloat {
        isCompact ? 12 : 14
    }

    var typeIconSize: CGFloat {
        isCompact ? 30 : 36
    }

    func badgeWidth(copied: Bool) -> CGFloat {
        if copied { return isCompact ? 88 : 102 }
        return typeIconSize
    }

    var typeIconCenter: CGPoint {
        CGPoint(x: chromeInset + typeIconSize / 2, y: chromeInset + typeIconSize / 2)
    }

    var toolbarCenter: CGPoint {
        CGPoint(x: size.width - chromeInset - 33, y: chromeInset + 15)
    }

    var topContentInset: CGFloat {
        chromeInset + typeIconSize + (isCompact ? 12 : 14)
    }

    var footerBottomInset: CGFloat {
        isCompact ? 14 : 16
    }

    var footerRowHeight: CGFloat {
        isCompact ? 22 : 24
    }

    var footerContentInset: CGFloat {
        footerBottomInset + footerRowHeight + (isCompact ? 12 : 14)
    }

    var footerHorizontalPadding: CGFloat {
        isVisualAsset ? (isCompact ? 12 : 14) : (isCompact ? 14 : 18)
    }

    var contentPadding: CGFloat {
        isCompact ? 14 : 18
    }

    var contentSize: CGSize {
        CGSize(
            width: max(1, size.width - contentPadding * 2),
            height: max(1, size.height - topContentInset - footerContentInset)
        )
    }

    var contentCenter: CGPoint {
        CGPoint(
            x: contentPadding + contentSize.width / 2,
            y: topContentInset + contentSize.height / 2
        )
    }

    var contentSpacing: CGFloat {
        isCompact ? 8 : 13
    }

    var textSpacing: CGFloat {
        isCompact ? 5 : 8
    }

    var titleFontSize: CGFloat {
        isCompact ? 15 : 18
    }

    var titleLineLimit: Int {
        contentSize.height < 120 ? 1 : 2
    }

    var previewFontSize: CGFloat {
        isCompact ? 11 : 13
    }

    var previewLineSpacing: CGFloat {
        isCompact ? 1.2 : 1.9
    }

    var codePreviewLineLimit: Int {
        codeTextHeight < 42 ? 1 : (isCompact ? 2 : 3)
    }

    var showsCodeDescription: Bool {
        !isCompact && codeTextHeight >= 58
    }

    var bodyFontSize: CGFloat {
        isCompact ? 13 : 15
    }

    var bodyLineSpacing: CGFloat {
        isCompact ? 2 : 3
    }

    var bodyLineLimit: Int {
        if contentSize.height < 96 { return 3 }
        return isCompact ? 4 : 5
    }

    var captionFontSize: CGFloat {
        isCompact ? 10 : 11
    }

    var captionLineLimit: Int {
        isCompact ? 1 : 2
    }

    var codePreviewHeight: CGFloat {
        let desired = size.height * (isCompact ? 0.32 : 0.36)
        let upperBound = max(58, contentSize.height * (isCompact ? 0.46 : 0.50))
        return min(max(desired, 58), upperBound)
    }

    var codeTextHeight: CGFloat {
        max(24, contentSize.height - codePreviewHeight - contentSpacing)
    }

    var visualTitleBaselineY: CGFloat {
        size.height - footerContentInset - textSpacing - (titleFontSize * 0.55)
    }
}

private extension ContextItem {
    var isVisualAsset: Bool {
        switch type {
        case .image, .url, .file:
            true
        case .text, .code, .thought:
            false
        }
    }
}

private struct HorizontalGalleryScrollView<Content: View>: NSViewRepresentable {
    @Binding var railOffset: CGFloat
    let resetToken: Int
    let contentRevision: Int
    let contentWidth: CGFloat
    let viewportHeight: CGFloat
    let scrollingDisabled: Bool
    let itemCount: Int
    let preloadThreshold: Int
    let onPrefetch: (Int) -> Void
    let content: Content

    init(
        railOffset: Binding<CGFloat>,
        resetToken: Int,
        contentRevision: Int,
        contentWidth: CGFloat,
        viewportHeight: CGFloat,
        scrollingDisabled: Bool,
        itemCount: Int,
        preloadThreshold: Int,
        onPrefetch: @escaping (Int) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        _railOffset = railOffset
        self.resetToken = resetToken
        self.contentRevision = contentRevision
        self.contentWidth = contentWidth
        self.viewportHeight = viewportHeight
        self.scrollingDisabled = scrollingDisabled
        self.itemCount = itemCount
        self.preloadThreshold = preloadThreshold
        self.onPrefetch = onPrefetch
        self.content = content()
    }

    func makeCoordinator() -> GalleryScrollCoordinator {
        GalleryScrollCoordinator(railOffset: $railOffset)
    }

    func makeNSView(context: Context) -> GalleryScrollView {
        let scrollView = GalleryScrollView()
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScrollElasticity = .none
        scrollView.horizontalScrollElasticity = .automatic
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.onScroll = { [weak coordinator = context.coordinator] x, viewportWidth in
            coordinator?.syncRailOffset(x)
            onPrefetch(visibleEndIndex(scrollX: x, viewportWidth: viewportWidth))
        }

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: contentWidth, height: viewportHeight))
        scrollView.documentView = hostingView
        scrollView.scrollToX(max(-railOffset, 0), notify: false)
        context.coordinator.observe(scrollView)
        scrollView.notifyCurrentScroll()
        return scrollView
    }

    func updateNSView(_ scrollView: GalleryScrollView, context: Context) {
        context.coordinator.railOffset = $railOffset
        scrollView.scrollingDisabled = scrollingDisabled
        scrollView.onScroll = { [weak coordinator = context.coordinator] x, viewportWidth in
            coordinator?.syncRailOffset(x)
            onPrefetch(visibleEndIndex(scrollX: x, viewportWidth: viewportWidth))
        }
        let resetRequested = context.coordinator.consume(resetToken: resetToken)
        let contentChanged = context.coordinator.consume(contentRevision: contentRevision)

        let targetSize = CGSize(width: contentWidth, height: viewportHeight)
        if let hostingView = scrollView.documentView as? NSHostingView<Content> {
            if contentChanged {
                hostingView.rootView = content
            }
            if hostingView.frame.size != targetSize {
                hostingView.frame = CGRect(origin: .zero, size: targetSize)
            }
        } else {
            let hostingView = NSHostingView(rootView: content)
            hostingView.frame = CGRect(origin: .zero, size: targetSize)
            scrollView.documentView = hostingView
        }

        let maxOffset = max(contentWidth - scrollView.contentView.bounds.width, 0)
        let desiredX = resetRequested ? 0 : min(max(-railOffset, 0), maxOffset)
        if resetRequested, railOffset != 0 {
            DispatchQueue.main.async {
                railOffset = 0
            }
        }
        context.coordinator.performProgrammaticScroll {
            scrollView.layoutSubtreeIfNeeded()
            scrollView.scrollToX(desiredX, notify: false)
        }
        if resetRequested {
            let coordinator = context.coordinator
            DispatchQueue.main.async { [weak scrollView] in
                guard let scrollView else { return }
                coordinator.performProgrammaticScroll {
                    scrollView.layoutSubtreeIfNeeded()
                    scrollView.scrollToX(0, notify: false)
                }
            }
        }
        scrollView.notifyCurrentScroll()
    }

    private func visibleEndIndex(scrollX: CGFloat, viewportWidth: CGFloat) -> Int {
        let cardStride = HandyMetric.cardWidth + 12
        guard cardStride > 0, itemCount > 0 else { return 0 }
        let visibleMaxX = scrollX + viewportWidth + CGFloat(preloadThreshold) * cardStride
        return min(itemCount - 1, max(0, Int(ceil(visibleMaxX / cardStride)) - 1))
    }
}

@MainActor
private final class GalleryScrollCoordinator: NSObject {
    var railOffset: Binding<CGFloat>
    private weak var scrollView: GalleryScrollView?
    private var isProgrammaticScroll = false
    private var lastResetToken = 0
    private var lastContentRevision: Int?
    private var lastPublishedScrollX: CGFloat = 0

    init(railOffset: Binding<CGFloat>) {
        self.railOffset = railOffset
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func observe(_ scrollView: GalleryScrollView) {
        NotificationCenter.default.removeObserver(self)
        self.scrollView = scrollView
        lastPublishedScrollX = scrollView.contentView.bounds.origin.x
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    func syncRailOffset(_ x: CGFloat) {
        guard !isProgrammaticScroll else { return }
        guard x <= 1 || abs(x - lastPublishedScrollX) >= 24 else { return }
        lastPublishedScrollX = x
        let next = -x
        guard abs(railOffset.wrappedValue - next) > 8 else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isProgrammaticScroll, abs(self.railOffset.wrappedValue - next) > 8 else { return }
            self.railOffset.wrappedValue = next
        }
    }

    func performProgrammaticScroll(_ action: () -> Void) {
        isProgrammaticScroll = true
        action()
        isProgrammaticScroll = false
    }

    func consume(resetToken: Int) -> Bool {
        guard resetToken != lastResetToken else { return false }
        lastResetToken = resetToken
        return true
    }

    func consume(contentRevision: Int) -> Bool {
        guard contentRevision != lastContentRevision else { return false }
        lastContentRevision = contentRevision
        return true
    }

    @objc private func boundsDidChange(_ notification: Notification) {
        guard let scrollView else { return }
        syncRailOffset(scrollView.contentView.bounds.origin.x)
    }
}

private final class GalleryScrollView: NSScrollView {
    var scrollingDisabled = false
    var onScroll: ((CGFloat, CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        guard !scrollingDisabled else { return }
        let horizontalDelta = event.scrollingDeltaX
        let verticalDelta = event.scrollingDeltaY
        let mappedDelta = abs(horizontalDelta) > abs(verticalDelta) ? -horizontalDelta : -verticalDelta * 1.4
        guard abs(mappedDelta) > 0.1 else { return }

        scrollToX(contentView.bounds.origin.x + mappedDelta, notify: true)
    }

    func scrollToX(_ x: CGFloat, notify: Bool) {
        guard let documentView else { return }
        let maxOffset = max(documentView.frame.width - contentView.bounds.width, 0)
        let nextX = min(max(x, 0), maxOffset)
        guard abs(contentView.bounds.origin.x - nextX) > 0.25 else { return }
        contentView.scroll(to: CGPoint(x: nextX, y: 0))
        reflectScrolledClipView(contentView)
        if notify {
            notifyCurrentScroll()
        }
    }

    func notifyCurrentScroll() {
        onScroll?(contentView.bounds.origin.x, contentView.bounds.width)
    }
}

private struct CodePreviewBlock: View {
    let item: ContextItem
    let accent: Color
    let elevated: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            LayerBackedMediaSurface(accent: accent, elevated: elevated, reduceMotion: reduceMotion)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Circle().fill(Color.red.opacity(0.45)).frame(width: 6, height: 6)
                    Circle().fill(Color.yellow.opacity(0.45)).frame(width: 6, height: 6)
                    Circle().fill(Color.green.opacity(0.45)).frame(width: 6, height: 6)
                }
                Text(item.preview)
                    .font(.handyMono(size: 11))
                    .foregroundStyle(HandyVisualTokens.Colors.textCode.opacity(0.78))
                    .lineSpacing(2.2)
                    .lineLimit(4)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.media, style: .continuous))
        .offset(y: reduceMotion ? 0 : (elevated ? -2 : 0))
        .animation(reduceMotion ? nil : .handySnappy, value: elevated)
    }
}

private struct VisualAssetPreview: View {
    let item: ContextItem
    let accent: Color
    let elevated: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LayerBackedMediaSurface(accent: accent, elevated: elevated, reduceMotion: reduceMotion)

                switch item.type {
                case .image:
                    imagePreview(size: proxy.size)
                case .url:
                    urlPreview(size: proxy.size)
                case .file:
                    filePreview
                case .text, .code, .thought:
                    EmptyView()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .offset(y: reduceMotion ? 0 : (elevated ? -2 : 0))
        .scaleEffect(elevated ? 1.008 : 1)
        .animation(reduceMotion ? nil : .handySnappy, value: elevated)
    }

    private func imagePreview(size: CGSize) -> some View {
        ZStack {
            if let thumbnail = item.thumbnailPath.flatMap(CachedImageLoader.image(contentsOfFile:)) {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .saturation(0.92)
                    .contrast(1.04)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.clear, Color.black.opacity(0.18)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                LinearGradient(
                    colors: [
                        accent.opacity(0.60),
                        Color(hex: "#303640").opacity(0.82),
                        Color.black.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 82, height: 82)
                    VStack(spacing: 9) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.22))
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.16))
                    }
                    .frame(width: 92, height: 82)
                }
                .offset(y: -18)
            }
        }
        .clipped()
    }

    private func urlPreview(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            if let thumbnail = item.thumbnailPath.flatMap(CachedImageLoader.image(contentsOfFile:)) {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .saturation(0.94)
                    .contrast(1.03)
                    .overlay(
                        LinearGradient(
                            colors: [Color.black.opacity(0.08), Color.clear, Color.black.opacity(0.30)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                LinearGradient(
                    colors: [Color(hex: "#0A67D8"), Color(hex: "#132032")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(alignment: .leading, spacing: 10) {
                    Spacer()
                    LinesGlyph(widths: [0.58, 0.82, 0.46])
                        .opacity(0.44)
                }
                .padding(14)
            }
        }
    }

    private var filePreview: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white.opacity(0.13), accent.opacity(0.20), Color.black.opacity(0.24)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 72, height: 88)
                    .overlay(
                        Text(item.detail.prefix(2).uppercased())
                            .font(.handyDisplay(size: 16, weight: .bold))
                            .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.76))
                    )
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
                LinesGlyph(widths: [0.62, 0.82, 0.50])
            }
        }
    }
}

private struct SourceGlyph: View {
    let item: ContextItem
    let size: CGFloat

    var body: some View {
        glyph
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private var glyph: some View {
        if let icon = item.sourceIconPath.flatMap(CachedImageLoader.image(contentsOfFile:)) {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else if let icon = runningAppIcon {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: symbolName)
                .font(.system(size: max(14, size * 0.7), weight: .semibold))
                .foregroundStyle(Color(hex: item.accent).opacity(0.92))
        }
    }

    private var runningAppIcon: NSImage? {
        NSWorkspace.shared.runningApplications.first { $0.localizedName == item.source }?.icon
    }

    private var symbolName: String {
        let source = item.source.lowercased()
        if source.contains("browser") { return "globe" }
        if source.contains("finder") { return "folder" }
        if source.contains("screenshot") { return "camera.viewfinder" }
        if source.contains("editor") { return "chevron.left.forwardslash.chevron.right" }
        if source.contains("clipboard") { return "doc.on.clipboard" }
        return "app"
    }
}

private struct CardSourceAgeRow: View {
    let item: ContextItem
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 6 : 7) {
            SourceGlyph(item: item, size: compact ? 22 : 26)

            Text(item.source)
                .font(.handyDisplay(size: compact ? 10 : 11, weight: .medium))
                .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.78))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            Text(item.displayAge())
                .font(.handyDisplay(size: compact ? 10 : 11))
                .foregroundStyle(HandyVisualTokens.Colors.textMuted)
                .lineLimit(1)
        }
        .frame(height: compact ? 22 : 24, alignment: .leading)
    }
}

private struct TypeIconBadge: View {
    let item: ContextItem
    let selected: Bool
    let copied: Bool
    let size: CGFloat

    var body: some View {
        Group {
            if copied {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: max(12, size * 0.36), weight: .bold))
                    Text("Copied")
                        .font(.handyDisplay(size: max(12, size * 0.36), weight: .bold))
                }
                .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.96))
                .padding(.horizontal, 11)
                .frame(height: size)
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: max(12, size * 0.42), weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.86))
                    .frame(width: size, height: size)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: max(9, size * 0.33), style: .continuous)
                .fill(Color.white.opacity(copied ? 0.17 : (selected ? 0.18 : 0.12)))
                .overlay(
                    RoundedRectangle(cornerRadius: max(9, size * 0.33), style: .continuous)
                        .fill(Color(hex: item.accent).opacity(copied ? 0.24 : (selected ? 0.18 : 0.10)))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: max(9, size * 0.33), style: .continuous)
                .stroke(Color.white.opacity(copied ? 0.24 : (selected ? 0.30 : 0.16)), lineWidth: 1)
        )
        .shadow(color: Color(hex: item.accent).opacity(copied ? 0.24 : (selected ? 0.30 : 0.12)), radius: copied || selected ? 10 : 6, x: 0, y: 3)
        .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch item.type {
        case .url: "link"
        case .image: "photo"
        case .file: "doc.text"
        case .code: "curlybraces"
        case .thought: "quote.opening"
        case .text: "text.alignleft"
        }
    }
}

private struct LayerBackedMediaSurface: NSViewRepresentable {
    let accent: Color
    let elevated: Bool
    let reduceMotion: Bool

    func makeNSView(context: Context) -> CardMediaSurfaceView {
        let view = CardMediaSurfaceView()
        view.update(accent: NSColor(accent), elevated: elevated, reduceMotion: reduceMotion)
        return view
    }

    func updateNSView(_ nsView: CardMediaSurfaceView, context: Context) {
        nsView.update(accent: NSColor(accent), elevated: elevated, reduceMotion: reduceMotion)
    }
}

private final class CardMediaSurfaceView: NSView {
    private let gradientLayer = CAGradientLayer()
    private let highlightLayer = CALayer()
    private var currentElevated = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.masksToBounds = false

        gradientLayer.cornerRadius = HandyVisualTokens.Radius.media
        gradientLayer.masksToBounds = true
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)

        highlightLayer.cornerRadius = HandyVisualTokens.Radius.media
        highlightLayer.backgroundColor = NSColor.white.withAlphaComponent(0.035).cgColor
        highlightLayer.masksToBounds = true

        layer?.addSublayer(gradientLayer)
        layer?.addSublayer(highlightLayer)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        highlightLayer.frame = bounds
        CATransaction.commit()
    }

    func update(accent: NSColor, elevated: Bool, reduceMotion: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.colors = [
            accent.withAlphaComponent(elevated ? 0.30 : 0.24).cgColor,
            NSColor.white.withAlphaComponent(elevated ? 0.050 : 0.035).cgColor,
        ]
        highlightLayer.opacity = elevated ? 1 : 0.72
        CATransaction.commit()

        guard currentElevated != elevated else { return }
        currentElevated = elevated

        let targetTransform = elevated ? CATransform3DMakeScale(1.015, 1.015, 1) : CATransform3DIdentity
        let targetShadowOpacity: Float = elevated ? 0.20 : 0.08
        let targetShadowRadius: CGFloat = elevated ? 18 : 10
        let targetShadowOffset = CGSize(width: 0, height: elevated ? 10 : 5)

        guard !reduceMotion, let layer else {
            self.layer?.transform = targetTransform
            self.layer?.shadowOpacity = targetShadowOpacity
            self.layer?.shadowRadius = targetShadowRadius
            self.layer?.shadowOffset = targetShadowOffset
            return
        }

        layer.shadowColor = NSColor.black.cgColor
        layer.shadowPath = CGPath(roundedRect: bounds, cornerWidth: HandyVisualTokens.Radius.media, cornerHeight: HandyVisualTokens.Radius.media, transform: nil)
        LayerAnimator.animateSpring(layer: layer, keyPath: "transform", to: targetTransform, config: HandyMotionTokens.springSnappy)
        LayerAnimator.animate(layer: layer, keyPath: "shadowOpacity", to: targetShadowOpacity, duration: HandyMotionTokens.Duration.fast, timingFunction: CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1))
        LayerAnimator.animate(layer: layer, keyPath: "shadowRadius", to: targetShadowRadius, duration: HandyMotionTokens.Duration.fast, timingFunction: CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1))
        LayerAnimator.animate(layer: layer, keyPath: "shadowOffset", to: targetShadowOffset, duration: HandyMotionTokens.Duration.fast, timingFunction: CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1))
    }
}

private struct CardToolbarView: View {
    let item: ContextItem
    let selected: Bool
    let visible: Bool
    @ObservedObject var state: PanelState
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: 6) {
            Button {
                state.deleteItem(item.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("Delete \(item.title)")

            Button {
                state.openPeek(item.id)
            } label: {
                Image(systemName: "eye")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("Peek \(item.title)")
        }
        .buttonStyle(CardToolbarButtonStyle())
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible ? 1 : 0.94, anchor: .topTrailing)
        .allowsHitTesting(visible)
        .accessibilityHidden(!visible)
        .animation(reduceMotion ? nil : .handySnappy, value: visible)
    }
}

struct LinesGlyph: View {
    let widths: [CGFloat]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(widths.enumerated()), id: \.offset) { _, width in
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 170 * width, height: 9)
            }
        }
    }
}

struct CardToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.86))
            .background(Color(red: 9 / 255, green: 11 / 255, blue: 11 / 255).opacity(configuration.isPressed ? 0.92 : 0.72))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}
