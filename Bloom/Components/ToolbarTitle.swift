//
//  ToolbarTitle.swift
//  Bloom
//

import SwiftUI

/// The standard toolbar title: 17 pt semibold rounded. The chat list uses `ChatListTitle` instead.
struct ToolbarTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(
                .system(
                    size: Theme.toolbarTitle.fontSize,
                    weight: Theme.toolbarTitle.fontWeight,
                    design: .rounded
                )
            )
    }
}

extension View {
    func toolbarTitle(_ title: LocalizedStringKey) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ToolbarTitle(title: title)
                }
            }
    }
}
