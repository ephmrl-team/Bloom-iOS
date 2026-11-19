//
//  ChatFooterView.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI

struct ChatFooterView: View {
    /// One height for the bar and the send circle: the glass morph needs both to line up.
    private static let controlSize = ChatFooterSendView.size

    @State private var text: String = ""
    @State private var inputBarHeight: CGFloat = Self.controlSize
    @State private var isRecordingLocked: Bool = false

    @FocusState private var focused: Bool
    @Namespace private var inputNS
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(KeyboardTracker.self) private var keyboard

    private var isExpanded: Bool {
        inputBarHeight > Self.controlSize
    }

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GlassEffectContainer(spacing: Theme.spacing.lg) {
            HStack(alignment: .bottom, spacing: Theme.spacing.md) {
                input
                if hasText {
                    ChatFooterSendView(
                        text: $text,
                        barHeight: $inputBarHeight,
                        isRecordingLocked: $isRecordingLocked,
                        namespace: inputNS
                    )
                    // The transition belongs to the view that is inserted, and the
                    // container spacing (16) is wider than the 12 pt gap so the glass
                    // grows out of the input instead of popping in.
                    .glassEffectTransition(reduceMotion ? .identity : .matchedGeometry)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.smooth(duration: 0.235), value: hasText)
        .onChange(of: keyboard.focusResets) { focused = false }
        .onChange(of: keyboard.focusRestores) { focused = true }
        .onDisappear { focused = false }
    }

    private var input: some View {
        ZStack(alignment: .leading) {
            if isExpanded {
                HStack(spacing: Theme.spacing.xs) {
                    ChatFooterVoiceView(isRecordingLocked: isRecordingLocked)
                }
            } else {
                ChatFooterTextView(focused: $focused, text: $text)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: Self.controlSize,
            maxHeight: isExpanded ? inputBarHeight : nil,
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius.composer))
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Theme.radius.composer))
        .glassEffectID("messageInput", in: inputNS)
        .onTapGesture {
            focused = true
        }
        .animation(.smooth(duration: 0.35), value: isExpanded)
        .animation(.smooth(duration: 0.35), value: inputBarHeight)
    }
}

#Preview {
    ChatFooterView()
        .environment(MessagesStore())
        .environment(KeyboardTracker())
        .padding(.vertical, KeyboardTracker.hiddenPadding)
}
