//
//  KeyboardTrackerTests.swift
//  Bloom
//

@testable import Bloom
import CoreGraphics
import Testing

struct KeyboardTrackerTests {
    private let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)

    @Test func tracksOnlyTheKeyboardOverlappingTheWindowBottom() {
        #expect(KeyboardTracker.dockedHeight(for: CGRect(x: 0, y: 544, width: 390, height: 300), in: bounds) == 300)
        #expect(KeyboardTracker.dockedHeight(for: CGRect(x: 0, y: 700, width: 390, height: 300), in: bounds) == 144)
        #expect(KeyboardTracker.dockedHeight(for: CGRect(x: 0, y: 844, width: 390, height: 300), in: bounds) == 0)
        #expect(KeyboardTracker.dockedHeight(for: CGRect(x: 40, y: 300, width: 300, height: 250), in: bounds) == 0)
    }

    @Test func interpolatesComposerPadding() {
        #expect(KeyboardTracker.padding(for: 0) == KeyboardTracker.hiddenPadding)
        #expect(KeyboardTracker.padding(for: 1) == KeyboardTracker.visiblePadding)
        #expect(KeyboardTracker.padding(for: 0.5) == 22)
        #expect(KeyboardTracker.bottomInset(for: 0) == 28)
        #expect(KeyboardTracker.bottomInset(for: 1) == 12)
        #expect(KeyboardTracker.bottomInset(for: 0.5) == 20)
    }

    @Test func mapsSafeAreaToKeyboardProgress() {
        #expect(KeyboardTracker.progress(safeArea: 34, restingInset: 34, keyboardHeight: 328) == 0)
        #expect(KeyboardTracker.progress(safeArea: 181, restingInset: 34, keyboardHeight: 328) == 0.5)
        #expect(KeyboardTracker.progress(safeArea: 328, restingInset: 34, keyboardHeight: 328) == 1)
        #expect(KeyboardTracker.progress(safeArea: 400, restingInset: 34, keyboardHeight: 328) == 1)
        #expect(KeyboardTracker.progress(safeArea: 0, restingInset: 34, keyboardHeight: 0) == 0)
    }
}
