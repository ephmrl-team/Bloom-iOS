//
//  ChatFooterWaveformView.swift
//  Bloom
//
//  Created by Аскольд on 16.08.2026.
//

import SwiftUI
import BlurSwiftUI
import BlurUIKit

struct ChatFooterWaveformView: View {
    var samples: [AudioSample]

    var waveColor: Color = Theme.colors.red
    var barWidth: CGFloat = 2
    var barSpacing: CGFloat = 2
    var minBarHeight: CGFloat = 6.0
    var maxBarHeight: CGFloat = 36.0

    var body: some View {
        Canvas { context, size in
            let maxBars = max(1, Int(size.width / (barWidth + barSpacing)))
            let visibleSamples = samples.suffix(maxBars)
            let placeholderCount = max(0, maxBars - visibleSamples.count)

            let placeholders = Array(repeating: minBarHeight, count: placeholderCount)
            let sampleHeights = visibleSamples.map { max(minBarHeight, $0.value * maxBarHeight) }

            var glow = context
            glow.addFilter(.blur(radius: 8))
            glow.opacity = 0.45
            drawBars(placeholders + sampleHeights, in: &glow, height: size.height, color: Color(red: 1.0, green: 0.0, blue: 0.0))

            var sharp = context
            var placeholdersOnly = sharp
            placeholdersOnly.opacity = 0.5
            drawBars(placeholders, in: &placeholdersOnly, height: size.height, color: waveColor)
            drawBars(sampleHeights, in: &sharp, height: size.height, color: waveColor, offset: placeholderCount)
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.235),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(alignment: .leading) {
            VariableBlur(direction: .left)
                .maximumBlurRadius(1)
                .passesTouchesThrough(true)
                .dimmingTintColor(.clear)
                .frame(width: 54)
                .frame(maxHeight: .infinity)
        }
    }

    private func drawBars(
        _ heights: [CGFloat],
        in context: inout GraphicsContext,
        height: CGFloat,
        color: Color,
        offset: Int = 0
    ) {
        for (index, barHeight) in heights.enumerated() {
            let rect = CGRect(
                x: CGFloat(index + offset) * (barWidth + barSpacing),
                y: (height - barHeight) / 2,
                width: barWidth,
                height: barHeight
            )
            context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(color))
        }
    }
}
