//
//  ChatFooterView.swift
//  Bloom
//
//  Created by Аскольд on 12.08.2026.
//

import SwiftUI

struct ChatFooterView: View {
    @State private var text: String = ""
    @State private var inputBarHeight: CGFloat = 44
    @State private var isRecordingLocked: Bool = false

    @FocusState private var focused: Bool
    @Namespace private var inputNS

    private var isExpanded: Bool {
        inputBarHeight > 44
    }

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GlassEffectContainer(spacing: Theme.spacing.md) {
            HStack(alignment: .bottom, spacing: Theme.spacing.md) {
                input
                if hasText {
                    ChatFooterSendView(
                        text: $text,
                        barHeight: $inputBarHeight,
                        isRecordingLocked: $isRecordingLocked,
                        namespace: inputNS
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.smooth(duration: 0.3), value: hasText)
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
        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: isExpanded ? inputBarHeight : nil, alignment: .leading)
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
