//
//  ChatContextMenuRootView.swift
//  Bloom
//

import SwiftUI

/// Root of the transparent overlay window. It never touches the chat's layout.
struct ChatContextMenuRootView: View {
    let ref: ChatContextMenuModelRef

    var body: some View {
        if let model = ref.model {
            ChatContextMenuOverlay(model: model)
        }
    }
}
