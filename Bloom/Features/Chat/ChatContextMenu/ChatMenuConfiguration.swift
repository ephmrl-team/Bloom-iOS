//
//  ChatMenuConfiguration.swift
//  Bloom
//

import SwiftUI

/// Presentation knobs for the chat context menu. Everything visual lives here so the menu can be
/// tuned without touching the transfer or the layout.
struct ChatMenuConfiguration {
    var liftScale: CGFloat = 1.09
    var menuWidth: CGFloat = 248
    var cornerRadius: CGFloat = Theme.radius.xl
    var rowHeight: CGFloat = 52
    var actionsPadding: CGFloat = 8
    var dividerHeight: CGFloat = Theme.borderWidth.md
    var reactionItemSize: CGFloat = 44
    var reactionCollapseSize: CGFloat = 37
    var reactionSqueezeWidth: CGFloat = 52
    var menuSqueezeHeight: CGFloat = 78
    var reactionPadding: CGFloat = 4
    var gap: CGFloat = 16
    var edgeInset: CGFloat = 16
    var backdropColor: Color = Theme.colors.menuBackdrop
    var backdropOpacity: Double = 0.5
    var reactions: [String] = ["❤️", "👍", "👎", "😂", "‼️", "❓"]
    var shadow = ChatMenuShadowStyle()
    var plateInset: CGFloat = 1 // the plate sits 2 pt inside the bubble
    var plateCornerRadius: CGFloat = 23.5
    var menuStartScale: CGFloat = 0.07
    var reactionCollapseAnimation: Animation = .smooth(duration: 0.18)
    var appearUnfoldAnimation: Animation = .spring(response: 0.36, dampingFraction: 0.68)
    var appearMorphAnimation: Animation = .spring(response: 0.38, dampingFraction: 0.66)
    var dismissMorphAnimation: Animation = .spring(response: 0.28, dampingFraction: 0.92)
    var reactionMorphDelay: TimeInterval = 0.09
    var enterBlur: CGFloat = 4
    var exitBlur: CGFloat = 6
    var plateTintMine: Color = Theme.colors.primary.opacity(0.34)
    var plateTintTheirs: Color = Theme.colors.glassTint
    var liftAnimation: Animation = .spring(response: 0.34, dampingFraction: 0.88)
    var controlAnimation: Animation = .spring(response: 0.34, dampingFraction: 0.72)
    var backdropAnimation: Animation = .easeOut(duration: 0.22)
    var reduceMotionAnimation: Animation = .easeOut(duration: 0.14)

    var reactionBarHeight: CGFloat {
        reactionItemSize + reactionPadding * 2
    }

    func reactionBarSize(count: Int) -> CGSize {
        CGSize(
            width: CGFloat(count) * reactionItemSize + reactionPadding * 2,
            height: reactionBarHeight
        )
    }

    func actionsSize(rows: Int) -> CGSize {
        CGSize(
            width: menuWidth,
            height: CGFloat(rows) * rowHeight + CGFloat(rows - 1) * dividerHeight + actionsPadding * 2
        )
    }
}

/// Shadow under the lifted content. `isEnabled == false` removes it completely.
struct ChatMenuShadowStyle {
    var color: Color = Theme.colors.liftedShadow
    var radius: CGFloat = 16
    var offset: CGSize = .init(width: 0, height: 6)
    var isEnabled = true
}
