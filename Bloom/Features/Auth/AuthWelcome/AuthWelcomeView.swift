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
    private static let autoScrollDelay: Duration = .seconds(5)
    private static let slideAnimation = Animation.smooth(duration: 0.6)

    @State private var appeared = false
    @State private var carousel = WelcomeCarousel(pageCount: WelcomeFeature.all.count + 1)
    /// Slot the scroll is on. Starts empty because `scrollPosition` ignores the value the
    /// binding is created with; setting it once on appear is a real change.
    @State private var slot: Int?

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            // shortcut: the scroll offset in points stops matching the page when this
            // width changes (iPhone portrait to landscape), so the page can sit off
            // centre until the next swipe. iPad holds one width, so it does not drift.
            let itemWidth = min(width * Self.itemWidthRatio, Self.maxItemWidth)
            let margin = (width - itemWidth) / 2

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(carousel.slots, id: \.self) { index in
                        let page = carousel.pageIndex(forSlot: index)
                        pageView(index: page, pageWidth: itemWidth, width: width)
                            .frame(width: itemWidth)
                            .accessibilityElement(children: .contain)
                            // The centred page is the one a test can address; the peek
                            // cards repeat pages, so they get their slot instead.
                            .accessibilityIdentifier(
                                index == carousel.currentSlot ? "welcomePage\(page)" : "welcomeSlot\(index)"
                            )
                            // Only the centred page is readable; a reader should not
                            // hear the peek cards as well.
                            .accessibilityHidden(page != carousel.currentPage)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $slot)
            // Shift the window once the scroll has stopped: doing it under the finger
            // would move the cards the user is touching.
            .onScrollPhaseChange { _, phase in
                if phase == .idle {
                    settle()
                }
            }
            .onAppear {
                if slot == nil {
                    slot = WelcomeCarousel.middleSlot
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
        .task(id: reduceMotion || voiceOver ? nil : slot) {
            guard !reduceMotion, !voiceOver, slot != nil else { return }

            try? await Task.sleep(for: Self.autoScrollDelay)
            guard !Task.isCancelled else { return }

            // One card to the right; the window shifts when the scroll stops.
            withAnimation(Self.slideAnimation) {
                self.slot = min((slot ?? WelcomeCarousel.middleSlot) + 1, WelcomeCarousel.windowSize - 1)
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

    /// Shifts the window when the swipe stopped near an end, without animation and in
    /// the same update as the scroll position, so the cards on screen do not move: the
    /// current page goes back to the middle slot and the scroll follows it exactly.
    private func settle() {
        guard let slot else { return }

        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            if let target = carousel.settle(atSlot: slot) {
                self.slot = target
            }
        }
    }

    private static let titleFont = Font.system(size: 32, weight: .semibold, design: .rounded)
    private static let nameFont = Font.system(size: 32, weight: .black, design: .rounded)
}
