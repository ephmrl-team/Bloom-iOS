//
//  WelcomeCarousel.swift
//  Bloom
//

/// Index math for the endless welcome carousel.
///
/// The pool is `copies` back-to-back runs of the pages and the middle run is the one on
/// screen. Once the position leaves that run the pool jumps by whole runs to the same
/// page in the middle, which looks like nothing happened because every run holds the same
/// pages. Kept out of the view so the jumps can be checked without a screen.
struct WelcomeCarousel {
    let pageCount: Int
    let copies: Int

    init(pageCount: Int, copies: Int = 3) {
        self.pageCount = max(pageCount, 1)
        self.copies = max(copies, 3)
    }

    /// Cards in the scroll view. All of them are built eagerly, so this is what the
    /// screen costs: three runs is the fewest that still leaves a whole run of runway on
    /// either side of the middle one.
    var poolCount: Int {
        pageCount * copies
    }

    /// Where the carousel opens: the first page of the middle run, so both of its
    /// neighbours exist and the left edge is never empty.
    var startItem: Int {
        pageCount * (copies / 2)
    }

    /// Which page a card shows.
    func pageIndex(forItem item: Int) -> Int {
        item % pageCount
    }

    /// The card to jump to once `item` has left the middle run, or `nil` while it is
    /// still inside it. The target is the same page in the middle run.
    func recenteredItem(forItem item: Int) -> Int? {
        let first = startItem
        let last = first + pageCount - 1
        guard item < first || item > last else { return nil }
        return first + pageIndex(forItem: item)
    }
}
