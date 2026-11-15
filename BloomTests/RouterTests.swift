//
//  RouterTests.swift
//  Bloom
//

import Foundation
import Testing
@testable import Bloom

@Suite("Router")
struct RouterTests {
    @Test("Push appends a route to the path")
    func pushAppendsRoute() {
        let router = Router()
        router.push(.chatList)
        #expect(router.path.count == 1)
    }

    @Test("Pop removes the last route")
    func popRemovesLastRoute() {
        let router = Router()
        router.push(.chatList)
        router.push(.chat(id: 7))
        router.pop()
        #expect(router.path.count == 1)
    }

    @Test("Pop on an empty path does nothing")
    func popOnEmptyPathIsSafe() {
        let router = Router()
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test("Modal presentation can be dismissed")
    func modalPresentation() {
        let router = Router()
        router.presentModal(.newMessage)
        #expect(router.presentedSheet == .newMessage)
        router.dismissModal()
        #expect(router.presentedSheet == nil)
    }

    @Test("Selecting a chat closes the sheet and pushes after dismissal")
    func selectChatDefersNavigation() {
        let router = Router()
        router.presentModal(.newMessage)

        router.selectChat(id: 42)
        #expect(router.presentedSheet == nil)
        #expect(router.path.isEmpty, "The chat must wait for the sheet to finish dismissing")

        router.pushPendingRouteIfNeeded()
        #expect(router.path.count == 1)
    }

    @Test("A pending route is consumed once")
    func pendingRouteIsConsumedOnce() {
        let router = Router()
        router.selectChat(id: 42)

        router.pushPendingRouteIfNeeded()
        router.pushPendingRouteIfNeeded()

        #expect(router.path.count == 1)
    }
}
