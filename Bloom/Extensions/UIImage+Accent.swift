//
//  UIImage+Accent.swift
//  Bloom
//

import SwiftUI
import UIKit

extension UIImage {
    /// The most saturated, brightest pixel of a 16 × 16 downsample, used as the photo's accent color.
    func accentColor() -> Color? {
        guard let pixels = samplePixels() else { return nil }

        var bestScore = 0.0
        var best: Color?
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let red = Double(pixels[index]) / 255
            let green = Double(pixels[index + 1]) / 255
            let blue = Double(pixels[index + 2]) / 255
            let brightness = max(red, green, blue)
            let score = (brightness - min(red, green, blue)) * brightness
            if score > bestScore {
                bestScore = score
                best = Color(red: red, green: green, blue: blue)
            }
        }
        return best
    }

    private func samplePixels(side: Int = 16) -> [UInt8]? {
        guard let cgImage, let context = CGContext(
            data: nil,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return nil }

        let buffer = UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: side * side * 4)
        return Array(buffer)
    }
}
