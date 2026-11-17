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

    @ObservationIgnored private weak var window: UIWindow?
    @ObservationIgnored private var safeAreaBottom: CGFloat = 0
    @ObservationIgnored private var keyboardHeight: CGFloat = 0
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

    func dismiss() {
        if let window {
            window.endEditing(true)
        } else {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }
    }

    @objc private func keyboardChanged(_ notification: Notification) {
        guard let window,
              let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        let frameInWindow = window.convert(frame, from: window.screen.coordinateSpace)
        let height = Self.dockedHeight(for: frameInWindow, in: window.bounds)
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
