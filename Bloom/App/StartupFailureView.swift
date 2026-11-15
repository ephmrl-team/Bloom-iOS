//
//  StartupFailureView.swift
//  Bloom
//

import SwiftUI

struct StartupFailureView: View {
    let detail: String?
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Theme.colors.secondaryText)

            Text("Couldn't start Bloom")
                .font(.system(.title3, design: .rounded, weight: .semibold))

            Text("Check your connection and try again.")
                .font(.subheadline)
                .foregroundStyle(Theme.colors.secondaryText)

            if let detail {
                Text(detail)
                    .font(.caption2.monospaced())
                    .foregroundStyle(Theme.colors.secondaryText)
                    .accessibilityIdentifier("startupErrorDetail")
            }

            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
                .padding(.top, Theme.spacing.sm)
        }
        .multilineTextAlignment(.center)
        .padding(Theme.spacing.xxl)
    }
}

#Preview {
    StartupFailureView(detail: "The operation couldn't be completed.") {}
}
