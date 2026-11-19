//
//  ChatContextMenuOverlay.swift
//  Bloom
//

import SwiftUI

/// Backdrop, lifted bubble and glass controls. Positioned in window coordinates over everything.
struct ChatContextMenuOverlay: View {
    let model: ChatContextMenuModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false
    @State private var reactionsFull = false
    @State private var reactionsDot = true
    @State private var menuFull = false
    @State private var menuDot = true
    /// The pending unfold/squeeze step; cancelled whenever the menu opens or closes again.
    @State private var phaseTask: Task<Void, Never>?
    /// Computed once when the menu opens: it is pure geometry, not a per-frame value.
    @State private var layout: ChatMenuLayout?

    var body: some View {
        ZStack(alignment: .topLeading) {
            backdrop
            if let item = model.item, let layout {
                ChatMenuControls(state: controlsState(item, layout: layout), model: model)
                liftedContent(item, layout: layout)
            }
        }
        .ignoresSafeArea()
        .onChange(of: model.item?.renderID, initial: true) { _, id in
            if id == nil {
                phaseTask?.cancel()
                lifted = false
                layout = nil
            } else if let item = model.item {
                // Placed once per message, not once per animation frame.
                layout = ChatMenuLayoutEngine.make(layoutRequest(item))
                animateIn()
            }
        }
        .onChange(of: model.isDismissing) { _, dismissing in
            if dismissing {
                animateOut()
            }
        }
    }

    private var config: ChatMenuConfiguration {
        model.configuration
    }

    private var animation: Animation {
        reduceMotion ? config.reduceMotionAnimation : config.liftAnimation
    }

    /// Springy when the blocks unfold out of the message, smooth when they squeeze back in.
    private var collapseAnimation: Animation {
        guard !reduceMotion else { return config.reduceMotionAnimation }
        return model.isDismissing ? config.reactionCollapseAnimation : config.appearUnfoldAnimation
    }

    /// Springy on the way out of the message, crisp on the way back in.
    private var morphAnimation: Animation {
        guard !reduceMotion else { return config.reduceMotionAnimation }
        return model.isDismissing ? config.dismissMorphAnimation : config.appearMorphAnimation
    }

    private var phaseDelay: Duration {
        .seconds(reduceMotion ? 0 : config.reactionMorphDelay)
    }

    /// Motion blur on the controls' content while they travel.
    private var contentBlur: CGFloat {
        guard !reduceMotion, !lifted else { return 0 }
        return model.isDismissing ? config.exitBlur : config.enterBlur
    }

    private var backdrop: some View {
        config.backdropColor
            .opacity(lifted ? config.backdropOpacity : 0)
            .contentShape(.rect)
            .onTapGesture { model.dismiss() }
            .animation(reduceMotion ? animation : config.backdropAnimation, value: lifted)
    }

    private func liftedContent(_ item: MessageItem, layout: ChatMenuLayout) -> some View {
        ChatLiftedContent(
            item: item,
            anchor: model.anchor,
            center: lifted ? layout.content.center : model.anchor.center,
            scale: reduceMotion ? 1 : (lifted ? config.liftScale : 1),
            shadow: config.shadow,
            shadowOpacity: lifted ? 1 : 0
        )
        .animation(animation, value: lifted)
    }

    private func controlsState(_ item: MessageItem, layout: ChatMenuLayout) -> ChatMenuControlsState {
        ChatMenuControlsState(
            item: item,
            layout: layout,
            lifted: lifted,
            reactionsFull: reactionsFull,
            reactionsDot: reactionsDot,
            menuFull: menuFull,
            menuDot: menuDot,
            contentBlur: contentBlur,
            liftAnimation: animation,
            collapseAnimation: collapseAnimation,
            morphAnimation: morphAnimation
        )
    }

    private func layoutRequest(_ item: MessageItem) -> ChatMenuLayoutRequest {
        ChatMenuLayoutRequest(item: item, model: model, scale: reduceMotion ? 1 : config.liftScale)
    }

    /// Dots morph into pills, then the pills unfold into the full blocks.
    private func animateIn() {
        phaseTask?.cancel()
        lifted = false
        reactionsFull = false
        reactionsDot = true
        menuFull = false
        menuDot = true
        withAnimation(animation) {
            lifted = true
        }
        withAnimation(morphAnimation) {
            reactionsDot = false
            menuDot = false
        }
        phaseTask = Task { @MainActor in
            try? await Task.sleep(for: phaseDelay)
            guard isLive else { return }
            withAnimation(collapseAnimation) {
                reactionsFull = true
                menuFull = true
            }
        }
    }

    /// The menu may have closed or been replaced while a phase was waiting.
    private var isLive: Bool {
        !Task.isCancelled && model.item != nil && !model.isDismissing
    }

    /// The blocks squeeze into pills first, then mid-way pick up speed and morph into the plate.
    private func animateOut() {
        phaseTask?.cancel()
        withAnimation(animation) {
            lifted = false
        }
        withAnimation(collapseAnimation) {
            reactionsFull = false
            menuFull = false
        }
        phaseTask = Task { @MainActor in
            try? await Task.sleep(for: phaseDelay)
            guard !Task.isCancelled, model.isDismissing else { return }
            withAnimation(morphAnimation) {
                reactionsDot = true
                menuDot = true
            } completion: {
                model.finishDismiss()
            }
        }
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
