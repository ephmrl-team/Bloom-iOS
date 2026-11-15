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
    private static let autoScrollDelay: Duration = .seconds(5)
    private static let slideAnimation = Animation.smooth(duration: 0.6)

    @State private var appeared = false
    @State private var position: Int?

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
                        page(index: id % pageCount, pageWidth: itemWidth, width: width)
                            .frame(width: itemWidth)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $position)
            // Jump as soon as the slider gets near an edge, not when the scroll stops:
            // waiting for the idle phase let a swipe run out of copies first.
            .onChange(of: position) { _, _ in
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
        // Keyed on the page, so a swipe cancels the countdown and nothing fires in the
        // middle of a gesture.
        .task(id: position) {
            guard let current = position else { return }

            try? await Task.sleep(for: Self.autoScrollDelay)
            guard !Task.isCancelled else { return }

            withAnimation(Self.slideAnimation) {
                self.position = current + 1
            }
        }
    }

    @ViewBuilder
    private func page(index: Int, pageWidth: CGFloat, width: CGFloat) -> some View {
        if index == 0 {
            WelcomePageView(
                title: Text("This is").font(Self.titleFont)
                    + Text(verbatim: " ").font(Self.titleFont)
                    + Text(verbatim: "Bloom").font(Self.nameFont),
                subtitle: "End-to-End encrypted messenger with a seamless experience",
                textWidth: width - 80,
                pageWidth: pageWidth,
                tileDelay: 0,
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
                pageWidth: pageWidth,
                tileDelay: 0.08,
                appeared: appeared
            ) {
                WelcomeFeatureTile(feature: feature)
            }
        }
    }

    /// Keeps the slider endless by jumping by whole copies without animation.
    ///
    /// The window is two copies wide and every jump is one copy, so a jump always
    /// lands in the middle copy and cannot trigger the opposite jump on the next
    /// phase change (a one-copy window bounced between two indices forever). It also
    /// leaves five cards of runway at either end, so the copies ahead of the swipe are
    /// always ready before the slider reaches the edge of the pool.
    private func recenter() {
        guard let position else { return }

        let shift = pageCount * 2
        let cushion = pageCount + 1
        let target: Int?
        if position < cushion {
            target = position + shift
        } else if position >= pageCount * Self.copies - cushion {
            target = position - shift
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
