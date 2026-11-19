//
//  ChatLiftedContent.swift
//  Bloom
//

import SwiftUI

/// The live bubble re-rendered in the overlay at its exact window frame, with a configurable shadow.
struct ChatLiftedContent: View {
    let item: MessageItem
    let anchor: CGRect
    let center: CGPoint
    let scale: CGFloat
    let shadow: ChatMenuShadowStyle
    let shadowOpacity: Double

    var body: some View {
        ChatBubbleContent(item: item)
            .frame(width: anchor.width, height: anchor.height, alignment: .topLeading)
            .scaleEffect(scale)
            .shadow(
                color: shadow.isEnabled ? shadow.color.opacity(shadowOpacity) : .clear,
                radius: shadow.radius,
                x: shadow.offset.width,
                y: shadow.offset.height
            )
            .position(center)
    }
}
