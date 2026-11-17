//
//  WelcomeCarouselTests.swift
//  Bloom
//

@testable import Bloom
import Testing

@Suite("Welcome carousel")
struct WelcomeCarouselTests {
    private let carousel = WelcomeCarousel(pageCount: 4)

    @Test("The window holds eight cards with the current page in the middle")
    func windowShowsNeighbours() {
        #expect(carousel.slots.count == 8)
        #expect(carousel.currentSlot == WelcomeCarousel.middleSlot)
        #expect(carousel.pageIndex(forSlot: WelcomeCarousel.middleSlot) == 0)
        #expect(carousel.pageIndex(forSlot: 0) == 1)
        #expect(carousel.pageIndex(forSlot: 7) == 0)
    }

    @Test("Every slot shows a real page")
    func slotsStayInRange() {
        for page in 0..<4 {
            let shifted = WelcomeCarousel(pageCount: 4, currentPage: page)
            let pages = shifted.slots.map(shifted.pageIndex(forSlot:))
            #expect(pages.allSatisfy { (0..<4).contains($0) })
            #expect(pages[WelcomeCarousel.middleSlot] == page)
        }
    }

    @Test("A swipe in the middle of the window changes nothing on screen")
    func innerSwipeKeepsTheCards() {
        var shifted = carousel
        let before = shifted.slots.map(shifted.pageIndex(forSlot:))

        let target = shifted.settle(atSlot: WelcomeCarousel.middleSlot + 1)

        #expect(target == nil)
        #expect(shifted.slots.map(shifted.pageIndex(forSlot:)) == before)
        #expect(shifted.currentPage == 1)
    }

    @Test("A swipe near an end refills the window without moving the cards")
    func edgeSwipeRefillsInPlace() {
        for slot in [WelcomeCarousel.edgeSlack, WelcomeCarousel.windowSize - 1 - WelcomeCarousel.edgeSlack] {
            var shifted = carousel
            let before = shifted.slots.map(shifted.pageIndex(forSlot:))

            let target = shifted.settle(atSlot: slot)

            #expect(target == WelcomeCarousel.middleSlot)
            // The page the user swiped to is the current one and keeps its slot.
            #expect(shifted.pageIndex(forSlot: WelcomeCarousel.middleSlot) == before[slot])
            // Everything that was on screen is still in the same slot.
            for moved in shifted.slots where before.indices.contains(moved + slot - WelcomeCarousel.middleSlot) {
                let old = moved + slot - WelcomeCarousel.middleSlot
                #expect(shifted.pageIndex(forSlot: moved) == before[old])
            }
        }
    }

    @Test("Swiping forward walks the pages in order and wraps at the end")
    func forwardCycleWrapsAround() {
        var shifted = WelcomeCarousel(pageCount: 4)
        var visited: [Int] = []

        for _ in 0..<5 {
            visited.append(shifted.currentPage)
            shifted.settle(atSlot: shifted.currentSlot + 1)
        }

        #expect(visited == [0, 1, 2, 3, 0])
    }

    @Test("Swiping back from the first page lands on the last one")
    func backwardCycleWrapsAround() {
        var shifted = WelcomeCarousel(pageCount: 4)
        shifted.settle(atSlot: WelcomeCarousel.middleSlot - 1)
        #expect(shifted.currentPage == 3)
    }

    @Test("A refill always leaves the same number of cards on both sides")
    func refillLeavesRunway() {
        for slot in 0..<WelcomeCarousel.windowSize {
            var shifted = carousel
            shifted.settle(atSlot: slot)
            #expect(shifted.currentSlot >= WelcomeCarousel.edgeSlack + 1)
            #expect(shifted.currentSlot <= WelcomeCarousel.windowSize - 2 - WelcomeCarousel.edgeSlack)
        }
    }

    @Test("A single-page carousel stays on its only page")
    func singlePageIsSafe() {
        var single = WelcomeCarousel(pageCount: 1)
        single.settle(atSlot: 7)
        #expect(single.currentPage == 0)
        #expect(single.slots.map(single.pageIndex(forSlot:)).allSatisfy { $0 == 0 })
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
