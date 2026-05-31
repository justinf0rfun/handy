import HandyCore
import SwiftUI

struct SearchRowView: View {
    @ObservedObject var state: PanelState
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(isFocused ? 0.68 : 0.50))
                .frame(width: 22)

            TextField("Search context", text: $state.search)
                .textFieldStyle(.plain)
                .font(.handyDisplay(size: 16))
                .foregroundStyle(HandyVisualTokens.Colors.textPrimary)
                .onSubmit {
                    if state.draft != nil {
                        state.copyDraft()
                    } else {
                        state.handleSearchEnter()
                    }
                }
                .onChange(of: state.search) { _, _ in state.searchChanged() }
                .disabled(state.peekItemID != nil || state.draft != nil)
                .accessibilityLabel("Search recent context")
                .frame(maxWidth: .infinity)

            if !state.search.isEmpty {
                Button(action: state.clearSearch) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PanelIconButtonStyle())
                .disabled(overlayActive)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.search, style: .continuous)
                .fill(Color.white.opacity(isFocused ? 0.068 : 0.044))
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(isFocused ? 0.066 : 0.040), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.search, style: .continuous))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: HandyVisualTokens.Radius.search, style: .continuous)
                .stroke(Color.white.opacity(isFocused ? 0.25 : 0.085), lineWidth: 1)
        )
        .shadow(color: HandyVisualTokens.Colors.accentPrimary.opacity(isFocused ? 0.08 : 0), radius: isFocused ? 12 : 0)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.18), value: isFocused)
    }

    private var overlayActive: Bool {
        state.peekItemID != nil || state.draft != nil
    }
}

struct PillRowView: View {
    @ObservedObject var state: PanelState

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ContextFilter.allCases) { filter in
                PillControl(
                    label: filter.label,
                    count: state.count(for: filter),
                    selected: state.activeFilter == filter
                ) {
                    state.setFilter(filter)
                }
                .accessibilityAddTraits(state.activeFilter == filter ? .isSelected : [])
            }
        }
        .frame(height: 30, alignment: .center)
    }
}

private struct PillControl: View {
    let label: String
    let count: Int
    let selected: Bool
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                Text("\(count)")
                    .font(.handyDisplay(size: 10, weight: .semibold))
                    .padding(.horizontal, 5)
                    .frame(minWidth: 18, minHeight: 18)
                    .background(selected ? Color.black.opacity(0.10) : Color.white.opacity(0.07))
                    .clipShape(Capsule())
            }
            .font(.handyDisplay(size: 12))
            .foregroundStyle(selected ? Color(hex: "#151716") : HandyVisualTokens.Colors.textPrimary.opacity(0.68))
            .padding(.horizontal, 9)
            .frame(height: 30)
            .background(selected ? HandyVisualTokens.Colors.textPrimary.opacity(0.92) : Color.white.opacity(0.045))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(selected ? Color.white.opacity(0.42) : Color.white.opacity(0.10), lineWidth: 1))
            .shadow(color: Color.white.opacity(selected ? 0.055 : 0), radius: selected ? 10 : 0, x: 0, y: 2)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.975 : (selected ? 1.018 : 1), anchor: .center)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.16), value: selected)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.10), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(count)")
        .accessibilityAddTraits(.isButton)
    }
}

struct GoalRowView: View {
    @ObservedObject var state: PanelState

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Goal")
                    .font(.handyDisplay(size: 11))
                    .foregroundStyle(HandyVisualTokens.Colors.textMuted.opacity(0.92))

                TextField("", text: $state.goal)
                    .textFieldStyle(.plain)
                    .font(.handyDisplay(size: 12))
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.9))
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Color.white.opacity(0.048))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Color.white.opacity(0.095), lineWidth: 1))
                    .lineLimit(1)
                    .onSubmit { state.composeDraft() }
                    .onChange(of: state.goal) { _, _ in state.clearDraft() }
                    .disabled(state.peekItemID != nil || state.draft != nil)
                    .accessibilityLabel("Goal")
            }

            Button {
                state.goal = "Turn the selected context into a concrete implementation plan for the native summon panel."
                state.clearDraft()
            } label: {
                Image(systemName: "sparkle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HandyVisualTokens.Colors.textPrimary.opacity(0.78))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(PanelIconButtonStyle())
            .disabled(state.peekItemID != nil || state.draft != nil)
            .accessibilityLabel("Sharpen goal")
        }
    }
}

