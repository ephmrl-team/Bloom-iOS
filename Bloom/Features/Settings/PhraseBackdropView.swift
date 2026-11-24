//
//  PhraseBackdropView.swift
//  Bloom
//

import SwiftUI

/// The phrase grid backdrop: the `key` icon tiled in a checkerboard at 5% text color.
struct PhraseBackdropView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var drift: CGSize = .zero

    private let pitch: CGFloat = 72
    private let rowStep: CGFloat = 42
    private let iconWidth: CGFloat = 38

    var body: some View {
        // The tint is a normal view color: a Canvas resolves dynamic colors against the wrong traits.
        Theme.colors.text
            .opacity(0.05)
            .mask { backdrop }
            .onAppear { driftIn() }
    }

    /// Two tiles of overscan on every side, so the drift never exposes a cut edge.
    private var backdrop: some View {
        GeometryReader { proxy in
            tiles
                .frame(width: proxy.size.width + pitch * 2, height: proxy.size.height + rowStep * 2)
                .offset(x: -pitch + drift.width, y: -rowStep + drift.height)
        }
    }

    /// One diagonal slide to the left that eases out over four seconds.
    private func driftIn() {
        guard !reduceMotion else {
            return
        }
        withAnimation(.smooth(duration: 4)) {
            drift = CGSize(width: -pitch / 2, height: -rowStep / 2)
        }
    }

    private var tiles: some View {
        Canvas { context, size in
            let key = context.resolve(Image("key"))

            let iconSize = CGSize(
                width: iconWidth,
                height: iconWidth * key.size.height / max(key.size.width, 1)
            )
            let rows = Int((size.height / rowStep).rounded(.up)) + 2
            let columns = Int((size.width / pitch).rounded(.up)) + 2

            for row in 0 ..< rows {
                let shift = row.isMultiple(of: 2) ? 0 : pitch / 2
                for column in 0 ..< columns {
                    let origin = CGPoint(
                        x: CGFloat(column) * pitch + shift - pitch / 2,
                        y: CGFloat(row - 1) * rowStep
                    )
                    context.draw(key, in: CGRect(origin: origin, size: iconSize))
                }
            }
        }
    }
}
