//
//  SpoilerParticlesView.swift
//  Bloom
//

import SwiftUI

/// A shimmering cloud of dots that hides whatever sits underneath, like a spoiler.
/// `revealed` wipes the cloud away through a gradient mask; animate it from the caller.
struct SpoilerParticlesView: View {
    let tint: Color
    let revealed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        tint
            .mask { particles }
            .mask { revealMask }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var particles: some View {
        GeometryReader { proxy in
            TimelineView(.animation(paused: reduceMotion || revealed)) { context in
                Rectangle()
                    // A constant fill: the shader only contributes an alpha mask, and a dynamic
                    // color handed to a shader stops resolving in dark mode.
                    .fill(Color.white)
                    .colorEffect(
                        ShaderLibrary.spoilerParticles(
                            // Seconds since the view appeared: a 32-bit float keeps sub-pixel precision.
                            .float(Float(context.date.timeIntervalSince(startDate))),
                            // Lets the shader keep every dot inside the canvas.
                            .float2(proxy.size)
                        )
                    )
            }
        }
    }

    /// A soft edge that travels off the left side when hidden and shrinks away when revealed.
    /// The overshoot keeps the gradient's clear tail outside the frame while the cloud is shown.
    private var revealMask: some View {
        GeometryReader { proxy in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.3),
                    .init(color: .white, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * (revealed ? 0 : 1.5))
            .frame(width: proxy.size.width, alignment: .trailing)
        }
    }
}
