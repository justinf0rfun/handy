import AppKit
import HandyCore
import SwiftUI

struct PeekPreviewView: View {
    let item: ContextItem
    let selected: Bool
    @ObservedObject var state: PanelState
    var focused: FocusState<HandyFocusTarget?>.Binding

    private var accent: Color { Color(hex: item.accent) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                Text(item.type.rawValue)
                    .font(.handyDisplay(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(accent.opacity(0.92))

                Spacer()

                Button { state.closePeek(restoreFocus: true) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 34, height: 34)
                }
                .focused(focused, equals: .peekClose)
                .focusable(true)
                .focusEffectDisabled()
                .buttonStyle(PeekCloseButtonStyle(focused: state.focusTarget == .peekClose, accent: accent))
                .accessibilityLabel("Close peek")
            }

            HStack(alignment: .top, spacing: 14) {
                ContextPeekMedia(item: item)
                    .frame(width: 190, height: 150)

                VStack(alignment: .leading, spacing: 9) {
                    Text(item.title)
                        .font(.handyDisplay(size: 22, weight: .semibold))
                        .foregroundStyle(HandyVisualTokens.Colors.textPrimary)
                        .lineLimit(1)

                    peekDescription

                    HStack(spacing: 8) {
                        peekMeta("Source", item.source)
                        peekMeta("Age", item.displayAge())
                        peekMeta("Detail", item.detail)
                    }
                }
            }

            HStack {
                Button(selected ? "Added" : "Use context") {
                    state.toggleSelection(item.id, focusCard: false)
                    state.requestFocus(.peekPrimary)
                }
                .focused(focused, equals: .peekPrimary)
                .focusable(true)
                .buttonStyle(PeekPrimaryButtonStyle(accent: accent, focused: state.focusTarget == .peekPrimary))

                Spacer()

                Button("Compose with this") {
                    if !state.selectedIDs.contains(item.id) {
                        state.toggleSelection(item.id, focusCard: false)
                    }
                    state.composeDraft()
                }
                .focused(focused, equals: .peekCompose)
                .focusable(true)
                .buttonStyle(PeekSecondaryButtonStyle(focused: state.focusTarget == .peekCompose))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 12 / 255, green: 14 / 255, blue: 14 / 255).opacity(0.94))
                .overlay(
                    RadialGradient(colors: [accent.opacity(0.22), .clear], center: .topLeading, startRadius: 0, endRadius: 260)
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(accent.opacity(0.44), lineWidth: 1))
        .shadow(color: .black.opacity(0.42), radius: 27, x: 0, y: 24)
        .onAppear {
            Task { @MainActor in
                focused.wrappedValue = .peekPrimary
            }
        }
        .accessibilityLabel("\(item.title) preview")
    }

    private func peekMeta(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(HandyVisualTokens.Colors.textMuted)
            Text(value)
                .foregroundStyle(HandyVisualTokens.Colors.textSecondary)
        }
        .font(.handyDisplay(size: 11))
        .padding(.horizontal, 9)
        .frame(height: 26)
        .background(Color.white.opacity(0.045))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var peekDescription: some View {
        Text(item.preview)
            .font(.handyDisplay(size: 13))
            .lineSpacing(2)
            .foregroundStyle(HandyVisualTokens.Colors.textSecondary)
            .lineLimit(3)
    }
}

struct ContextPeekMedia: View {
    let item: ContextItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.media, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: item.accent).opacity(0.24), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
            if item.type == .code {
                Text(item.preview)
                    .font(.handyMono(size: 10))
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.74))
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(14)
            } else if item.type == .image, let thumbnail = imageForItem {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if item.type == .url {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "link")
                        .font(.system(size: 22, weight: .semibold))
                    Text(item.preview)
                        .font(.handyDisplay(size: 12, weight: .medium))
                        .lineLimit(5)
                }
                .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.74))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(14)
            } else {
                Text(item.preview)
                    .font(.handyDisplay(size: 13))
                    .lineSpacing(2.5)
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.76))
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.media, style: .continuous))
    }

    private var imageForItem: NSImage? {
        if let thumbnail = item.thumbnailPath.flatMap(NSImage.init(contentsOfFile:)) {
            return thumbnail
        }
        if item.type == .image {
            return NSImage(contentsOfFile: item.preview)
        }
        return nil
    }
}

struct DraftPreviewView: View {
    let draft: String
    let copied: Bool
    let intent: String
    let focused: Bool
    var focusBinding: FocusState<HandyFocusTarget?>.Binding
    let copy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 14) {
                    Text("Draft")
                        .font(.handyDisplay(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(HandyVisualTokens.Colors.accentPrimary.opacity(0.78))
                    Text(intent)
                        .font(.handyDisplay(size: 12, weight: .medium))
                        .foregroundStyle(HandyVisualTokens.Colors.textSecondary)
                }
                Spacer()
                Button(copied ? "Copied" : "Copy prompt", action: copy)
                    .focused(focusBinding, equals: .draftCopy)
                    .focusable(true)
                    .font(.handyDisplay(size: 12, weight: .bold))
                    .buttonStyle(DraftButtonStyle(focused: focused))
                    .accessibilityLabel(copied ? "Copied" : "Copy prompt")
            }

            Text(draft)
                .font(.handyDisplay(size: 13))
                .lineSpacing(1.8)
                .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.78))
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 10 / 255, green: 12 / 255, blue: 12 / 255).opacity(0.88))
                .overlay(
                    LinearGradient(colors: [HandyVisualTokens.Colors.accentPrimary.opacity(0.12), Color.white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(HandyVisualTokens.Colors.accentPrimary.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 18)
        .onAppear {
            Task { @MainActor in
                focusBinding.wrappedValue = .draftCopy
            }
        }
    }
}

struct PeekPrimaryButtonStyle: ButtonStyle {
    let accent: Color
    let focused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.handyDisplay(size: 13, weight: .medium))
            .foregroundStyle(Color(hex: "#141615"))
            .padding(.horizontal, 13)
            .frame(height: 36)
            .background(accent.opacity(configuration.isPressed ? 0.72 : 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .focusRing(focused, radius: 13)
    }
}

struct PeekSecondaryButtonStyle: ButtonStyle {
    let focused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.handyDisplay(size: 13, weight: .medium))
            .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.82))
            .padding(.horizontal, 13)
            .frame(height: 36)
            .background(Color.white.opacity(configuration.isPressed ? 0.10 : 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .focusRing(focused, radius: 13)
    }
}

struct PeekCloseButtonStyle: ButtonStyle {
    let focused: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(configuration.isPressed ? 0.72 : 0.86))
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.07))
            .clipShape(Circle())
            .overlay(Circle().stroke((focused ? accent : Color.white).opacity(focused ? 0.46 : 0.12), lineWidth: focused ? 1.5 : 1))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

struct DraftButtonStyle: ButtonStyle {
    let focused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.84))
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(HandyVisualTokens.Colors.accentPrimary.opacity(configuration.isPressed ? 0.18 : 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(HandyVisualTokens.Colors.accentPrimary.opacity(0.28), lineWidth: 1))
            .focusRing(focused, radius: 11)
    }
}

private extension View {
    func focusRing(_ focused: Bool, radius: CGFloat) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(HandyVisualTokens.Colors.accentPrimary.opacity(focused ? 0.82 : 0), lineWidth: 2)
                .padding(-3)
        )
    }
}
