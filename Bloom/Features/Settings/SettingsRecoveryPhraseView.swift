//
//  SettingsRecoveryPhraseView.swift
//  Bloom
//

import SwiftUI

struct SettingsRecoveryPhraseView: View {
    @Environment(BloomManager.self) private var bloomManager
    @Environment(Router.self) private var router

    @State private var words: [String] = []
    @State private var hasLoaded = false
    @State private var isRevealed = false

    private let columns = [
        GridItem(.flexible(), spacing: Theme.spacing.xxl),
        GridItem(.flexible(), spacing: Theme.spacing.xxl),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if hasLoaded {
                    if words.isEmpty {
                        Text("The recovery phrase is not available on this device.")
                            .font(.system(size: SettingsLayout.rowFontSize, weight: .regular, design: .rounded))
                            .foregroundStyle(Theme.colors.secondaryText)
                            .multilineTextAlignment(.center)
                    } else {
                        phraseBlock
                        caption
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, SettingsLayout.captionInset)
                            .padding(.top, SettingsLayout.captionSpacing)
                        testButton
                            .padding(.top, SettingsLayout.sectionSpacing)
                    }
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
        .toolbarTitle("Recovery phrase")
        .topVariableBlur()
        .task {
            words = bloomManager.recoveryPhrase()?.split(separator: " ").map(String.init) ?? []
            hasLoaded = true
        }
    }

    private var phraseBlock: some View {
        VStack(spacing: 0) {
            grid
                .padding(Theme.spacing.xxl)
                .animation(.smooth(duration: 0.6), value: isRevealed)
                .accessibilityHidden(!isRevealed)

            Button(action: togglePhrase) {
                Text(isRevealed ? "Hide phrase" : "Show phrase")
                    .font(.system(size: SettingsLayout.actionButtonFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.colors.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: SettingsLayout.phraseFooterHeight)
                    .background(Theme.colors.foreground)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background {
            ZStack {
                Theme.colors.background
                PhraseBackdropView()
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.colors.foreground, lineWidth: 1))
    }

    private var caption: some View {
        Text("Keep your recovery phrase safe. You'll need it to recover your account if you lose all your devices.")
            .font(.system(size: SettingsLayout.captionFontSize, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.colors.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.radius.xl, style: .continuous)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.spacing.xxl) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                wordCell(index: index, word: word)
            }
        }
    }

    private func wordCell(index: Int, word: String) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: "\(index + 1).")
                .monospacedDigit()
                .foregroundStyle(Theme.colors.secondaryText)
            Text(verbatim: "  \(word)")
                .foregroundStyle(Theme.colors.text.opacity(isRevealed ? 1 : 0))
                .overlay {
                    SpoilerParticlesView(tint: Theme.colors.text, revealed: isRevealed)
                }
        }
        .font(.system(size: SettingsLayout.phraseWordFontSize, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var testButton: some View {
        Button {
            router.presentModal(.mnemonicQuiz(words.joined(separator: " ")))
        } label: {
            Text("Test yourself")
                .font(.system(size: SettingsLayout.actionButtonFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.colors.text)
                .frame(maxWidth: .infinity)
                .frame(height: SettingsLayout.actionButtonHeight)
                .background(Theme.colors.foreground, in: shape)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func togglePhrase() {
        guard isRevealed else {
            Task {
                if await PhraseUnlock.request() {
                    isRevealed = true
                }
            }
            return
        }
        isRevealed = false
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            SettingsRecoveryPhraseView()
        }
        .environment(BloomManager(backend: MockAPI()))
        .environment(Router())
    }
#endif
