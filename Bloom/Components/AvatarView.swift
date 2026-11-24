//
//  AvatarView.swift
//  Bloom
//
//  Created by Аскольд on 11.08.2026.
//

import SwiftUI

enum AvatarSize {
    case xs, sm, md, mdLarge, lg, xl, xxl, xxxl, xxxxl

    var dimension: CGFloat {
        switch self {
        case .xs: return 34
        case .sm: return 40
        case .md: return 44
        case .mdLarge: return 48
        case .lg: return 56
        case .xl: return 76
        case .xxl: return 100
        case .xxxl: return 128
        case .xxxxl: return 160
        }
    }
}

struct AvatarView: View {
    var size: AvatarSize = .md
    var square: Bool = false
    var image: String?
    var id: String = ""
    var name: String = ""
    /// Stretches the avatar to the space it is given instead of its fixed `size`.
    var fills: Bool = false

    private var dimension: CGFloat {
        size.dimension
    }

    var body: some View {
        Group {
            if let imageUrlString = image, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(loadedImage):
                        loadedImage
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        defaultAvatarView
                    @unknown default:
                        defaultAvatarView
                    }
                }
            } else {
                defaultAvatarView
            }
        }
        .frame(width: fills ? nil : dimension, height: fills ? nil : dimension)
        .frame(maxWidth: fills ? .infinity : nil, maxHeight: fills ? .infinity : nil)
        .clipShape(square ? AnyShape(Rectangle()) : AnyShape(Circle()))
    }

    private var defaultAvatarView: some View {
        let colors = avatarGradient(for: id)
        let initials = initials(from: name)

        return (square ? AnyShape(Rectangle()) : AnyShape(Circle()))
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .overlay(
                Text(initials)
                    .font(.system(size: dimension / 2.25, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.colors.white)
            )
    }
}
