//
//  ChatListTitleStateTests.swift
//  Bloom
//

import Testing
@testable import Bloom

@Suite("Chat list title")
struct ChatListTitleStateTests {
    @Test("Says Chats once the list is loaded")
    func showsOnline() {
        #expect(ChatListTitleState(isOnline: true, hasLoadedChats: true, hasError: false) == .online)
    }

    @Test("Says Connecting until the list arrives")
    func showsConnecting() {
        #expect(ChatListTitleState(isOnline: true, hasLoadedChats: false, hasError: false) == .connecting)
    }

    @Test("Says No internet without a network path")
    func showsOffline() {
        #expect(ChatListTitleState(isOnline: false, hasLoadedChats: true, hasError: false) == .offline)
    }

    @Test("Says Connection error when the list failed")
    func showsError() {
        #expect(ChatListTitleState(isOnline: true, hasLoadedChats: true, hasError: true) == .error)
    }

    @Test("Prefers offline, then error, over connecting")
    func ranksStates() {
        #expect(ChatListTitleState(isOnline: false, hasLoadedChats: false, hasError: true) == .offline)
        #expect(ChatListTitleState(isOnline: true, hasLoadedChats: false, hasError: true) == .error)
    }
}
