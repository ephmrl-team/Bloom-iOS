//
//  AuthWelcomeFooterView.swift
//  Bloom
//
//  Created by Аскольд on 14.08.2026.
//

import SwiftUI

struct AuthWelcomeFooterView: View {
    let appeared: Bool
    @Binding var path: NavigationPath
    @Environment(BloomManager.self) private var bloomManager
    @Environment(AppState.self) private var appState
    
    @State private var isLoading = false
    @State private var task: Task<Void, Never>?
    @State private var failure: Failure?
    @State private var isFailurePresented = false

    /// Kept until the next failure, so the alert keeps its own title while it dismisses.
    private enum Failure {
        case registration
        case login
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                #if DEBUG
                if AppMode.current == .mock {
                    if MockScenario.current == .error {
                        failure = .registration
                        isFailurePresented = true
                    } else {
                        task?.cancel()
                        task = Task {
                            // Mock starts without a session, so sign in before entering the app.
                            _ = await bloomManager.loginUser(recoveryKey: MockData.mnemonic)
                            appState.authenticate()
                        }
                    }
                    return
                }
                #endif

                task?.cancel()
                task = Task { await signIn() }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image("cloud")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }
                    Text("Continue with iCloud")
                }
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .accessibilityIdentifier("continueButton")
            .glassEffect(
                .regular
                    .interactive()
                    .tint(isLoading ? Color.gray.opacity(0.5) : Theme.colors.primary)
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .blur(radius: appeared ? 0 : 8)
            .animation(.smooth(duration: 0.75).delay(0.24), value: appeared)

            NavigationLink(value: AuthRoute.mnemonic) {
                Label {
                    Text("Continue with mnemonic")
                } icon: {
                    Image("key")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.foreground)
            }
            .accessibilityIdentifier("mnemonicLoginButton")
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .disabled(isLoading)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .blur(radius: appeared ? 0 : 8)
            .animation(.smooth(duration: 0.65).delay(0.32), value: appeared)
            .contentShape(Capsule())
        }
        .padding(.horizontal, 36)
        .padding(.top, 16)
        .padding(.bottom, 36)
        .onDisappear {
            task?.cancel()
        }
        .alert(
            failure == .login ? "Login Error" : "Registration Error",
            isPresented: $isFailurePresented
        ) {
            if failure == .login {
                // The saved key is unusable, so offer the route that still works.
                Button("Continue with mnemonic") {
                    path.append(AuthRoute.mnemonic)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            if failure == .login {
                Text("Could not sign in with the saved key. Use your phrase instead.")
            } else {
                Text("Failed to register. Please check your internet connection and try again.")
            }
        }
    }

    /// Signs in or registers, then reports the outcome unless the screen is gone.
    private func signIn() async {
        isLoading = true
        defer { isLoading = false }

        var user: User? = nil
        var route: AuthRoute = .success
        let isLogin = bloomManager.checkSession()

        if isLogin {
            user = await bloomManager.loginUser()
        } else {
            let registration = await bloomManager.registerUser()
            user = registration.user
            if let phrase = registration.mnemonic {
                route = .mnemonicReveal(phrase)
            }
        }

        guard !Task.isCancelled else { return }

        // A phrase means the account exists even if its record failed to decode.
        if user != nil || route != .success {
            path.append(route)
        } else {
            failure = isLogin ? .login : .registration
            isFailurePresented = true
        }
    }
}
