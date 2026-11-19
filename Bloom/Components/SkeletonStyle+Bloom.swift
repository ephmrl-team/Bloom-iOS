//
//  SkeletonStyle+Bloom.swift
//  Bloom
//

import SkulletX
import UIKit

extension SkeletonStyle {
    /// Bloom's skeleton uses the incoming message bubble color.
    static func bloom(radius: CGFloat) -> SkeletonStyle {
        var style = SkeletonStyle()
        style.base = .secondarySystemBackground
        style.highlight = .dynamic(lightHex: "ffffffb3", darkHex: "ffffff1a")
        style.radius = radius
        return style
    }
}
