//
//  SettingsProfileCard.swift
//  Bloom
//

import BlurSwiftUI
import BlurUIKit
import SwiftUI
import UIKit

/// The 16:9 profile header. Without a photo the card is the generated avatar gradient; with one,
/// the photo fills the card and its own accent color dims the variable blur under the user data.
struct SettingsProfileCard: View {
    let user: User

    @State private var photoAccent: Color?

    private var name: String {
        user.displayName ?? user.username
    }

    private var image: String? {
        user.avatarUrl
    }

    /// The photo's own accent; the generated gradient accent until the photo has been sampled.
    private var accent: Color {
        photoAccent ?? avatarGradient(for: user.id).first ?? Theme.colors.primary
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.radius.xl, style: .continuous)
    }

    var body: some View {
        Color.clear
            .aspectRatio(SettingsLayout.profileAspectRatio, contentMode: .fit)
            .overlay { content }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    Color.primary.opacity(SettingsLayout.profileBorderOpacity),
                    lineWidth: SettingsLayout.profileBorderWidth
                )
            }
            .accessibilityElement(children: .combine)
            .task(id: image) { await samplePhotoAccent() }
    }

    private var content: some View {
        ZStack(alignment: .bottomLeading) {
            background

            if image == nil {
                avatarInitials
            } else {
                photoDimming
            }

            footer
        }
    }

    @ViewBuilder
    private var background: some View {
        if let image {
            Color.clear.overlay {
                AvatarView(size: .xxxxl, square: true, image: image, id: user.id, name: name, fills: true)
            }
        } else {
            LinearGradient(
                colors: avatarGradient(for: user.id),
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    private var avatarInitials: some View {
        Text(initials(from: name))
            .font(
                .system(
                    size: SettingsLayout.profileInitialsFontSize,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(Theme.colors.white.opacity(SettingsLayout.profileInitialsOpacity))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var photoDimming: some View {
        VariableBlur(direction: .up)
            .maximumBlurRadius(SettingsLayout.profileBlurRadius)
            .dimmingTintColor(accent)
            .dimmingAlpha(.constant(alpha: SettingsLayout.profileBlurDimmingAlpha))
            .passesTouchesThrough(true)
            .frame(height: SettingsLayout.profileFooterHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
    }

    private var footer: some View {
        HStack(spacing: SettingsLayout.profileAvatarSpacing) {
            AvatarView(size: .mdLarge, image: image, id: user.id, name: name)

            userLabel

            Spacer(minLength: Theme.spacing.micro)

            SettingsChevron(
                size: SettingsLayout.profileChevronSize,
                color: Theme.colors.white.opacity(SettingsLayout.profileChevronOpacity)
            )
        }
        .padding(
            EdgeInsets(
                top: SettingsLayout.profileInset,
                leading: SettingsLayout.profileInset,
                bottom: SettingsLayout.profileInset,
                trailing: SettingsLayout.profileTrailingInset
            )
        )
    }

    private var userLabel: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.profileNameSpacing) {
            Text(name)
                .font(.system(size: SettingsLayout.profileNameFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.colors.white)
                .lineLimit(1)

            Text("@\(user.username)")
                .font(.system(size: SettingsLayout.profileUsernameFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.colors.whiteSecondary)
                .lineLimit(1)
        }
    }

    private func samplePhotoAccent() async {
        photoAccent = nil

        guard let image, let url = URL(string: image) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let photo = UIImage(data: data) else { return }

        // A neutral (grayscale) photo has no accent, so the band stays neutral.
        photoAccent = photo.accentColor() ?? Theme.colors.black
    }
}
