//
//  AuthMnemonicReviewView.swift
//  Bloom
//

import SwiftUI

struct AuthMnemonicReviewView: View {
    let phrase: String
    @Binding var path: NavigationPath

    @State private var challenges: [MnemonicChallenge] = []
    @State private var picks: [Int: String] = [:]

    private var isConfirmed: Bool {
        !challenges.isEmpty && challenges.allSatisfy { picks[$0.id] == $0.answer }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing.xxl) {
                VStack(spacing: Theme.spacing.md - 2) {
                    Text("Confirm your phrase")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text("Pick the right word for each position to make sure you wrote the phrase down correctly.")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.spacing.xxl)

                ForEach(challenges) { challenge in
                    MnemonicChallengeView(
                        challenge: challenge,
                        pick: Binding(
                            get: { picks[challenge.id] },
                            set: { picks[challenge.id] = $0 }
                        )
                    )
                }
            }
            .padding(.horizontal, 36)
            .padding(.bottom, Theme.spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            AuthMnemonicFooterView(isEnabled: isConfirmed, isLoading: false) {
                path.append(AuthRoute.success)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollEdgeEffectHidden(true, for: .all)
        .topVariableBlur()
        .ignoresSafeArea(.container, edges: .bottom)
        .hidesSensitiveContent()
        .onAppear {
            challenges = MnemonicChallenge.make(from: phrase)
        }
        .onDisappear {
            picks = [:]
        }
    }
}

private struct MnemonicChallenge: Identifiable {
    let id: Int
    let answer: String
    let options: [String]

    static func make(from phrase: String, count: Int = 3) -> [MnemonicChallenge] {
        let words = phrase.split(separator: " ").map(String.init)
        guard words.count > count else { return [] }

        let indices = (0..<words.count).shuffled().prefix(count).sorted()

        return indices.map { index in
            let answer = words[index]
            let decoys = words.filter { $0 != answer }.shuffled().prefix(count)
            return MnemonicChallenge(id: index, answer: answer, options: ([answer] + decoys).shuffled())
        }
    }
}

private struct MnemonicChallengeView: View {
    let challenge: MnemonicChallenge
    @Binding var pick: String?

    private let columns = [
        GridItem(.flexible(), spacing: Theme.spacing.sm),
        GridItem(.flexible(), spacing: Theme.spacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.md) {
            Text("Word #\(challenge.id + 1)")
                .font(.system(.headline, design: .rounded, weight: .semibold))

            LazyVGrid(columns: columns, spacing: Theme.spacing.sm) {
                ForEach(challenge.options, id: \.self) { option in
                    Button {
                        pick = option
                    } label: {
                        Text(option)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(pick == option ? Color.white : Color.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(background(for: option))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(pick == option ? .isSelected : [])
                    .accessibilityIdentifier("mnemonicOption\(challenge.id)_\(option)")
                }
            }
        }
    }

    private func background(for option: String) -> Color {
        guard pick == option else { return Color(.secondarySystemBackground) }
        return option == challenge.answer ? Theme.colors.green : Theme.colors.primary
    }
}

#Preview {
    NavigationStack {
        AuthMnemonicReviewView(
            phrase: "abandon ability able about above absent absorb abstract absurd abuse access accident",
            path: .constant(NavigationPath())
        )
    }
}
