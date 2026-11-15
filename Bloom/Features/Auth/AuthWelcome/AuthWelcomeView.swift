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
    /// The settle after a swipe and the auto-advance slide.
    private static let settleAnimation = Animation.spring(duration: 0.45, bounce: 0.12)
    private static let slideAnimation = Animation.smooth(duration: 0.6)

    @State private var appeared = false
    @State private var scrollPosition = ScrollPosition(idType: Int.self)
    @State private var currentPage: Int?

    private var pageCount: Int {
        WelcomeFeature.all.count + 1
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let itemWidth = width * Self.itemWidthRatio
            let margin = (width - itemWidth) / 2
            let centerX = proxy.frame(in: .global).midX

            ScrollView(.horizontal) {
                // Eagerly built on purpose: a fast swipe must never reach a page that is
                // not ready yet, and lazy rows arrive too late. The pool is wide enough
                // that the endless jump back to the middle copy is rare.
                HStack(spacing: 0) {
                    ForEach(0..<(pageCount * Self.copies), id: \.self) { id in
                        page(index: id % pageCount, pageWidth: itemWidth, centerX: centerX, width: width)
                            .frame(width: itemWidth)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .scrollIndicators(.hidden)
            .scrollPosition($scrollPosition)
            // Paging is done here instead of with `.viewAligned`: the page to settle on is
            // picked and scrolled to with our own spring, so the landing curve is ours.
            .onScrollPhaseChange { _, phase in
                guard phase == .idle, let page = scrollPosition.viewID(type: Int.self) else { return }
                settle(on: page)
            }
            .onChange(of: scrollPosition.viewID(type: Int.self)) { _, page in
                guard let page else { return }
                currentPage = page
            }
            .onAppear {
                currentPage = pageCount * 2
                scrollPosition.scrollTo(id: pageCount * 2)
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
        .task(id: currentPage) {
            guard let current = currentPage else { return }

            try? await Task.sleep(for: Self.autoScrollDelay)
            guard !Task.isCancelled else { return }

            let next = (current + 1) % (pageCount * Self.copies)
            currentPage = next
            withAnimation(Self.slideAnimation) {
                scrollPosition.scrollTo(id: next)
            }
        }
    }

    @ViewBuilder
    private func page(index: Int, pageWidth: CGFloat, centerX: CGFloat, width: CGFloat) -> some View {
        if index == 0 {
            WelcomePageView(
                title: Text("This is").font(Self.titleFont)
                    + Text(verbatim: " ").font(Self.titleFont)
                    + Text(verbatim: "Bloom").font(Self.nameFont),
                subtitle: "End-to-End encrypted messenger with a seamless experience",
                textWidth: width - 80,
                pageWidth: pageWidth,
                containerMidX: centerX,
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
                containerMidX: centerX,
                tileDelay: 0.08,
                appeared: appeared
            ) {
                WelcomeFeatureTile(feature: feature)
            }
        }
    }

    /// Settles the scroll view exactly on a page and keeps the slider endless.
    ///
    /// Inside the middle copies the page is scrolled to itself, which only removes the
    /// distance a swipe left behind. Outside them the position moves by whole copies
    /// without animation: every page is drawn `copies` times, so the jump lands on the
    /// same picture and the two-copy window cannot bounce between two indices.
    private func settle(on page: Int) {
        currentPage = page
        let shift = pageCount * 2

        if page < pageCount {
            jump(to: page + shift)
        } else if page >= pageCount * 4 {
            jump(to: page - shift)
        } else {
            withAnimation(Self.settleAnimation) {
                scrollPosition.scrollTo(id: page)
            }
        }
    }

    private func jump(to target: Int) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            scrollPosition.scrollTo(id: target)
        }
        currentPage = target
    }

    private static let titleFont = Font.system(size: 32, weight: .semibold, design: .rounded)
    private static let nameFont = Font.system(size: 32, weight: .black, design: .rounded)
}
