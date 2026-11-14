//
//  AuthMnemonicRevealView.swift
//  Bloom
//

import SwiftUI

struct AuthMnemonicRevealView: View {
    let phrase: String
    @Binding var path: NavigationPath

    @Environment(\.scenePhase) private var scenePhase
    @State private var isRevealed = false

    private var words: [String] {
        phrase.split(separator: " ").map(String.init)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing.xxl) {
                VStack(spacing: Theme.spacing.md - 2) {
                    Text("Save your recovery phrase")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text("These 12 words are the only way to restore your account. Write them down and keep them offline.")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.spacing.xxl)

                MnemonicWordsGrid(words: words, isRevealed: isRevealed)

                Button(isRevealed ? "Hide words" : "Show words") {
                    isRevealed.toggle()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 36)
            .padding(.bottom, Theme.spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            AuthMnemonicFooterView(isEnabled: isRevealed, isLoading: false) {
                path.append(AuthRoute.mnemonicReview(phrase))
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollEdgeEffectHidden(true, for: .all)
        .topVariableBlur()
        .ignoresSafeArea(.container, edges: .bottom)
        .hidesSensitiveContent()
        .onDisappear {
            isRevealed = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                isRevealed = false
            }
        }
    }
}

private struct MnemonicWordsGrid: View {
    let words: [String]
    let isRevealed: Bool

    private let columns = [
        GridItem(.flexible(), spacing: Theme.spacing.md),
        GridItem(.flexible(), spacing: Theme.spacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.spacing.md) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                HStack(spacing: Theme.spacing.sm) {
                    Text("\(index + 1)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(isRevealed ? word : "•••••")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Theme.spacing.lg)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuthMnemonicRevealView(
            phrase: "abandon ability able about above absent absorb abstract absurd abuse access accident",
            path: .constant(NavigationPath())
        )
    }
}
