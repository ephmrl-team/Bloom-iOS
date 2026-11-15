//
//  AuthMnemonicRevealView.swift
//  Bloom
//

import SwiftUI

struct AuthMnemonicRevealView: View {
    let phrase: String
    @Binding var path: NavigationPath

    @State private var isQuizPresented = false

    private var words: [String] {
        phrase.split(separator: " ").map(String.init)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing.xxl) {
                VStack(spacing: Theme.spacing.md - 2) {
                    Text("Remember phrase")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Save your seed phrase to recover your account if needed.")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.spacing.xxl)

                MnemonicWordsGrid(words: words)
            }
            .padding(.horizontal, 36)
            .padding(.bottom, Theme.spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            AuthMnemonicFooterView(isEnabled: true, isLoading: false, title: "Test Yourself") {
                isQuizPresented = true
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollEdgeEffectHidden(true, for: .all)
        .topVariableBlur()
        .ignoresSafeArea(.container, edges: .bottom)
        .hidesSensitiveContent()
        .sheet(isPresented: $isQuizPresented) {
            AuthMnemonicQuizView(phrase: phrase) {
                isQuizPresented = false
                path.append(AuthRoute.success)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(.systemBackground))
        }
    }
}

private struct MnemonicWordsGrid: View {
    let words: [String]

    private let columns = [
        GridItem(.flexible(), spacing: Theme.spacing.md),
        GridItem(.flexible(), spacing: Theme.spacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.spacing.md) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                HStack(spacing: Theme.spacing.sm) {
                    Text(word)
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Spacer(minLength: 0)

                    Text("\(index + 1)")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
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
