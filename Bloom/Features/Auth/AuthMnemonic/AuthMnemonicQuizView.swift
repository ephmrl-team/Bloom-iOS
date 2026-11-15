//
//  AuthMnemonicQuizView.swift
//  Bloom
//

import SwiftUI

struct AuthMnemonicQuizView: View {
    let phrase: String
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var challenges: [MnemonicChallenge] = []
    @State private var picks: [Int: String] = [:]

    private var isConfirmed: Bool {
        !challenges.isEmpty && challenges.allSatisfy { picks[$0.id] == $0.answer }
    }

    var body: some View {
        VStack(spacing: Theme.spacing.xl) {
            ZStack {
                Text("Test yourself")
                    .font(.system(.headline, design: .rounded, weight: .semibold))

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image("x.mark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(.foreground)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Close")

                    Spacer()
                }
            }

            ScrollView {
                VStack(spacing: Theme.spacing.lg) {
                    ForEach(challenges) { challenge in
                        MnemonicChallengeRow(
                            challenge: challenge,
                            pick: Binding(
                                get: { picks[challenge.id] },
                                set: { picks[challenge.id] = $0 }
                            )
                        )
                    }
                }
                .padding(.bottom, Theme.spacing.sm)
            }
            .scrollIndicators(.hidden)

            Button {
                onFinish()
            } label: {
                Text("Continue")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.glassProminent)
            .disabled(!isConfirmed)
            .tint(isConfirmed ? Theme.colors.primary : Color.gray.opacity(0.4))
        }
        .padding(.horizontal, Theme.spacing.xxl)
        .padding(.top, Theme.spacing.xl)
        .padding(.bottom, Theme.spacing.lg)
        .onAppear {
            challenges = MnemonicChallenge.make(from: phrase)
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
            let decoy = words.filter { $0 != answer }.randomElement() ?? answer
            return MnemonicChallenge(id: index, answer: answer, options: [answer, decoy].shuffled())
        }
    }
}

private struct MnemonicChallengeRow: View {
    let challenge: MnemonicChallenge
    @Binding var pick: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.sm) {
            Text("\(challenge.id + 1) phrase word")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))

            HStack(spacing: Theme.spacing.sm) {
                ForEach(challenge.options, id: \.self) { option in
                    Button {
                        pick = option
                    } label: {
                        Text(option)
                            .font(.system(.headline, design: .rounded, weight: .medium))
                            .foregroundStyle(pick == option ? Color.white : Color.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
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
        return option == challenge.answer ? Theme.colors.green : Color(.systemRed)
    }
}

#Preview {
    AuthMnemonicQuizView(
        phrase: "abandon ability able about above absent absorb abstract absurd abuse access accident"
    ) {}
}
