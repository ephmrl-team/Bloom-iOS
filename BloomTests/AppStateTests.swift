//
//  AppStateTests.swift
//  Bloom
//

import Testing
@testable import Bloom

@Suite("App state")
struct AppStateTests {
    @Test("Starts in authentication")
    func startsInAuth() {
        #expect(AppState().root == .auth)
    }

    @Test("Moves between auth and the main app")
    func switchesRoot() {
        let state = AppState()

        state.authenticate()
        #expect(state.root == .main)

        state.logout()
        #expect(state.root == .auth)
    }
}
