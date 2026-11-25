//
//  SettingsEncryptionKeysView.swift
//  Bloom
//

import SwiftUI
import UIKit

struct SettingsEncryptionKeysView: View {
    @Environment(BloomManager.self) private var bloomManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var copyCount = 0
    @State private var copiedKey: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if rows.isEmpty {
                    unavailable
                } else {
                    EncryptionFingerprintCard(emojis: emojis) { copy($0) }
                    caption
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, SettingsLayout.captionInset)
                        .padding(.top, SettingsLayout.captionSpacing)
                    keyList
                        .padding(.top, SettingsLayout.sectionSpacing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.spacing.lg)
            .padding(.vertical, Theme.spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .background(Theme.colors.background)
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.bottom, SettingsLayout.bottomContentMargin, for: .scrollContent)
        .toolbarTitle("Encryption keys")
        .topVariableBlur()
        .hidesSensitiveContent()
        .sensoryFeedback(.impact(weight: .light), trigger: copyCount)
    }

    private var rows: [KeyRow] {
        guard let user = bloomManager.currentUser else { return [] }
        let rows = [
            KeyRow(id: "ml-kem", title: "ML-KEM-768 Fingerprint", key: user.mlKemPublicKey),
            KeyRow(id: "x448", title: "X448 Fingerprint", key: user.ecdhPublicKey),
            KeyRow(id: "ed448", title: "Ed448 Fingerprint", key: user.edPublicKey),
        ]
        return rows.filter { !$0.key.isEmpty }
    }

    private var emojis: [String] {
        EmojiFingerprint.emojis(for: rows.map(\.key))
    }

    private var caption: some View {
        Text("Compare this fingerprint with a friend to verify your chats are end-to-end encrypted.")
            .font(.system(size: SettingsLayout.captionFontSize, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.colors.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var keyList: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
            ForEach(rows) { row in
                keySection(row)
            }
        }
    }

    private func keySection(_ row: KeyRow) -> some View {
        VStack(alignment: .leading, spacing: SettingsLayout.captionSpacing) {
            Text(row.title)
                .font(.system(size: SettingsLayout.rowFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.colors.secondaryText)
                .padding(.horizontal, SettingsLayout.captionInset)

            keyField(row.key)
        }
    }

    private func keyField(_ key: String) -> some View {
        HStack(spacing: 0) {
            Text(key)
                .font(.system(size: SettingsLayout.keyFontSize, weight: .regular, design: .monospaced))
                .foregroundStyle(Theme.colors.text)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, SettingsLayout.keyRowInset)

            copyButton(key)
        }
        .frame(height: SettingsLayout.keyRowHeight)
        .background(
            Theme.colors.foreground,
            in: RoundedRectangle(cornerRadius: Theme.radius.lg, style: .continuous)
        )
    }

    private func copyButton(_ key: String) -> some View {
        let copied = copiedKey == key
        return Button {
            copy(key)
            showCopied(key)
        } label: {
            copyGlyph(copied)
                .frame(width: SettingsLayout.keyRowHeight, height: SettingsLayout.keyRowHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "Copied" : "Copy")
    }

    private func copyGlyph(_ copied: Bool) -> some View {
        ZStack {
            Image("doc.on.doc")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .opacity(copied ? 0 : 1)
                .scaleEffect(copied && !reduceMotion ? 0.6 : 1)
                .blur(radius: copied && !reduceMotion ? 3 : 0)
            Image("checkmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .opacity(copied ? 1 : 0)
                .scaleEffect(copied || reduceMotion ? 1 : 0.6)
                .blur(radius: copied || reduceMotion ? 0 : 3)
        }
        .frame(width: SettingsLayout.copyIconSize, height: SettingsLayout.copyIconSize)
        .foregroundStyle(Theme.colors.secondaryText)
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .smooth(duration: 0.3), value: copied)
    }

    private func showCopied(_ key: String) {
        copiedKey = key
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedKey == key {
                copiedKey = nil
            }
        }
    }

    private var unavailable: some View {
        Text("No keys available.")
            .font(.system(size: SettingsLayout.rowFontSize, weight: .regular, design: .rounded))
            .foregroundStyle(Theme.colors.secondaryText)
            .multilineTextAlignment(.center)
    }

    private func copy(_ text: String) {
        UIPasteboard.general.string = text
        copyCount += 1
    }

    private struct KeyRow: Identifiable {
        let id: String
        let title: LocalizedStringKey
        let key: String
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            SettingsEncryptionKeysView()
        }
        .environment(BloomManager(backend: MockAPI()))
    }
#endif
