//
//  NewMessageRowView.swift
//  Bloom
//

import SwiftUI

struct NewMessageRowView: View {
    let user: User
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 0) {
                AvatarView(
                    size: .md,
                    id: user.id,
                    name: user.displayName ?? user.username
                )
                .padding(.trailing, Theme.spacing.lg)
                .padding(.vertical, Theme.spacing.md)

                VStack(alignment: .center, spacing: Theme.spacing.xs) {
                    Text(user.displayName ?? user.username)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("@\(user.username)")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Theme.spacing.lg)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
