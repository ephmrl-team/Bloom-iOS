//
//  WelcomeCarouselTests.swift
//  Bloom
//

import Testing
@testable import Bloom

@Suite("Welcome carousel")
struct WelcomeCarouselTests {
    private let carousel = WelcomeCarousel(pageCount: 4, copies: 3)

    @Test("The pool holds one card per page per run")
    func poolCountMatchesRuns() {
        #expect(carousel.poolCount == 12)
        #expect(WelcomeCarousel(pageCount: 4, copies: 5).poolCount == 20)
    }

    @Test("The carousel opens on a page that has neighbours on both sides")
    func startItemHasNeighbours() {
        #expect(carousel.startItem == 4)
        #expect(carousel.startItem > 0)
        #expect(carousel.startItem < carousel.poolCount - 1)
        #expect(carousel.pageIndex(forItem: carousel.startItem) == 0)
    }

    @Test("Every card shows one of the pages")
    func pageIndexStaysInRange() {
        let pages = (0..<carousel.poolCount).map(carousel.pageIndex(forItem:))
        #expect(pages.allSatisfy { (0..<4).contains($0) })
        #expect(Set(pages) == [0, 1, 2, 3])
    }

    @Test("A card inside the middle run is not moved")
    func middleRunIsStable() {
        for item in 4..<8 {
            #expect(carousel.recenteredItem(forItem: item) == nil)
        }
    }

    @Test("A jump keeps the page and lands in the middle run")
    func jumpKeepsThePage() {
        for item in 0..<carousel.poolCount where !(4..<8).contains(item) {
            let target = carousel.recenteredItem(forItem: item)
            let unwrapped = try? #require(target)
            #expect(unwrapped.map(carousel.pageIndex(forItem:)) == carousel.pageIndex(forItem: item))
            #expect(unwrapped.map { (4..<8).contains($0) } == true)
        }
    }

    @Test("A jump cannot trigger the opposite jump")
    func jumpDoesNotBounce() throws {
        for item in 0..<carousel.poolCount {
            let target = try #require(carousel.recenteredItem(forItem: item) ?? item)
            #expect(carousel.recenteredItem(forItem: target) == nil)
        }
    }

    @Test("There is a whole run of runway on both sides of the middle run")
    func runwayCoversEveryDirection() {
        let first = carousel.startItem
        let last = first + 3
        #expect(first - 4 >= 0)
        #expect(last + 4 < carousel.poolCount)
    }

    @Test("A single-page carousel still starts and stays put")
    func singlePageIsSafe() {
        let single = WelcomeCarousel(pageCount: 1, copies: 3)
        #expect(single.startItem == 1)
        #expect(single.recenteredItem(forItem: single.startItem) == nil)
        #expect(single.pageIndex(forItem: 2) == 0)
    }

    @Test("Copies below three are raised to three, so a run always has runway")
    func copiesHaveAMinimum() {
        #expect(WelcomeCarousel(pageCount: 4, copies: 1).copies == 3)
    }
}
