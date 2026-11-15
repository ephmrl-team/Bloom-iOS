//
//  SavedMessagesView.swift
//  Bloom
//

import SwiftUI

struct SavedMessagesView: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text("No saved messages")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            } icon: {
                Image("saved.flag")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
        } description: {
            Text("Messages you keep for later will show up here.")
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Saved")
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedMessagesView()
    }
}
