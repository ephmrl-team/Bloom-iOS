//
//  AvatarGradient.swift
//  Bloom
//
//  Created by Аскольд on 11.08.2026.
//

import SwiftUI

func avatarGradient(for id: String) -> [Color] {
    var hash: UInt = 5381

    for byte in id.utf8 {
        hash = 33 &* hash &+ UInt(byte)
    }

    let index = Int(hash % UInt(AvatarConstants.avatarColors.count))

    return AvatarConstants.avatarColors[index]
}
