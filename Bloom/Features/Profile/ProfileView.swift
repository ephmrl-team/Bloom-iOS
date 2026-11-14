//
// ProfileView.swift
// Bloom
//

import SwiftUI

struct ProfileView: View {
    let userID: String

    @Environment(BloomManager.self) private var bloomManager
    @State private var user: User?

    var body: some View {
        VStack(spacing: Theme.spacing.xl) {
            AvatarView(
                size: .xxl,
                id: userID,
                name: user?.displayName ?? user?.username ?? userID
            )

            VStack(spacing: Theme.spacing.xs) {
                Text(user?.displayName ?? user?.username ?? userID)
                    .font(.title2.bold())

                if let username = user?.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let description = user?.description, !description.isEmpty {
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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            user = await bloomManager.user(id: userID)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(userID: "user_1")
    }
}
