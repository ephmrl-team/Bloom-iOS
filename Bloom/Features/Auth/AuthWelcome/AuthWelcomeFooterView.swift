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
    
    @State private var isLoading = false
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                isLoading = true
                Task {
                    var user: User? = nil
                    var route: AuthRoute = .success

                    if bloomManager.checkSession() {
                        user = await bloomManager.loginUser()
                    } else {
                        let registration = await bloomManager.registerUser()
                        user = registration.user
                        if let phrase = registration.mnemonic {
                            route = .mnemonicReveal(phrase)
                        }
                    }

                    isLoading = false
                    if user != nil {
                        path.append(route)
                    } else {
                        showErrorAlert = true
                    }
                }
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
                            .frame(width: 20, height: 20)
                    }
                    Text("Continue")
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
                        .frame(width: 16, height: 16)
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
        .alert("Registration Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to register. Please check your internet connection and try again.")
        }
    }
}
