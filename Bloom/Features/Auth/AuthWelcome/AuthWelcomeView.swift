//
//  AuthWelcomeView.swift
//  Bloom
//
//  Created by Аскольд on 14.08.2026.
//

import SwiftUI

struct AuthWelcomeView: View {
    @Binding var path: NavigationPath

    @State private var appeared = false
    @State private var offset: CGFloat = 0
    @State private var pageWidth: CGFloat = 0

    private struct ScrollMetrics: Equatable {
        var offset: CGFloat
        var width: CGFloat
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                WelcomePageView(
                    title: "This is **Bloom**",
                    subtitle: "End-to-end encrypted messenger with seamless experience",
                    progress: progress(for: 0),
                    width: pageWidth
                ) {
                    Image("GiantLogo")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 4, y: 4)
                }

                ForEach(Array(WelcomeFeature.all.enumerated()), id: \.offset) { index, feature in
                    WelcomePageView(
                        title: feature.title,
                        subtitle: feature.subtitle,
                        progress: progress(for: index + 1),
                        width: pageWidth
                    ) {
                        WelcomeFeatureTile(feature: feature)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: ScrollMetrics.self) { geometry in
            ScrollMetrics(
                offset: geometry.contentOffset.x + geometry.contentInsets.leading,
                width: geometry.containerSize.width
            )
        } action: { _, newValue in
            offset = newValue.offset
            pageWidth = newValue.width
        }
        .safeAreaInset(edge: .bottom) {
            AuthWelcomeFooterView(appeared: appeared, path: $path)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(.snappy(duration: 0.75)) {
                appeared = true
            }
        }
    }

    /// 0 while a page is centred, ±1 once it is a full page away.
    private func progress(for index: Int) -> CGFloat {
        guard pageWidth > 0 else { return 0 }
        return offset / pageWidth - CGFloat(index)
    }
}
