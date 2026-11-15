//
//  WelcomeCarousel.swift
//  Bloom
//

/// The window the welcome carousel scrolls through.
///
/// Three cards are in the scroll view at any moment: the current page and one on either
/// side. When a swipe settles, the window shifts by the pages that were swiped and the
/// current page returns to the middle slot, so the same three cards keep being reused
/// instead of the scroll running to the end of a fixed pool. The cards under the finger
/// do not move: the slot that was swiped into becomes the middle one, which is what makes
/// the shift invisible.
struct WelcomeCarousel {
    /// Cards in the scroll view. More would be built and never seen.
    static let windowSize = 3
    /// Slot the current page sits in.
    static let currentSlot = 1

    let pageCount: Int
    private(set) var currentPage: Int

    init(pageCount: Int, currentPage: Int = 0) {
        self.pageCount = max(pageCount, 1)
        self.currentPage = ((currentPage % self.pageCount) + self.pageCount) % self.pageCount
    }

    /// Slots of the window, left to right.
    var slots: Range<Int> {
        0..<Self.windowSize
    }

    /// Which page a slot shows.
    func pageIndex(forSlot slot: Int) -> Int {
        wrap(currentPage + slot - Self.currentSlot)
    }

    /// Takes the slot the scroll came to rest on and returns the slot to hold from now
    /// on. The window moves by the swiped distance, so the card the user swiped to
    /// becomes the current one and everything on screen stays where it is.
    mutating func settle(atSlot slot: Int) -> Int {
        currentPage = wrap(currentPage + slot - Self.currentSlot)
        return Self.currentSlot
    }

    private func wrap(_ page: Int) -> Int {
        ((page % pageCount) + pageCount) % pageCount
    }
}
