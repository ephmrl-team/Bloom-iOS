//
//  AuthWelcomeView.swift
//  Bloom
//
//  Created by Аскольд on 14.08.2026.
//

import SwiftUI

struct AuthWelcomeView: View {
    @Binding var path: NavigationPath

    @State private var appeared = false
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            WelcomePageView(
                title: "This is **Bloom**",
                subtitle: "End-to-end encrypted messenger with seamless experience"
            ) {
                Image("GiantLogo")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            }
            .tag(0)

            ForEach(Array(WelcomeFeature.all.enumerated()), id: \.offset) { index, feature in
                WelcomePageView(title: feature.title, subtitle: feature.subtitle) {
                    WelcomeFeatureTile(feature: feature)
                }
                .tag(index + 1)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .safeAreaInset(edge: .bottom) {
            AuthWelcomeFooterView(appeared: appeared, path: $path)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(.snappy(duration: 0.75)) {
                appeared = true
            }
        }
    }
}
