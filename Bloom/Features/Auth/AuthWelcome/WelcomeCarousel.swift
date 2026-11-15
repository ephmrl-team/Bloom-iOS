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

    /// How close to an edge of the pool the position may get before it is pulled back
    /// to the middle run. One card: the outermost card has no neighbour on its outer
    /// side, and jumping any earlier resets the scroll while the user is still dragging.
    private static let edgeSlack = 1

    /// The card to jump to once `item` has reached the edge of the pool, or `nil` while
    /// it still has runway. The target is the same page in the middle run.
    func recenteredItem(forItem item: Int) -> Int? {
        let nearStart = item <= Self.edgeSlack
        let nearEnd = item >= poolCount - 1 - Self.edgeSlack
        guard nearStart || nearEnd else { return nil }

        let target = startItem + pageIndex(forItem: item)
        return target == item ? nil : target
    }
}
