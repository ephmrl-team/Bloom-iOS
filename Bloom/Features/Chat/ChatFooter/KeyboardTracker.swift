//
//  KeyboardTracker.swift
//  Bloom
//

import Observation
import QuartzCore
import SwiftUI
import UIKit

/// Follows the keyboard every frame, including animated and interactive transitions,
/// so the composer can move with it instead of jumping on a bool.
@Observable
@MainActor
final class KeyboardTracker {
    /// Composer inset from the screen bottom while the keyboard is hidden.
    static let hiddenPadding: CGFloat = 28
    /// Composer inset above the keyboard while it is shown.
    static let visiblePadding: CGFloat = 16

    private(set) var height: CGFloat = 0
    private(set) var progress: CGFloat = 0
    /// Padding the composer ends the current transition at. The text inside the
    /// input takes its final width from here before the transition starts.
    private(set) var targetPadding: CGFloat = hiddenPadding

    /// Distance from the screen bottom the composer stands at right now.
    var bottomPadding: CGFloat {
        height + Self.padding(for: progress)
    }

    static func padding(for progress: CGFloat) -> CGFloat {
        hiddenPadding + (visiblePadding - hiddenPadding) * progress
    }

    static func dockedHeight(for frame: CGRect, in bounds: CGRect) -> CGFloat {
        let overlap = bounds.intersection(frame)
        guard !overlap.isNull, frame.maxY >= bounds.maxY - 0.5 else { return 0 }
        return overlap.height
    }

    @ObservationIgnored private var targetHeight: CGFloat = 0
    @ObservationIgnored private var denominator: CGFloat = 0
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private weak var guide: UIView?
    @ObservationIgnored private weak var window: UIWindow?
    @ObservationIgnored private var idleTicks = 0
    @ObservationIgnored private var ticks = 0
    @ObservationIgnored private let linkProxy = DisplayLinkProxy()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init() {
        linkProxy.owner = self

        let center = NotificationCenter.default
        let keyboardNames: [Notification.Name] = [
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardWillHideNotification
        ]
        observers = keyboardNames.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                MainActor.assumeIsolated {
                    self?.handleKeyboardChange(note)
                }
            }
        }
    }

    deinit {
        link?.invalidate()
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    /// Starts following the guide that spans from the keyboard top to the window bottom.
    func attach(guide: UIView, in window: UIWindow) {
        self.guide = guide
        self.window = window
        startDisplayLink()
    }

    fileprivate func tick() {
        guard let guide, let window = guide.window else {
            stopDisplayLink()
            return
        }

        // The presentation layer is the only value that moves with the keyboard animation.
        let raw = guide.layer.presentation()?.frame.height ?? guide.frame.height
        // With no keyboard the guide rests on the bottom safe area edge, not the screen edge.
        let hiddenBottom = window.safeAreaInsets.bottom
        let progress: CGFloat = denominator > 0
            ? min(1, max(0, (raw - hiddenBottom) / max(1, denominator - hiddenBottom)))
            : 0
        // Scale the interpolated travel back to the real keyboard height, so a
        // half-open keyboard is half the distance, not half minus the safe area.
        let height = denominator * progress

        if abs(progress - self.progress) > 0.001 {
            self.progress = progress
        }
        if abs(height - self.height) > 0.5 {
            self.height = height
        }

        if abs(height - targetHeight) < 0.5 {
            idleTicks += 1
            if idleTicks > 6 {
                targetPadding = progress > 0.5 ? Self.visiblePadding : Self.hiddenPadding
                stopDisplayLink()
            }
        } else {
            idleTicks = 0
        }

        // A display link that outlives the transition keeps the main run loop busy
        // forever, which hangs every accessibility query on the screen.
        ticks += 1
        if ticks > 240 {
            stopDisplayLink()
        }
    }

    private func handleKeyboardChange(_ note: Notification) {
        // shortcut: an interactive dismissal is followed through the repeated
        // willChangeFrame notifications UIKit posts while the drag runs.
        guard let window,
              let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        let frameInWindow = window.convert(frame, from: window.screen.coordinateSpace)
        let newHeight = Self.dockedHeight(for: frameInWindow, in: window.bounds)
        guard abs(newHeight - targetHeight) > 0.5 else { return }
        targetHeight = newHeight
        if targetHeight > 0 {
            denominator = targetHeight
        }
        targetPadding = targetHeight > 0 ? Self.visiblePadding : Self.hiddenPadding
        startDisplayLink()
    }

    private func startDisplayLink() {
        guard link == nil else { return }
        idleTicks = 0
        ticks = 0

        let link = CADisplayLink(target: linkProxy, selector: #selector(DisplayLinkProxy.tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    private func stopDisplayLink() {
        link?.invalidate()
        link = nil
    }
}

private final class DisplayLinkProxy: NSObject {
    weak var owner: KeyboardTracker?

    @objc func tick() {
        owner?.tick()
    }
}
