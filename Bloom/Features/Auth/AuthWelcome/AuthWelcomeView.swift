//
//  AuthWelcomeView.swift
//  Bloom
//
//  Created by Аскольд on 14.08.2026.
//

import SwiftUI

struct AuthWelcomeView: View {
    @Binding var path: NavigationPath

    /// Item width as a share of the screen, so the neighbouring tiles stay in view.
    private static let itemWidthRatio: CGFloat = 0.5
    private static let copies = 5
    private static let autoScrollDelay: Duration = .seconds(8)

    @State private var appeared = false
    @State private var position: Int?
    @State private var isScrolling = false

    private var pageCount: Int {
        WelcomeFeature.all.count + 1
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let itemWidth = width * Self.itemWidthRatio
            let margin = (width - itemWidth) / 2

            ScrollView(.horizontal) {
                // Eagerly built on purpose: a fast swipe must never reach a page that is
                // not ready yet, and lazy rows arrive too late. The pool is wide enough
                // that the endless jump back to the middle copy is rare.
                HStack(spacing: 0) {
                    ForEach(0..<(pageCount * Self.copies), id: \.self) { id in
                        page(index: id % pageCount, width: width)
                            .frame(width: itemWidth)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $position)
            .onScrollPhaseChange { _, phase in
                isScrolling = phase != .idle
                guard phase == .idle else { return }
                recenter()
            }
            .onAppear {
                position = pageCount * 2
            }
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
        // Restarts after every page change, so the timer never fights a swipe.
        .task(id: position) {
            guard position != nil else { return }

            try? await Task.sleep(for: Self.autoScrollDelay)
            guard !Task.isCancelled, !isScrolling, let position else { return }

            withAnimation(.smooth(duration: 0.55)) {
                self.position = position + 1
            }
        }
    }

    @ViewBuilder
    private func page(index: Int, width: CGFloat) -> some View {
        if index == 0 {
            WelcomePageView(
                title: Text("This is").font(Self.titleFont)
                    + Text(verbatim: " ").font(Self.titleFont)
                    + Text(verbatim: "Bloom").font(Self.nameFont),
                subtitle: "End-to-end encrypted messenger with seamless experience",
                textWidth: width - 80,
                tileDelay: index % pageCount == 0 ? 0 : 0.08,
                appeared: appeared
            ) {
                Image("GiantLogo")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 34))
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 4, y: 4)
            }
        } else {
            let feature = WelcomeFeature.all[index - 1]
            WelcomePageView(
                title: Text(feature.title).font(Self.titleFont),
                subtitle: feature.subtitle,
                textWidth: width - 80,
                tileDelay: index % pageCount == 0 ? 0 : 0.08,
                appeared: appeared
            ) {
                WelcomeFeatureTile(feature: feature)
            }
        }
    }

    /// Keeps the slider endless by jumping to the middle copy without an animation.
    private func recenter() {
        guard let position else { return }

        let jump = pageCount * 2
        let target: Int
        if position < jump {
            target = position + jump
        } else if position >= pageCount * 3 {
            target = position - jump
        } else {
            return
        }

        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            self.position = target
        }
    }

    private static let titleFont = Font.system(size: 32, weight: .semibold, design: .rounded)
    private static let nameFont = Font.system(size: 32, weight: .black, design: .rounded)
}
