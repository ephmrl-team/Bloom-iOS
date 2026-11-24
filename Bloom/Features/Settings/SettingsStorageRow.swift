//
//  SettingsStorageRow.swift
//  Bloom
//

import SwiftUI

/// The row shows the measured size and refreshes after returning from the detail screen.
struct SettingsStorageRow: View {
    @State private var usage: StorageUsage?

    var body: some View {
        SettingsRowLink(route: .storage) {
            SettingsRowView(title: "Storage", icon: "chart.pie", tint: .blue) {
                SettingsRowValue(value: usage?.formattedTotal ?? StorageUsage.format(0))
            }
        }
        .onAppear {
            Task { usage = await StorageUsageReader.read() }
        }
    }
}
