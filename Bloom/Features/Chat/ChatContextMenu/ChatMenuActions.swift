//
//  ChatMenuActions.swift
//  Bloom
//

import Foundation

/// What the menu can do with the lifted message. The row owns the callbacks.
struct ChatMenuActions {
    var copy: () -> Void = {}
    var reply: () -> Void = {}
    var forward: () -> Void = {}
    var delete: (() -> Void)?
}

enum ChatMenuAction {
    case copy
    case reply
    case forward
    case delete
}
