//
//  KeyboardTrackerHost.swift
//  Bloom
//

import SwiftUI
import UIKit

/// Zero-size probe that hands the keyboard's position over to `KeyboardTracker`.
struct KeyboardTrackerHost: UIViewRepresentable {
    let tracker: KeyboardTracker

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.onWindow = { [tracker] probe, window in
            tracker.attach(guide: probe.guide, in: window)
        }
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {}

    final class ProbeView: UIView {
        /// Spans from the keyboard's top edge to the bottom of the window.
        let guide = UIView()

        var onWindow: ((ProbeView, UIWindow) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, guide.superview == nil else { return }

            guide.isUserInteractionEnabled = false
            guide.alpha = 0
            guide.translatesAutoresizingMaskIntoConstraints = false
            addSubview(guide)
            NSLayoutConstraint.activate([
                guide.topAnchor.constraint(equalTo: window.keyboardLayoutGuide.topAnchor),
                guide.bottomAnchor.constraint(equalTo: window.bottomAnchor),
                guide.leadingAnchor.constraint(equalTo: leadingAnchor),
                guide.widthAnchor.constraint(equalToConstant: 1)
            ])
            onWindow?(self, window)
        }
    }
}
