//
//  ChatMenuControls.swift
//  Bloom
//

import SwiftUI

/// Everything the glass blocks need to draw one frame of the menu.
struct ChatMenuControlsState {
    var item: MessageItem
    var layout: ChatMenuLayout
    var lifted: Bool
    var reactionsFull: Bool
    var reactionsDot: Bool
    var menuFull: Bool
    var menuDot: Bool
    var contentBlur: CGFloat
    var liftAnimation: Animation
    var collapseAnimation: Animation
    var morphAnimation: Animation
}

/// Plate, reactions and menu in one `GlassEffectContainer`: they grow out of the message and morph apart.
struct ChatMenuControls: View {
    let state: ChatMenuControlsState
    let model: ChatContextMenuModel

    @Namespace private var glass

    var body: some View {
        GlassEffectContainer(spacing: config.gap) {
            ZStack(alignment: .topLeading) {
                plate
                reactionBar
                actionMenu
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var config: ChatMenuConfiguration {
        model.configuration
    }

    private var plate: some View {
        let rect = state.lifted ? plateRect(state.layout.content) : dot(in: anchorPlate, size: config.reactionBarHeight)
        return Color.clear
            .frame(width: rect.width, height: rect.height)
            .glassEffect(
                .regular.tint(state.item.me ? config.plateTintMine : config.plateTintTheirs),
                in: RoundedRectangle(cornerRadius: config.plateCornerRadius, style: .continuous)
            )
            .glassEffectID("plate", in: glass)
            .offset(x: rect.minX, y: rect.minY)
            .animation(state.liftAnimation, value: state.lifted)
    }

    private var reactionBar: some View {
        let rect = reactionRect
        return ChatReactionBar(
            selected: model.reactions[state.item.id],
            shown: !state.reactionsDot,
            blur: state.contentBlur,
            isMine: state.item.me,
            configuration: config
        ) { reaction in
            model.react(reaction)
        }
        .frame(width: rect.width, height: rect.height)
        .clipShape(Capsule())
        .glassEffect(.regular.interactive(), in: Capsule())
        .glassEffectID("reactions", in: glass)
        .offset(x: rect.minX, y: rect.minY)
        .animation(state.collapseAnimation, value: state.reactionsFull)
        .animation(state.morphAnimation, value: state.reactionsDot)
    }

    private var actionMenu: some View {
        let rect = actionRect
        return ChatMenuActionsView(
            actions: model.actions,
            shown: !state.menuDot,
            blur: state.contentBlur,
            configuration: config,
            onSelect: run
        )
        .frame(width: rect.width, height: rect.height, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous))
        .glassEffect(
            .regular.interactive(),
            in: RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
        )
        .glassEffectID("actions", in: glass)
        .offset(x: rect.minX, y: rect.minY)
        .animation(state.collapseAnimation, value: state.menuFull)
        .animation(state.morphAnimation, value: state.menuDot)
    }

    /// Full bar, then a pill squeezed around its centre, then a dot inside the plate.
    private var reactionRect: CGRect {
        if state.reactionsFull {
            return state.layout.reactions
        }
        return state.reactionsDot ? collapsedDot : squeezed(state.layout.reactions)
    }

    /// Same three steps for the menu: full block, a column squeezed around its centre, then the dot.
    private var actionRect: CGRect {
        if state.menuFull {
            return state.layout.actions
        }
        return state.menuDot ? collapsedDot : squeezed(state.layout.actions, height: config.menuSqueezeHeight)
    }

    /// The blocks collapse where the message started, not where it is heading.
    private var collapsedDot: CGRect {
        dot(in: anchorPlate, size: config.reactionCollapseSize)
    }

    private var anchorPlate: CGRect {
        plateRect(model.anchor)
    }

    /// Slightly smaller than the message it backs, so it stays hidden under the bubble.
    private func plateRect(_ content: CGRect) -> CGRect {
        content.insetBy(dx: config.plateInset, dy: config.plateInset)
    }

    /// A dot in the middle of the message: everything morphs out of the content's centre.
    private func dot(in content: CGRect, size: CGFloat) -> CGRect {
        let side = min(size, content.width, content.height)
        return CGRect(x: content.midX - side / 2, y: content.midY - side / 2, width: side, height: side)
    }

    private func squeezed(_ rect: CGRect, height: CGFloat? = nil) -> CGRect {
        let width = config.reactionSqueezeWidth
        let target = height ?? rect.height
        return CGRect(x: rect.midX - width / 2, y: rect.midY - target / 2, width: width, height: target)
    }

    private func run(_ action: ChatMenuAction) {
        let actions = model.actions
        switch action {
        case .copy:
            model.run(actions.copy)
        case .reply:
            model.run(actions.reply)
        case .forward:
            model.run(actions.forward)
        case .delete:
            if let delete = actions.delete {
                model.run(delete)
            }
        }
    }
}
