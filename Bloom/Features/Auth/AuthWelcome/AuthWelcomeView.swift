//
//  AuthWelcomeView.swift
//  Bloom
//
//  Created by Аскольд on 14.08.2026.
//

import SwiftUI

struct AuthWelcomeView: View {
    @Binding var path: NavigationPath
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    /// Item width as a share of the screen, so the neighbouring tiles stay in view.
    private static let itemWidthRatio: CGFloat = 0.5
    /// Caps for iPad, where half of the width would be a 500pt tile next to a
    /// one-line paragraph.
    private static let maxItemWidth: CGFloat = 360
    private static let maxTextWidth: CGFloat = 360
    private static let copies = 3
    private static let autoScrollDelay: Duration = .seconds(5)
    private static let slideAnimation = Animation.smooth(duration: 0.6)

    @State private var appeared = false
    /// Starts empty on purpose: `scrollPosition` ignores the value the binding is
    /// created with, so a preset index left the carousel sitting on the first copy —
    /// the left neighbour missing — until something moved it. Setting it once on
    /// appear is a real change and lands before the first frame.
    @State private var position: Int?

    private var carousel: WelcomeCarousel {
        WelcomeCarousel(pageCount: WelcomeFeature.all.count + 1, copies: Self.copies)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            // shortcut: the scroll offset in points stops matching the page when this
            // width changes (iPhone portrait to landscape), so the page can sit off
            // centre until the next swipe. iPad holds one width, so it does not drift.
            let itemWidth = min(width * Self.itemWidthRatio, Self.maxItemWidth)
            let margin = (width - itemWidth) / 2

            ScrollView(.horizontal) {
                // Eagerly built on purpose: a fast swipe must never reach a page that is
                // not ready yet, and lazy rows arrive too late.
                HStack(spacing: 0) {
                    ForEach(0..<carousel.poolCount, id: \.self) { id in
                        let page = carousel.pageIndex(forItem: id)
                        pageView(index: page, pageWidth: itemWidth, width: width)
                            .frame(width: itemWidth)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("welcomePage\(page)")
                            // Only the centred copy is readable: the pool holds three of
                            // every page, and a reader should not hear them all.
                            .accessibilityHidden(id != position)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $position)
            // Pull the pool back only once the scroll has stopped. Doing it while the
            // finger is down resets the offset mid-drag, which reads as a jerk back.
            .onScrollPhaseChange { _, phase in
                if phase == .idle {
                    recenter()
                }
            }
            .onAppear {
                if position == nil {
                    position = carousel.startItem
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AuthWelcomeFooterView(appeared: appeared, path: $path)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.75)) {
                appeared = true
            }
        }
        // Keyed on the page, so a swipe cancels the countdown and nothing fires in the
        // middle of a gesture. Reduce Motion and VoiceOver turn the carousel into a
        // plain slider: nothing moves unless the user moves it.
        .task(id: reduceMotion || voiceOver ? nil : position) {
            guard !reduceMotion, !voiceOver, let current = position else { return }

            try? await Task.sleep(for: Self.autoScrollDelay)
            guard !Task.isCancelled else { return }

            withAnimation(Self.slideAnimation) {
                self.position = current + 1
            }
        }
    }

    @ViewBuilder
    private func pageView(index: Int, pageWidth: CGFloat, width: CGFloat) -> some View {
        let textWidth = min(width - 80, Self.maxTextWidth)

        if index == 0 {
            WelcomePageView(
                title: Text("This is \(Text(verbatim: "Bloom").font(Self.nameFont))")
                    .font(Self.titleFont),
                subtitle: "End-to-End encrypted messenger with a seamless experience",
                textWidth: textWidth,
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
                textWidth: textWidth,
                pageWidth: pageWidth,
                tileDelay: 0.08,
                appeared: appeared
            ) {
                WelcomeFeatureTile(feature: feature)
            }
        }
    }

    /// Keeps the slider endless by jumping by whole runs without animation.
    ///
    /// The jump lands on the same page in the middle run, so what is on screen does not
    /// change — the copies are identical. `WelcomeCarousel` owns which index that is.
    private func recenter() {
        guard let position, let target = carousel.recenteredItem(forItem: position) else { return }

        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            self.position = target
        }
    }

    private static let titleFont = Font.system(size: 32, weight: .semibold, design: .rounded)
    private static let nameFont = Font.system(size: 32, weight: .black, design: .rounded)
}
