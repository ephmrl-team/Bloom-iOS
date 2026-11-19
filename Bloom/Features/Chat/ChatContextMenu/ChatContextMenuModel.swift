//
//  ChatContextMenuModel.swift
//  Bloom
//

import OSLog
import SwiftUI
import UIKit

/// Owns the transparent overlay window and the state of the lifted chat menu.
@Observable
@MainActor
final class ChatContextMenuModel {
    private(set) var item: MessageItem?
    private(set) var anchor: CGRect = .zero
    private(set) var bounds: CGRect = .zero
    private(set) var safeArea: UIEdgeInsets = .zero
    private(set) var actions = ChatMenuActions()
    private(set) var isDismissing = false
    private(set) var reactions: [Int: String] = [:]
    var configuration = ChatMenuConfiguration()

    @ObservationIgnored private var window: UIWindow?
    @ObservationIgnored private var pendingAction: (() -> Void)?
    @ObservationIgnored private let ref = ChatContextMenuModelRef()

    var liftedRenderID: UUID? {
        item?.renderID
    }

    func present(item: MessageItem, anchor: CGRect, actions: ChatMenuActions) {
        guard anchor.width > 0, anchor.height > 0 else { return }
        guard let scene = activeScene else {
            Logger.bloom.error("chat menu: no active window scene")
            return
        }

        self.item = item
        self.anchor = anchor
        self.actions = actions
        bounds = scene.effectiveGeometry.coordinateSpace.bounds
        safeArea = scene.keyWindowInsets
        pendingAction = nil
        isDismissing = false

        let window = ensureWindow(in: scene)
        window.frame = bounds
        window.isUserInteractionEnabled = true
        window.isHidden = false
        ChatMenuHaptics.lift()
    }

    func dismiss() {
        guard item != nil, !isDismissing else { return }
        isDismissing = true
    }

    func dismissImmediately() {
        pendingAction = nil
        isDismissing = false
        item = nil
        window?.isHidden = true
    }

    /// Runs after the return spring. The row un-hides and the overlay empties in the same update, so no
    /// frame shows both or neither; the window itself is hidden a beat later, once it draws nothing.
    func finishDismiss() {
        isDismissing = false
        let action = pendingAction
        pendingAction = nil
        item = nil
        window?.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self, item == nil, !isDismissing else { return }
            window?.isHidden = true
        }
        action?()
    }

    func react(_ reaction: String) {
        guard let item else { return }
        reactions[item.id] = reactions[item.id] == reaction ? nil : reaction
        ChatMenuHaptics.select()
        dismiss()
    }

    func run(_ action: @escaping () -> Void) {
        pendingAction = action
        ChatMenuHaptics.action()
        dismiss()
    }

    private var activeScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    private func ensureWindow(in scene: UIWindowScene) -> UIWindow {
        if let window {
            return window
        }

        ref.model = self
        let window = UIWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)
        window.backgroundColor = .clear
        let host = UIHostingController(rootView: ChatContextMenuRootView(ref: ref))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = true
        self.window = window
        return window
    }
}

/// The overlay window keeps its hosting view alive; a weak back-reference stops the cycle.
@MainActor
final class ChatContextMenuModelRef {
    weak var model: ChatContextMenuModel?
}

private extension UIWindowScene {
    var keyWindowInsets: UIEdgeInsets {
        (windows.first { $0.isKeyWindow } ?? windows.first)?.safeAreaInsets ?? .zero
    }
}
