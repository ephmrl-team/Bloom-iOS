//
//  SettingsView.swift
//  Bloom
//
//  Created by Аскольд on 13.08.2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(BloomManager.self) private var bloomManager

    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var isLogoutDialogPresented = false

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        List {
            profileSection
            securitySection
            applicationSection
            dataSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(SettingsLayout.sectionSpacing)
        .scrollContentBackground(.hidden)
        .background(Theme.colors.background)
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.top, SettingsLayout.topContentMargin, for: .scrollContent)
        .contentMargins(.bottom, SettingsLayout.bottomContentMargin, for: .scrollContent)
        .navigationBarBackButtonHidden(true)
        .toolbarTitle("Settings")
        .navigationDestination(for: SettingsRoute.self) { route in
            destination(for: route)
        }
        .topVariableBlur()
        .confirmationDialog(
            "Log out?",
            isPresented: $isLogoutDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) { logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save your recovery phrase before you log out. Without it you cannot sign in again.")
        }
    }

    @ViewBuilder
    private var profileSection: some View {
        if let user = bloomManager.currentUser {
            Section {
                SettingsRowLink(route: .profile(id: user.id)) {
                    SettingsProfileCard(user: user)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
    }

    private var securitySection: some View {
        Section {
            SettingsRowLink(route: .recoveryPhrase) {
                SettingsRowView(title: "Recovery phrase", icon: "key", tint: .orange) {
                    SettingsChevron()
                }
            }
            .settingsRowStyle()

            SettingsRowLink(route: .encryptionKeys) {
                SettingsRowView(title: "Encryption keys", icon: "shield", tint: .green) {
                    SettingsChevron()
                }
            }
            .settingsRowStyle()
        }
    }

    private var applicationSection: some View {
        Section {
            SettingsNotificationsRow()
                .settingsRowStyle()

            SettingsRowLink(route: .appearance) {
                SettingsRowView(title: "Appearance", icon: "circle.half", tint: .purple) {
                    SettingsRowValue(value: appearanceMode.title)
                }
            }
            .settingsRowStyle()

            SettingsLanguageRow()
                .settingsRowStyle()
        }
    }

    private var dataSection: some View {
        Section {
            SettingsStorageRow()
                .settingsRowStyle()

            SettingsRowLink(route: .about) {
                SettingsRowView(title: "About", icon: "logo", tint: .gray) {
                    SettingsChevron()
                }
            }
            .settingsRowStyle()
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                isLogoutDialogPresented = true
            } label: {
                Text("Log Out")
                    .font(.system(size: SettingsLayout.actionButtonFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.colors.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: SettingsLayout.actionButtonHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Theme.colors.foreground)
        }
    }

    @ViewBuilder
    private func destination(for route: SettingsRoute) -> some View {
        switch route {
        case let .profile(id):
            ProfileView(userID: id)
        case .recoveryPhrase:
            SettingsRecoveryPhraseView()
        case .encryptionKeys:
            SettingsEncryptionKeysView()
        case .appearance:
            SettingsAppearanceView()
        case .storage:
            SettingsStorageView()
        case .about:
            SettingsAboutView()
        }
    }

    private func logout() {
        bloomManager.logout()
        appState.logout()
    }
}

#if DEBUG
    #Preview {
        NavigationStack {
            SettingsView()
        }
        .environment(Router())
        .environment(AppState())
        .environment(BloomManager(backend: MockAPI()))
    }
#endif
