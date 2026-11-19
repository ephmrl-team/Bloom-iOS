//
//  KeyboardTracker.swift
//  Bloom
//

import Observation
import SwiftUI
import UIKit

@Observable
@MainActor
final class KeyboardTracker: NSObject {
    static let hiddenPadding: CGFloat = 28
    static let visiblePadding: CGFloat = 16

    private(set) var progress: CGFloat = 0
    /// Where the scroll view's bottom edge sits and how much of it is inset: together they say where
    /// the last message is on screen, whatever moves it.
    private(set) var contentBottomInset: CGFloat = 0
    private(set) var scrollFrame: CGRect = .zero
    /// Bumped when the back swipe takes the keyboard away, so the composer drops its focus state too.
    private(set) var focusResets = 0
    /// Bumped when the chat menu closes, so the composer takes the keyboard back.
    private(set) var focusRestores = 0

    @ObservationIgnored private weak var window: UIWindow?
    @ObservationIgnored private var safeAreaBottom: CGFloat = 0
    @ObservationIgnored private var keyboardHeight: CGFloat = 0
    @ObservationIgnored private var keyboardDocked = false
    /// Screen position of the content's bottom edge when the menu opened; `nil` when nothing is held.
    @ObservationIgnored private var lockedViewportBottom: CGFloat?
    @ObservationIgnored private var shouldRestoreAfterMenu = false
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardChanged(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    static func padding(for progress: CGFloat) -> CGFloat {
        hiddenPadding + (visiblePadding - hiddenPadding) * progress
    }

    static func bottomInset(for progress: CGFloat) -> CGFloat {
        hiddenPadding + (Theme.spacing.md - hiddenPadding) * progress
    }

    static func dockedHeight(for frame: CGRect, in bounds: CGRect) -> CGFloat {
        let overlap = bounds.intersection(frame)
        guard !overlap.isNull, frame.maxY >= bounds.maxY - 0.5 else { return 0 }
        return overlap.height
    }

    static func progress(safeArea: CGFloat, restingInset: CGFloat, keyboardHeight: CGFloat) -> CGFloat {
        guard keyboardHeight > restingInset else { return 0 }
        return min(1, max(0, (safeArea - restingInset) / (keyboardHeight - restingInset)))
    }

    func attach(in window: UIWindow) {
        self.window = window
        updateProgress()
    }

    func update(safeAreaBottom: CGFloat) {
        self.safeAreaBottom = safeAreaBottom
        updateProgress()
    }

    /// Keyboard height while it is on screen, `nil` when it is hidden.
    var visibleHeight: CGFloat? {
        keyboardDocked && keyboardHeight > 0 ? keyboardHeight : nil
    }

    /// Empty room under the last message while the menu holds the keyboard's place: it opens up as
    /// the content's bottom edge drops back down and closes again as the keyboard returns, so the
    /// messages never move.
    var frozenMessageBottomPadding: CGFloat {
        guard let lockedViewportBottom else { return 0 }
        return max(0, viewportBottom - lockedViewportBottom)
    }

    /// Drops the keyboard without moving the messages: the room it frees is handed to the scroll
    /// content, so the menu backdrop can cover the whole screen.
    func suspendForContextMenu() {
        shouldRestoreAfterMenu = visibleHeight != nil
        lockedViewportBottom = viewportBottom
        resetFocus()
    }

    /// Called once the bubble is back in the list: the composer takes the keyboard back.
    func resumeAfterContextMenu() {
        guard shouldRestoreAfterMenu else { return }
        shouldRestoreAfterMenu = false
        focusRestores &+= 1
    }

    /// The screen is going away: drop the hold without bringing the keyboard back.
    func resetContextMenuLock() {
        lockedViewportBottom = nil
        shouldRestoreAfterMenu = false
    }

    /// Fed from the chat's scroll view: its bottom edge on screen and how much of it is inset.
    func update(contentBottomInset: CGFloat) {
        self.contentBottomInset = contentBottomInset
    }

    func update(scrollFrame: CGRect) {
        self.scrollFrame = scrollFrame
    }

    private var viewportBottom: CGFloat {
        scrollFrame.maxY - contentBottomInset
    }

    func dismiss() {
        if let window {
            window.endEditing(true)
        } else {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }
    }

    /// Resigns the keyboard and clears the composer's focus, so a cancelled back swipe cannot restore it.
    func resetFocus() {
        focusResets &+= 1
        dismiss()
    }

    @objc private func keyboardChanged(_ notification: Notification) {
        guard let window,
              let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        let frameInWindow = window.convert(frame, from: window.screen.coordinateSpace)
        let height = Self.dockedHeight(for: frameInWindow, in: window.bounds)
        keyboardDocked = height > 0
        if height > 0 {
            keyboardHeight = height
        }
        updateProgress()
    }

    private func updateProgress() {
        guard let window else { return }
        progress = Self.progress(
            safeArea: safeAreaBottom,
            restingInset: window.safeAreaInsets.bottom,
            keyboardHeight: keyboardHeight
        )
    }
}
