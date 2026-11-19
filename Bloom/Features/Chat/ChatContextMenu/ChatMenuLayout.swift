//
//  ChatMenuLayout.swift
//  Bloom
//

import UIKit

/// Everything the overlay needs to place the lifted bubble, the reactions and the action block.
struct ChatMenuLayoutRequest {
    let anchor: CGRect
    let bounds: CGRect
    let safeArea: UIEdgeInsets
    let configuration: ChatMenuConfiguration
    let isMine: Bool
    let actionRows: Int
    let scale: CGFloat
}

@MainActor
extension ChatMenuLayoutRequest {
    init(item: MessageItem, model: ChatContextMenuModel, scale: CGFloat) {
        self.init(
            anchor: model.anchor,
            bounds: model.bounds,
            safeArea: model.safeArea,
            configuration: model.configuration,
            isMine: item.me,
            actionRows: item.me ? 4 : 3,
            scale: scale
        )
    }
}

struct ChatMenuLayout: Equatable {
    let content: CGRect
    let reactions: CGRect
    let actions: CGRect
}

enum ChatMenuLayoutEngine {
    static func make(_ request: ChatMenuLayoutRequest) -> ChatMenuLayout {
        let limits = Limits(request)
        let reactionsSize = request.configuration.reactionBarSize(count: request.configuration.reactions.count)
        let actionsSize = request.configuration.actionsSize(rows: request.actionRows)
        let content = contentRect(request, reactions: reactionsSize, actions: actionsSize, limits: limits)
        let reactions = rect(
            content: content,
            size: reactionsSize,
            originY: content.minY - limits.gap - reactionsSize.height,
            limits: limits
        )
        let actions = rect(
            content: content,
            size: actionsSize,
            originY: content.maxY + limits.gap,
            limits: limits
        )
        return ChatMenuLayout(content: content, reactions: reactions, actions: actions)
    }

    /// Reactions always sit above and actions always below, so the content itself travels: up when
    /// the actions would fall under the keyboard or the bottom edge, down when the reactions would
    /// leave the top.
    private static func contentRect(
        _ request: ChatMenuLayoutRequest,
        reactions: CGSize,
        actions: CGSize,
        limits: Limits
    ) -> CGRect {
        var content = request.anchor.scaled(by: request.scale)
        if content.width <= limits.maxX - limits.minX {
            content.origin.x = min(max(content.origin.x, limits.minX), limits.maxX - content.width)
        }

        let overflowBelow = content.maxY + limits.gap + actions.height - limits.bottom
        if overflowBelow > 0 {
            let roomAbove = content.minY - limits.gap - reactions.height - limits.top
            content.origin.y -= min(overflowBelow, max(0, roomAbove))
        }

        let overflowAbove = limits.top - (content.minY - limits.gap - reactions.height)
        if overflowAbove > 0 {
            let roomBelow = limits.bottom - (content.maxY + limits.gap + actions.height)
            content.origin.y += min(overflowAbove, max(0, roomBelow))
        }

        return content
    }

    private static func rect(content: CGRect, size: CGSize, originY: CGFloat, limits: Limits) -> CGRect {
        let xOrigin = originX(content: content, width: size.width, limits: limits)
        return CGRect(
            origin: CGPoint(x: xOrigin, y: min(max(originY, limits.top), limits.bottom - size.height)),
            size: size
        )
    }

    private static func originX(content: CGRect, width: CGFloat, limits: Limits) -> CGFloat {
        let proposed = limits.isMine ? content.maxX - width : content.minX
        return min(max(proposed, limits.minX), limits.maxX - width)
    }

    private struct Limits {
        let top: CGFloat
        let bottom: CGFloat
        let gap: CGFloat
        let minX: CGFloat
        let maxX: CGFloat
        let isMine: Bool

        init(_ request: ChatMenuLayoutRequest) {
            let configuration = request.configuration
            top = request.safeArea.top + configuration.edgeInset
            // The keyboard is already on its way out when the menu opens, so the screen is free.
            bottom = request.bounds.maxY - request.safeArea.bottom - configuration.edgeInset
            gap = configuration.gap
            minX = request.bounds.minX + configuration.edgeInset
            maxX = request.bounds.maxX - configuration.edgeInset
            isMine = request.isMine
        }
    }
}

private extension CGRect {
    func scaled(by scale: CGFloat) -> CGRect {
        let width = self.width * scale
        let height = self.height * scale
        return CGRect(x: midX - width / 2, y: midY - height / 2, width: width, height: height)
    }
}
