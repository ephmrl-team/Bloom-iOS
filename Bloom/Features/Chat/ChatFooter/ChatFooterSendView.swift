//
//  ChatFooterSendView.swift
//  Bloom
//
//  Created by Аскольд on 13.08.2026.
//

import SwiftUI

struct ChatFooterSendView: View {
    static let size: CGFloat = 44

    @Binding var text: String
    @Binding var barHeight: CGFloat
    @Binding var isRecordingLocked: Bool
    let namespace: Namespace.ID

    @Environment(MessagesStore.self) private var store

    @State private var holdTask: Task<Void, Never>? = nil

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Button {
            send()
        } label: {
            Image(systemName: "arrow.up")
                .font(.headline)
                .foregroundStyle(Theme.colors.white)
                .frame(width: Self.size, height: Self.size)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(Theme.colors.primary).interactive(), in: .circle)
        .glassEffectID("sendButton", in: namespace)
        .accessibilityLabel("Send message")
        .accessibilityIdentifier("chatSendButton")
    }

    // Voice note button, parked for now. The recording logic below is kept as is;
    // re-enable this button (and the press style) when voice notes ship again.
    //
    // Button {
    //     guard hasText else { return }
    //     send()
    // } label: {
    //     Image(systemName: hasText ? "arrow.up" : "microphone.fill")
    //         .font(.headline)
    //         .foregroundStyle(hasText ? Theme.colors.white : Theme.colors.secondaryText)
    //         .frame(width: Self.size, height: Self.size)
    // }
    // .buttonStyle(InstantPressButtonStyle { pressing in
    //     handlePress(pressing)
    // })
    // .glassEffect(
    //     hasText ? .regular.tint(Theme.colors.primary).interactive() : .regular.interactive(),
    //     in: .circle
    // )

    private func handlePress(_ pressing: Bool) {
        guard !hasText else { return }
        if pressing {
            startHoldSequence()
        } else {
            cancelHoldSequence()
        }
    }

    private func startHoldSequence() {
        holdTask?.cancel()

        holdTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.15))
            guard !Task.isCancelled else { return }

            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.smooth(duration: 0.35)) {
                barHeight = 52
            }

            try? await Task.sleep(for: .seconds(0.75))
            guard !Task.isCancelled else { return }

            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.smooth(duration: 0.35)) {
                barHeight = 64
                isRecordingLocked = true
            }
        }
    }

    private func cancelHoldSequence() {
        holdTask?.cancel()
        holdTask = nil

        if !isRecordingLocked {
            withAnimation(.smooth(duration: 0.235)) {
                barHeight = Self.size
            }
        }
    }

    private func send() {
        // Animated here so the row's insertion transition runs; the list scrolls with the same curve.
        withAnimation(.smooth(duration: 0.235)) {
            store.send(text)
        }
        text = ""
    }
}

struct InstantPressButtonStyle: ButtonStyle {
    var onPressingChanged: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                onPressingChanged(isPressed)
            }
    }
}
