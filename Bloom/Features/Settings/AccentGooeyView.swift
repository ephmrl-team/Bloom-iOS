//
//  AccentGooeyView.swift
//  Bloom
//

import SwiftUI

struct AccentTransition: Identifiable, Equatable {
    let id: UUID
    let from: AppAccent
    let target: AppAccent

    func hides(_ accent: AppAccent) -> Bool {
        from == accent || target == accent
    }
}

/// One metaball bridge. The phase is evaluated from the timeline clock instead of SwiftUI's
/// animation system, so the shader gets a new uniform every frame and the bridge cannot jump to
/// its end value after a frame or two.
struct AccentGooeyView: View {
    let transition: AccentTransition
    let width: CGFloat

    @State private var start = Date()
    @State private var finished = false

    var body: some View {
        let from = center(for: transition.from)
        let target = center(for: transition.target)
        let fromColor = transition.from.color
        let toColor = transition.target.color
        let radius = Float(SettingsLayout.appearanceSwatchSize / 2)
        let selectedRadius = Float(
            SettingsLayout.appearanceSwatchSize * SettingsLayout.appearanceSwatchSelectedScale / 2
        )

        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: finished)) { context in
            let elapsed = max(context.date.timeIntervalSince(start), 0)

            Rectangle()
                .fill(.white)
                .frame(width: width, height: SettingsLayout.appearanceSwatchCellSize)
                .colorEffect(
                    ShaderLibrary.accentGooey(
                        .float2(Float(from.x), Float(from.y)),
                        .float2(Float(target.x), Float(target.y)),
                        .float(springProgress(at: elapsed)),
                        .float(neckProgress(at: elapsed)),
                        .float(radius),
                        .float(selectedRadius),
                        .color(fromColor),
                        .color(toColor)
                    )
                )
        }
        .task {
            try? await Task.sleep(for: .milliseconds(900))
            finished = true
        }
    }

    /// Underdamped spring, response 0.5 s, about 25 % overshoot, then settles.
    private func springProgress(at elapsed: TimeInterval) -> Double {
        let response = 0.5
        let damping = 0.4
        let omega = 2 * Double.pi / response
        let omegaD = omega * (1 - damping * damping).squareRoot()
        let wave = cos(omegaD * elapsed) + damping * omega / omegaD * sin(omegaD * elapsed)
        let value = 1 - exp(-damping * omega * elapsed) * wave
        return min(max(value, 0), 1.2)
    }

    /// The bridge lives on its own clock: a 0.7 s bump, so the liquid is clearly visible while the
    /// discs spring into place instead of flashing for a couple of frames.
    private func neckProgress(at elapsed: TimeInterval) -> Double {
        let duration = 0.7
        let phase = min(elapsed / duration, 1)
        return sin(Double.pi * phase)
    }

    private func center(for accent: AppAccent) -> CGPoint {
        let index = AppAccent.allCases.firstIndex(of: accent) ?? 0
        let step = SettingsLayout.appearanceSwatchCellSize + SettingsLayout.appearanceSwatchSpacing
        return CGPoint(
            x: Theme.spacing.lg + SettingsLayout.appearanceSwatchCellSize / 2 + CGFloat(index) * step,
            y: SettingsLayout.appearanceSwatchCellSize / 2
        )
    }
}
