//
//  WelcomeCarousel.swift
//  Bloom
//

/// The window the welcome carousel scrolls through.
///
/// Eight cards are in the scroll view at any moment and they are reused: the current
/// page sits somewhere in the middle, and once a swipe stops within `edgeSlack` cards of
/// either end, the window is refilled around it. Reusing the cards keeps the scroll from
/// ever reaching an end, and because the pages keep their slots the refill changes
/// nothing on screen.
struct WelcomeCarousel {
    /// Cards in the scroll view. Enough to swipe a few pages before a refill.
    static let windowSize = 8
    /// Slot the current page returns to when the window is refilled.
    static let middleSlot = 3
    /// A refill happens when the scroll stops this close to an end, so the cards that
    /// are about to be needed are always there before the swipe gets to them.
    static let edgeSlack = 1

    let pageCount: Int
    private(set) var currentPage: Int
    private(set) var currentSlot: Int

    init(pageCount: Int, currentPage: Int = 0) {
        self.pageCount = max(pageCount, 1)
        self.currentPage = ((currentPage % self.pageCount) + self.pageCount) % self.pageCount
        self.currentSlot = Self.middleSlot
    }

    /// Slots of the window, left to right.
    var slots: Range<Int> {
        0..<Self.windowSize
    }

    /// Which page a slot shows.
    func pageIndex(forSlot slot: Int) -> Int {
        wrap(currentPage + slot - currentSlot)
    }

    /// Takes the slot the scroll came to rest on and returns the slot to hold from now
    /// on, or nil when the window does not need refilling.
    ///
    /// The pages keep their slots, so the only visible difference is the one the refill
    /// makes: the current page moves back to the middle and the scroll with it, which
    /// leaves every card where it was.
    @discardableResult
    mutating func settle(atSlot slot: Int) -> Int? {
        currentPage = wrap(currentPage + slot - currentSlot)
        currentSlot = slot

        guard slot <= Self.edgeSlack || slot >= Self.windowSize - 1 - Self.edgeSlack else {
            return nil
        }

        currentSlot = Self.middleSlot
        return currentSlot
    }

    private func wrap(_ page: Int) -> Int {
        ((page % pageCount) + pageCount) % pageCount
    }
}
