//
//  EncryptionFingerprintCard.swift
//  Bloom
//

import SwiftUI

/// The emoji fingerprint card: the emoji row pops in from left to right, the footer copies the row.
struct EncryptionFingerprintCard: View {
    let emojis: [String]
    let onCopy: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var copied = false
    @State private var rowWidth: CGFloat = 0
    @State private var isShown = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Theme.spacing.xl) {
                emojiRow
                Text("Emoji fingerprint of all your encryption keys")
                    .font(.system(size: SettingsLayout.fingerprintCaptionFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.spacing.xxl)
            .padding(.vertical, Theme.spacing.xl)

            fingerprintButton
        }
        .background {
            ZStack {
                Theme.colors.background
                PhraseBackdropView(icon: "shield")
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.colors.foreground, lineWidth: 1))
    }

    private var emojiRow: some View {
        HStack(spacing: SettingsLayout.fingerprintEmojiSpacing) {
            ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
                Text(verbatim: emoji)
                    .font(.system(size: emojiSize * 1.25))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: emojiSize)
                    .scaleEffect(isShown || reduceMotion ? 1 : 0.35)
                    .blur(radius: isShown || reduceMotion ? 0 : 10)
                    .opacity(isShown ? 1 : 0)
                    .animation(popAnimation(index), value: isShown)
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
        .onChange(of: rowWidth, initial: true) { _, width in
            guard width > 0 else { return }
            isShown = true
        }
        .accessibilityHidden(true)
    }

    /// Five cells and four gaps share the card width, so the emoji row reaches both inner insets.
    private var emojiSize: CGFloat {
        let gaps = SettingsLayout.fingerprintEmojiSpacing * CGFloat(EmojiFingerprint.length - 1)
        let width = rowWidth - gaps
        return max(width / CGFloat(EmojiFingerprint.length), 1)
    }

    /// The row blooms out of its middle emoji towards both edges.
    private func popAnimation(_ index: Int) -> Animation? {
        guard !reduceMotion else { return nil }
        let center = Double(emojis.count - 1) / 2
        return .spring(response: 0.51, dampingFraction: 0.62)
            .delay(abs(Double(index) - center) * 0.055)
    }

    private var fingerprintButton: some View {
        Button {
            onCopy(emojis.joined(separator: " "))
            flashCopied()
        } label: {
            ZStack {
                Text("Copy fingerprint")
                    .opacity(copied ? 0 : 1)
                    .scaleEffect(copied && !reduceMotion ? 0.85 : 1)
                    .blur(radius: copied && !reduceMotion ? 4 : 0)
                HStack(spacing: Theme.spacing.sm) {
                    Image("checkmark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: SettingsLayout.copyIconSize, height: SettingsLayout.copyIconSize)
                    Text("Copied")
                }
                .opacity(copied ? 1 : 0)
                .scaleEffect(copied || reduceMotion ? 1 : 0.85)
                .blur(radius: copied || reduceMotion ? 0 : 4)
            }
            .font(.system(size: SettingsLayout.actionButtonFontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.colors.text)
            .frame(maxWidth: .infinity)
            .frame(height: SettingsLayout.phraseFooterHeight)
            .background(Theme.colors.foreground)
            .contentShape(Rectangle())
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .smooth(duration: 0.3), value: copied)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "Copied" : "Copy fingerprint")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.radius.xl, style: .continuous)
    }

    private func flashCopied() {
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }
}

#if DEBUG
    #Preview {
        EncryptionFingerprintCard(emojis: ["🌊", "🍒", "🥑", "📷", "🧬"], onCopy: { _ in })
            .padding()
            .background(Theme.colors.background)
    }
#endif
