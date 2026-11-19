//
//  ChatMessagesSkeleton.swift
//  Bloom
//

import SkulletX
import SwiftUI

/// Loading stand-in for a conversation: bubbles of both sides, bottom-heavy like the chat.
struct ChatMessagesSkeleton: View {
    private static let style = SkeletonStyle.bloom(radius: 22)

    /// Widths of the stand-in bubbles, top to bottom; every third one is the other side's.
    private static let widths: [CGFloat] = [
        180, 240, 120, 260, 150, 210, 96, 230, 140, 200, 110, 250, 160, 120, 190,
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(Self.widths.enumerated()), id: \.offset) { index, width in
                    HStack(spacing: 0) {
                        if index % 3 == 2 {
                            Spacer(minLength: 55)
                        }

                        SkeletonBar(height: 42, style: Self.style)
                            .frame(maxWidth: width)

                        if index % 3 != 2 {
                            Spacer(minLength: 55)
                        }
                    }
                    .padding(.top, Theme.spacing.lg)
                    .padding(.horizontal, Theme.spacing.lg)
                }
            }
        }
        .defaultScrollAnchor(.bottom)
        .scrollIndicators(.hidden)
        .scrollEdgeEffectHidden(true, for: .top)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

#Preview {
    ChatMessagesSkeleton()
}
