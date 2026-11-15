//
//  ChatSearchField.swift
//  Bloom
//

import SwiftUI
import UIKit

/// A search field that lives in the navigation bar.
///
/// `@FocusState` is dropped for toolbar items, so the field is the system's own
/// `UISearchTextField` and takes focus itself once it is in the hierarchy.
struct ChatSearchField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UISearchTextField {
        let field = UISearchTextField()
        field.delegate = context.coordinator
        field.placeholder = String(localized: "Search")
        field.returnKeyType = .search
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.accessibilityIdentifier = "searchField"
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged),
            for: .editingChanged
        )
        return field
    }

    func updateUIView(_ field: UISearchTextField, context: Context) {
        if field.text != text {
            field.text = text
        }

        if !context.coordinator.hasTakenFocus {
            context.coordinator.hasTakenFocus = true
            field.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private let text: Binding<String>
        var hasTakenFocus = false

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func textChanged(_ field: UITextField) {
            text.wrappedValue = field.text ?? ""
        }

        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            field.resignFirstResponder()
            return true
        }
    }
}
