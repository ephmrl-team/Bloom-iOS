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
        view.onPopBegan = { [weak tracker] in tracker?.dismiss() }
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}

    final class ProbeView: UIView {
        var onWindow: ((UIWindow) -> Void)?
        var onPopBegan: (() -> Void)?
        private weak var popGesture: UIGestureRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window {
                onWindow?(window)
            }
            attachPopGesture()
        }

        /// Dismiss the keyboard as soon as the interactive back swipe starts, before the pop completes.
        private func attachPopGesture() {
            guard popGesture == nil else { return }

            var responder: UIResponder? = self
            while let current = responder {
                if let navigation = current as? UINavigationController,
                   let gesture = navigation.interactivePopGestureRecognizer
                {
                    gesture.addTarget(self, action: #selector(popGestureChanged))
                    popGesture = gesture
                    return
                }
                responder = current.next
            }
        }

        @objc private func popGestureChanged() {
            guard let popGesture else { return }
            switch popGesture.state {
            case .began:
                onPopBegan?()
            case .ended, .cancelled:
                // shortcut: fixed 400 ms guess for UIKit restoring the first responder after a cancelled pop.
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(400))
                    self?.onPopBegan?()
                }
            default:
                break
            }
        }
    }
}