struct ComposeRowView: View {
    @ObservedObject var state: PanelState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.selectedItems.isEmpty ? "Select context" : "\(state.selectedItems.count) selected")
                        .font(.handyDisplay(size: 12))
                        .foregroundStyle(HandyVisualTokens.Colors.textMuted)
                    if state.selectedItems.isEmpty {
                        Text("Pick a card or peek one")
                            .font(.handyDisplay(size: 11))
                            .foregroundStyle(HandyVisualTokens.Colors.textMuted.opacity(0.9))
                            .lineLimit(1)
                    }
                }

                HStack(spacing: -7) {
                    ForEach(state.selectedItems.prefix(4)) { item in
                        SelectionTrayToken(
                            item: item,
                            pulseToken: state.selectionPulseID == item.id ? state.selectionPulseToken : 0,
                            remove: { state.removeSelection(item.id) }
                        )
                    }
                }
            }
            .frame(minWidth: 132, alignment: .leading)
            .modifier(HorizontalShake(trigger: state.invalidComposeNudge, distance: 3))
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.16), value: state.invalidComposeNudge)

            Spacer()

            VStack(alignment: .leading, spacing: 5) {
                Text("Intent")
                    .font(.handyDisplay(size: 11))
                    .foregroundStyle(HandyVisualTokens.Colors.textMuted)
                Picker("", selection: $state.intent) {
                    ForEach(state.intents, id: \.self) { intent in
                        Text(intent).tag(intent)
                    }
                }
                .labelsHidden()
                .frame(width: 148, height: 36)
                .onChange(of: state.intent) { _, _ in state.clearDraft() }
            }

            Button(action: state.runPrimaryAction) {
                Text(state.draft == nil ? "Compose" : (state.copied ? "Copied" : "Copy prompt"))
                    .font(.handyDisplay(size: 14, weight: .semibold))
                    .foregroundStyle(canCompose ? HandyVisualTokens.Colors.textPrimary : HandyVisualTokens.Colors.textMuted)
                    .frame(width: 108, height: 40)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(canCompose ? 0.112 : 0.052))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(canCompose ? HandyVisualTokens.Colors.accentPrimary.opacity(0.28) : Color.white.opacity(0.095), lineWidth: 1)
            )
            .shadow(color: HandyVisualTokens.Colors.accentPrimary.opacity(canCompose ? 0.075 : 0), radius: canCompose ? 14 : 0, x: 0, y: 3)
            .scaleEffect(state.copied ? 1.025 : 1)
            .modifier(HorizontalShake(trigger: state.invalidComposeNudge, distance: 2))
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.16), value: state.copied)
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.12), value: state.invalidComposeNudge)
            .accessibilityLabel(state.draft == nil ? "Compose" : "Copy prompt")
        }
        .padding(.top, 2)
    }

    private var canCompose: Bool {
        !state.selectedIDs.isEmpty && !state.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct SelectionTrayToken: View {
    let item: ContextItem
    let pulseToken: Int
    let remove: () -> Void
    @State private var pulsing = false

    var body: some View {
        Button(action: remove) {
            Text(String(item.type.rawValue.prefix(1)).uppercased())
                .font(.handyDisplay(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "#121414"))
                .frame(width: 30, height: 30)
                .background(Color(hex: item.accent))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.75), lineWidth: 1))
                .shadow(
                    color: Color(hex: item.accent).opacity(pulsing ? 0.46 : 0),
                    radius: pulsing ? 11 : 0,
                    x: 0,
                    y: pulsing ? 4 : 0
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(pulsing ? 1.18 : 1, anchor: .center)
        .animation(.handySnappy, value: pulsing)
        .accessibilityLabel("Remove \(item.title)")
        .onChange(of: pulseToken) { _, token in
            guard token > 0 else { return }
            pulsing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + HandyMotionTokens.Duration.fast) {
                pulsing = false
            }
        }
    }
}

private struct HorizontalShake: GeometryEffect {
    var trigger: CGFloat
    let distance: CGFloat

    init(trigger: Int, distance: CGFloat) {
        self.trigger = CGFloat(trigger)
        self.distance = distance
    }

    var animatableData: CGFloat {
        get { trigger }
        set { trigger = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let phase = sin(animatableData * .pi * 2.0)
        return ProjectionTransform(CGAffineTransform(translationX: phase * distance, y: 0))
    }
}
