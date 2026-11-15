//
//  WelcomeCarouselTests.swift
//  Bloom
//

import Testing
@testable import Bloom

@Suite("Welcome carousel")
struct WelcomeCarouselTests {
    private let carousel = WelcomeCarousel(pageCount: 4)

    @Test("The window is the current page with one on each side")
    func windowShowsNeighbours() {
        #expect(carousel.slots.count == 3)
        #expect(carousel.pageIndex(forSlot: 0) == 3)
        #expect(carousel.pageIndex(forSlot: 1) == 0)
        #expect(carousel.pageIndex(forSlot: 2) == 1)
    }

    @Test("Every slot shows a real page")
    func slotsStayInRange() {
        for page in 0..<4 {
            let shifted = WelcomeCarousel(pageCount: 4, currentPage: page)
            let pages = shifted.slots.map(shifted.pageIndex(forSlot:))
            #expect(pages.allSatisfy { (0..<4).contains($0) })
            #expect(Set(pages).count == 3)
        }
    }

    @Test("Settling moves the window by exactly the swiped distance")
    func settleKeepsTheCardsUnderTheFinger() {
        // The shift must be invisible: whatever was in the swiped slot has to become the
        // current slot, and the card that was current has to become its left neighbour.
        for slot in [0, 2] {
            var shifted = carousel
            let before = shifted.slots.map(shifted.pageIndex(forSlot:))

            let target = shifted.settle(atSlot: slot)

            let after = shifted.slots.map(shifted.pageIndex(forSlot:))
            #expect(target == WelcomeCarousel.currentSlot)
            #expect(after[1] == before[slot])
            if slot > WelcomeCarousel.currentSlot {
                // Swiped forward: the card that was current stays on its left.
                #expect(after[0] == before[1])
            } else {
                // Swiped back: it stays on its right.
                #expect(after[2] == before[1])
            }
        }
    }

    @Test("Settling on the current slot does nothing")
    func settleInPlaceIsANoop() {
        var shifted = carousel
        #expect(shifted.settle(atSlot: WelcomeCarousel.currentSlot) == WelcomeCarousel.currentSlot)
        #expect(shifted.currentPage == 0)
    }

    @Test("Swiping forward walks the pages in order and wraps at the end")
    func forwardCycleWrapsAround() {
        var shifted = WelcomeCarousel(pageCount: 4)
        var visited: [Int] = []

        for _ in 0..<5 {
            visited.append(shifted.currentPage)
            _ = shifted.settle(atSlot: 2)
        }

        #expect(visited == [0, 1, 2, 3, 0])
    }

    @Test("Swiping back from the first page lands on the last one")
    func backwardCycleWrapsAround() {
        var shifted = WelcomeCarousel(pageCount: 4)
        _ = shifted.settle(atSlot: 0)
        #expect(shifted.currentPage == 3)
        #expect(shifted.pageIndex(forSlot: 2) == 0)
    }

    @Test("A single-page carousel stays on its only page")
    func singlePageIsSafe() {
        var single = WelcomeCarousel(pageCount: 1)
        _ = single.settle(atSlot: 2)
        #expect(single.currentPage == 0)
        #expect(single.slots.map(single.pageIndex(forSlot:)) == [0, 0, 0])
    }

    @Test("A page count below one is raised to one")
    func pageCountHasAMinimum() {
        #expect(WelcomeCarousel(pageCount: 0).pageCount == 1)
    }

    @Test("The current page is wrapped into range")
    func currentPageIsWrapped() {
        #expect(WelcomeCarousel(pageCount: 4, currentPage: 5).currentPage == 1)
        #expect(WelcomeCarousel(pageCount: 4, currentPage: -1).currentPage == 3)
    }
}
