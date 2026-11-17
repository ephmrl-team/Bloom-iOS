//
//  BloomKitObservers.swift
//  Bloom
//

import BloomKit
import Foundation
import OSLog

final class ChatsObserver: NSObject, ClientChatsListenerProtocol {
    var onUpdate: (@MainActor (Data) -> Void)?

    func onChatsUpdated(_ chatsJSON: Data?) {
        guard let data = chatsJSON else { return }
        Task { @MainActor in
            self.onUpdate?(data)
        }
    }
}

final class UserObserver: NSObject, ClientUserListenerProtocol {
    var onUpdate: (@MainActor (User) -> Void)?

    func onUserUpdated(_ userJSON: Data?) {
        guard let data = userJSON else { return }
        do {
            let user = try JSONDecoder.bloomDecoder.decode(User.self, from: data)
            Task { @MainActor in
                self.onUpdate?(user)
            }
        } catch {
            Logger.bloom.error("user observer decode failed: \(error, privacy: .public)")
        }
    }
}
