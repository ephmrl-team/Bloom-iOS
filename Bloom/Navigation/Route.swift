//
//  Route.swift
//  Bloom
//
//  Created by Аскольд on 10.08.2026.
//

import SwiftUI

enum Route: Hashable, Identifiable {
    case chatList
    case chat(id: Int)
    case profile(id: String)

    var id: Self {
        self
    }
}

enum ModalRoute: Hashable, Identifiable {
    case newMessage
    case mnemonicQuiz(String)

    var id: Self {
        self
    }
}

enum AuthRoute: Hashable {
    case mnemonic
    case mnemonicReveal(String)
    case success
}
