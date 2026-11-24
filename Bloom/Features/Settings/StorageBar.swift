//
//  StorageBar.swift
//  Bloom
//

import SwiftUI

/// A two-segment bar that makes the Documents / tmp split visible at a glance.
struct StorageBar: View {
    let documents: Int64
    let temporary: Int64

    private var total: Int64 {
        max(documents + temporary, 1)
    }

    /// A hairline gap only when both segments are visible, so the bar never overflows its width.
    private var segmentSpacing: CGFloat {
        documents > 0 && temporary > 0 ? 2 : 0
    }

    var body: some View {
        VStack(spacing: Theme.spacing.md) {
            GeometryReader { proxy in
                let available = proxy.size.width - segmentSpacing

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.colors.secondaryText.opacity(SettingsLayout.storageTrackOpacity))

                    HStack(spacing: segmentSpacing) {
                        segment(color: Theme.colors.primary, value: documents, width: available)
                        segment(color: Theme.colors.orange, value: temporary, width: available)
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: SettingsLayout.storageBarHeight)

            HStack(spacing: Theme.spacing.lg) {
                legend("Documents", color: Theme.colors.primary)
                legend("Temporary files", color: Theme.colors.orange)
                Spacer(minLength: 0)
            }
        }
        .settingsRowStyle()
    }

    private func segment(color: Color, value: Int64, width: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width * CGFloat(value) / CGFloat(total))
    }

    private func legend(_ title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: Theme.spacing.xs) {
            Circle()
                .fill(color)
                .frame(
                    width: SettingsLayout.storageLegendDotSize,
                    height: SettingsLayout.storageLegendDotSize
                )

            Text(title)
                .font(.system(size: SettingsLayout.valueFontSize, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.colors.secondaryText)
        }
    }
}
