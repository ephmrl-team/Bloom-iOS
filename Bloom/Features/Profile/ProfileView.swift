//
// ProfileView.swift
//  Bloom
//

import SwiftUI

struct ProfileView: View {
    let userID: String

    @Environment(BloomManager.self) private var bloomManager
    @State private var user: User?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let user {
                profile(user)
            } else if loadFailed {
                ContentUnavailableView {
                    Label("Couldn't load profile", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("Check your connection and try again.")
                } actions: {
                    Button("Try again") {
                        Task { await load() }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await load() }
    }

    private func profile(_ user: User) -> some View {
        VStack(spacing: Theme.spacing.xl) {
            AvatarView(
                size: .xxl,
                id: userID,
                name: user.displayName ?? user.username
            )

            VStack(spacing: Theme.spacing.xs) {
                Text(user.displayName ?? user.username)
                    .font(.title2.bold())

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let description = user.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing.xl)
            }

            Spacer()
        }
        .padding(.top, Theme.spacing.xl)
        .frame(maxWidth: .infinity)
    }

    private func load() async {
        user = await bloomManager.user(id: userID)
        loadFailed = user == nil
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ProfileView(userID: "user_1")
    }
    .environment(BloomManager(backend: MockAPI()))
}
#endif
