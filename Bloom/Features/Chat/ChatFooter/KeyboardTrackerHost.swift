//
//  KeyboardTrackerHost.swift
//  Bloom
//

import SwiftUI
import UIKit

struct KeyboardTrackerHost: UIViewRepresentable {
    let tracker: KeyboardTracker

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.onWindow = { [weak tracker] window in tracker?.attach(in: window) }
        view.onPopHideKeyboard = { [weak tracker] in tracker?.resetFocus() }
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}

    final class ProbeView: UIView {
        var onWindow: ((UIWindow) -> Void)?
        var onPopHideKeyboard: (() -> Void)?
        private weak var popGesture: UIGestureRecognizer?
        private weak var navigation: UINavigationController?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window {
                onWindow?(window)
            }
            attachPopGesture()
        }

        /// Dismiss the keyboard as soon as the interactive back swipe starts, before the pop completes.
        private func attachPopGesture() {
            var responder: UIResponder? = self
            while let current = responder {
                if let navigation = current as? UINavigationController {
                    let gesture = navigation.interactivePopGestureRecognizer
                    if let gesture, popGesture == nil {
                        gesture.addTarget(self, action: #selector(popGestureChanged))
                        popGesture = gesture
                    }
                    // The system delegate limits the swipe to the screen edge.
                    PopGestureDelegate.shared.navigation = navigation
                    PopGestureDelegate.shared.onWillPop = { [weak self] in self?.onPopHideKeyboard?() }
                    gesture?.delegate = PopGestureDelegate.shared
                    self.navigation = navigation
                    return
                }
                responder = current.next
            }
        }

        @objc private func popGestureChanged() {
            switch popGesture?.state {
            case .began:
                onPopHideKeyboard?()
            case .ended, .cancelled:
                // Lifting the finger without completing the pop ends the gesture and only then makes the
                // transition cancel; UIKit brings the first responder back with it.
                onPopHideKeyboard?()
                navigation?.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
                    self?.onPopHideKeyboard?()
                }, completion: { [weak self] _ in
                    self?.onPopHideKeyboard?()
                    Task { @MainActor in self?.onPopHideKeyboard?() }
                })
            default:
                break
            }
        }
    }
}

/// Makes the system interactive pop gesture work from anywhere, not only the screen edge.
final class PopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = PopGestureDelegate()
    weak var navigation: UINavigationController?
    var onWillPop: (() -> Void)?

    func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard let navigation, navigation.viewControllers.count > 1 else { return false }
        guard let pan = gesture as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: pan.view)
        guard velocity.x > 0, abs(velocity.x) > abs(velocity.y) else { return false }
        // Resign before the navigation controller saves the first responder for the interactive
        // transition; otherwise a cancelled pop restores the keyboard and the composer bounces.
        onWillPop?()
        return true
    }

    func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Horizontal drags inside a text input move the caret, they must not pop the screen.
        var view = touch.view
        while let current = view {
            if current is UITextView || current is UITextField {
                return false
            }
            view = current.superview
        }
        return true
    }
}
