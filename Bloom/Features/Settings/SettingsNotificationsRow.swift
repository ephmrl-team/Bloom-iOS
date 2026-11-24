//
//  SettingsNotificationsRow.swift
//  Bloom
//

import OSLog
import SwiftUI
import UIKit
import UserNotifications

/// Shows the real authorization state; the row opens the system settings, which is the only place
/// a permission can be granted or revoked after the first answer.
struct SettingsNotificationsRow: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var isEnabled = false

    var body: some View {
        Button {
            Task { await handleTap() }
        } label: {
            SettingsRowView(title: "Notifications", icon: "bell", tint: .pink) {
                SettingsRowValue(value: isEnabled ? LocalizedStringKey("On") : "Off")
            }
        }
        .buttonStyle(.plain)
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refresh() }
        }
    }

    private func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isEnabled = true
        case .denied, .notDetermined:
            isEnabled = false
        @unknown default:
            isEnabled = false
        }
    }

    private func handleTap() async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        guard status == .notDetermined else {
            openSystemSettings()
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isEnabled = granted
            if !granted {
                openSystemSettings()
            }
        } catch {
            Logger.bloom.error("notification authorization failed: \(error, privacy: .public)")
            isEnabled = false
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
