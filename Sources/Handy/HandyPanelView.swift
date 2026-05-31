import HandyCore
import SwiftUI

struct HandyPanelView: View {
    @ObservedObject var state: PanelState
    let panelSize: CGSize
    let close: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: HandyFocusTarget?

    private var shortLayout: Bool { panelSize.height <= 650 }
    private var padding: CGFloat { shortLayout ? 16 : 28 }
    private var gap: CGFloat { shortLayout ? 8 : 16 }
    private var innerWidth: CGFloat { panelSize.width - (padding * 2) - 2 }
    private var cardHeight: CGFloat { galleryHeight - (shortLayout ? 30 : 44) }
    private var headerHeight: CGFloat { shortLayout ? 34 : 40 }
    private var searchHeight: CGFloat { shortLayout ? 52 : 56 }
    private var searchWidth: CGFloat { min(innerWidth - (shortLayout ? 8 : 14), shortLayout ? 520 : 560) }
    private var searchPillGap: CGFloat { shortLayout ? 16 : 18 }
    private var pillHeight: CGFloat { shortLayout ? 30 : 34 }
    private var goalHeight: CGFloat { shortLayout ? 50 : 67 }
    private var composeHeight: CGFloat { shortLayout ? 50 : 63 }
    private var galleryHeight: CGFloat { shortLayout ? 250 : 330 }
    private var peekHeight: CGFloat { shortLayout ? 220 : 264 }
    private var draftHeight: CGFloat { shortLayout ? 96 : 104 }
    private var overlayActive: Bool { state.activePeekItem != nil || state.draft != nil }

    var body: some View {
        ZStack(alignment: .topLeading) {
            shell
        }
        .overlay(alignment: .topLeading) {
            overlayLayer
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .background(Color.clear)
        .onChange(of: state.focusTarget) { _, target in
            Task { @MainActor in
                focused = target
            }
        }
        .onAppear {
            Task { @MainActor in
                focused = .search
            }
        }
    }

    private var shell: some View {
        VStack(spacing: gap) {
            header
                .frame(width: innerWidth, height: headerHeight)
                .reveal(state.revealContent, index: 0, reduceMotion: reduceMotion)
                .accessibilityHidden(overlayActive)

            searchAndPills
                .reveal(state.revealContent, index: 1, reduceMotion: reduceMotion)
                .accessibilityHidden(overlayActive)

            GoalRowView(state: state)
                .frame(width: innerWidth, height: goalHeight)
                .reveal(state.revealContent, index: 3, reduceMotion: reduceMotion)
                .accessibilityHidden(overlayActive)

            ContextGalleryView(
                state: state,
                cardHeight: cardHeight,
                galleryHeight: galleryHeight,
                focused: $focused
            )
            .frame(width: innerWidth, height: galleryHeight)
            .reveal(state.revealContent, index: 4, reduceMotion: reduceMotion)
            .accessibilityHidden(overlayActive)

            Spacer(minLength: 0)

            ComposeRowView(state: state)
                .frame(width: innerWidth, height: composeHeight)
                .reveal(state.revealContent, index: 5, reduceMotion: reduceMotion)
        }
        .padding(padding)
        .frame(width: panelSize.width, height: panelSize.height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.panel, style: .continuous)
                .fill(HandyVisualTokens.Colors.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.panel, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.062), Color.white.opacity(0.020), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.panel, style: .continuous)
                        .stroke(HandyVisualTokens.Colors.borderSubtle, lineWidth: 1)
                )
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.panel, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
                }
                .shadow(color: .black.opacity(0.54), radius: 55, x: 0, y: 42)
        )
        .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.panel, style: .continuous))
    }

    private var overlayLayer: some View {
        ZStack(alignment: .topLeading) {
            if let item = state.activePeekItem {
                PeekPreviewView(item: item, selected: state.selectedIDs.contains(item.id), state: state, focused: $focused)
                    .frame(width: innerWidth, height: peekHeight)
                    .offset(x: padding, y: peekTop)
                    .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .top)))
                    .zIndex(3)
            }

            if let draft = state.draft {
                DraftPreviewView(
                    draft: draft,
                    copied: state.copied,
                    intent: state.intent,
                    focused: state.focusTarget == .draftCopy,
                    focusBinding: $focused,
                    copy: state.copyDraft
                )
                .frame(width: innerWidth, height: draftHeight)
                .offset(x: padding, y: draftTop)
                .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .bottom)))
                .zIndex(2)
            }
        }
        .allowsHitTesting(state.activePeekItem != nil || state.draft != nil)
    }

    private var searchAndPillsHeight: CGFloat {
        searchHeight + searchPillGap + pillHeight
    }

    private var galleryTop: CGFloat {
        padding + headerHeight + gap + searchAndPillsHeight + gap + goalHeight + gap
    }

    private var peekTop: CGFloat {
        max(padding, galleryTop - searchAndPillsHeight - goalHeight - (gap * 2) + (searchHeight / 2))
    }

    private var draftTop: CGFloat {
        max(padding, panelSize.height - padding - composeHeight - gap - draftHeight)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("Handy")
                    .font(.handyDisplay(size: shortLayout ? 18 : 20, weight: .semibold))
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.94))
                    .lineLimit(1)

                Text("Copy · Attach · Capture")
                    .font(.handyDisplay(size: shortLayout ? 9 : 10, weight: .bold))
                    .kerning(0.45)
                    .textCase(.uppercase)
                    .foregroundStyle(HandyVisualTokens.Colors.textMuted.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: shortLayout ? 12 : 13, weight: .medium))
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.72))
                    .frame(width: shortLayout ? 30 : 34, height: shortLayout ? 30 : 34)
            }
            .buttonStyle(PanelIconButtonStyle())
            .accessibilityLabel("Close Handy")
        }
    }

    private var searchAndPills: some View {
        VStack(alignment: .leading, spacing: 0) {
            SearchRowView(state: state, isFocused: focused == .search)
                .focused($focused, equals: .search)
                .frame(width: searchWidth, height: searchHeight, alignment: .leading)

            hitTestGap

            PillRowView(state: state)
                .frame(width: innerWidth, height: pillHeight)
        }
        .frame(width: innerWidth, height: searchHeight + searchPillGap + pillHeight, alignment: .topLeading)
    }

    private var hitTestGap: some View {
        Rectangle()
            .fill(Color.black.opacity(0.001))
            .frame(width: innerWidth, height: searchPillGap)
            .allowsHitTesting(true)
            .onTapGesture {}
    }
}

private extension View {
    func reveal(_ revealed: Bool, index: Int, reduceMotion: Bool) -> some View {
        opacity(revealed ? 1 : 0)
            .scaleEffect(reduceMotion ? 1 : (revealed ? 1 : 0.985), anchor: .top)
            .animation(reduceMotion ? nil : .handySmooth.delay(Double(index) * 0.045), value: revealed)
    }
}

struct PanelIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.white.opacity(configuration.isPressed ? 0.090 : 0.055))
            .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.control, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.20 : 0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
