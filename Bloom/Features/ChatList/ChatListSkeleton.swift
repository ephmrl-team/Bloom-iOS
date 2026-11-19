//
//  ChatListSkeleton.swift
//  Bloom
//

import SkulletX
import SwiftUI

/// Loading stand-in for the chat list: the row metrics of `ChatsListRowView`, nothing more.
struct ChatListSkeleton: View {
    private static let style = SkeletonStyle.bloom(radius: 6)

    var body: some View {
        List {
            ForEach(0 ..< 20, id: \.self) { _ in
                row
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectHidden(true, for: .all)
        .ignoresSafeArea(.container, edges: .bottom)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var row: some View {
        HStack(alignment: .top, spacing: 0) {
            SkeletonBar(
                width: AvatarSize.lg.dimension,
                height: AvatarSize.lg.dimension,
                style: Self.style,
                isCircular: true
            )
            .padding(.trailing, Theme.spacing.lg)
            .padding(.vertical, Theme.spacing.md)

            lines
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, Theme.spacing.lg)
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.sm) {
            HStack(spacing: Theme.spacing.xs) {
                SkeletonBar(height: 17, style: Self.style)
                    .frame(maxWidth: 140, alignment: .leading)

                Spacer(minLength: 0)

                SkeletonBar(width: 34, height: 13, style: Self.style)
            }

            SkeletonBar(height: 15, style: Self.style)
                .frame(maxWidth: 220, alignment: .leading)
        }
    }
}

#Preview {
    ChatListSkeleton()
}
