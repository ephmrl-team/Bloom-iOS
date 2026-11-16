//
//  ChatSearchField.swift
//  Bloom
//

import SwiftUI

/// A round search button that morphs into a full-width field.
///
/// The capsule is one persistent view whose width animates, so the button and
/// the field are the same shape growing and shrinking, not two swapped views.
struct ChatSearchField: View {
    @Binding var text: String
    @Binding var isSearching: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.spacing.sm) {
            if isSearching {
                icon("magnifyingglass", size: 18)

                TextField("Search", text: $text)
                    .font(.system(.body, design: .rounded))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("searchField")
                    .onAppear { isFocused = true }

                Button(action: close) {
                    icon("x.mark", size: 14)
                        .frame(width: 24, height: 24)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close search")
                .accessibilityIdentifier("searchCloseButton")
            } else {
                collapsedButton
            }
        }
        .padding(.horizontal, isSearching ? Theme.spacing.md : 0)
        .frame(maxWidth: isSearching ? .infinity : 44, alignment: .center)
        .frame(height: 44)
        .background(Capsule().fill(Theme.colors.foreground))
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: isSearching)
    }

    private var collapsedButton: some View {
        Button {
            isSearching = true
        } label: {
            icon("magnifyingglass", size: 18)
                .frame(width: 44, height: 44)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search")
        .accessibilityIdentifier("searchButton")
    }

    private func icon(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(Theme.colors.secondaryText)
    }

    private func close() {
        isFocused = false
        text = ""
        isSearching = false
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var isSearching = false

    VStack(spacing: Theme.spacing.lg) {
        ChatSearchField(text: $text, isSearching: $isSearching)

        Button(isSearching ? "Collapse" : "Expand") {
            isSearching.toggle()
        }
    }
    .padding()
}
