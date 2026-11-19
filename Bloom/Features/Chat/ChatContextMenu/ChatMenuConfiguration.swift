//
//  ChatMenuConfiguration.swift
//  Bloom
//

import SwiftUI

/// Presentation knobs for the chat context menu. Everything visual lives here so the menu can be
/// tuned without touching the transfer or the layout.
struct ChatMenuConfiguration {
    var liftScale: CGFloat = 1.09
    var menuWidth: CGFloat = 240
    var cornerRadius: CGFloat = 32
    var rowHeight: CGFloat = 44
    var rowSpacing: CGFloat = 4
    var menuEdgePadding: CGFloat = 10
    /// Highlight inset from the menu edge, and the row content inset inside the highlight.
    var rowInset: CGFloat = 10
    var rowContentInset: CGFloat = 12
    var rowFontSize: CGFloat = 17
    var iconSize: CGFloat = 24
    var iconSpacing: CGFloat = 14
    var dividerHeight: CGFloat = Theme.borderWidth.md
    /// Room above and below the rule that separates Delete.
    var dividerSpacing: CGFloat = 8
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
    var plateInset: CGFloat = 0 // the plate sits 2 pt inside the bubble
    var plateCornerRadius: CGFloat = 23.5
    var menuStartScale: CGFloat = 0.07
    var reactionCollapseAnimation: Animation = .smooth(duration: 0.18)
    var appearUnfoldAnimation: Animation = .spring(response: 0.34, dampingFraction: 0.74)
    var appearMorphAnimation: Animation = .spring(response: 0.34, dampingFraction: 0.76)
    var dismissMorphAnimation: Animation = .spring(response: 0.26, dampingFraction: 0.92)
    var reactionMorphDelay: TimeInterval = 0.06
    var enterBlur: CGFloat = 4
    var exitBlur: CGFloat = 6
    var plateTintMine: Color = Theme.colors.primary.opacity(0.34)
    var plateTintTheirs: Color = Theme.colors.glassTint
    var liftAnimation: Animation = .spring(response: 0.32, dampingFraction: 0.88)
    var controlAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.82)
    var backdropAnimation: Animation = .easeOut(duration: 0.2)
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
        // Only Delete is ruled off, and four rows is the own-message menu that has it.
        let dividers = rows > 3 ? 1 : 0
        let gaps = rows - 1 + dividers
        return CGSize(
            width: menuWidth,
            height: CGFloat(rows) * rowHeight + CGFloat(gaps) * rowSpacing
                + CGFloat(dividers) * (dividerHeight + dividerSpacing * 2) + menuEdgePadding * 2
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
