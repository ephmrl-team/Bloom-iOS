//
//  ChatSearchField.swift
//  Bloom
//

import SwiftUI
import UIKit

struct ChatSearchField: UIViewControllerRepresentable {
    @Binding var text: String

    func makeUIViewController(context: Context) -> Controller {
        Controller(text: $text)
    }

    /// Runs on every keystroke: only keep the binding fresh, never touch the search controller here.
    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.text = $text
    }

    final class Controller: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate {
        var text: Binding<String>
        private let search = UISearchController(searchResultsController: nil)
        private weak var installedItem: UINavigationItem?
        private var isInstalled = false

        init(text: Binding<String>) {
            self.text = text
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            return nil
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            search.searchResultsUpdater = self
            search.delegate = self
            search.obscuresBackgroundDuringPresentation = false
            search.hidesNavigationBarDuringPresentation = false
            search.searchBar.autocorrectionType = .no
            search.searchBar.autocapitalizationType = .none
            search.searchBar.searchTextField.accessibilityIdentifier = "searchField"
            search.searchBar.setImage(
                UIImage(named: "magnifyingglass")?.withRenderingMode(.alwaysTemplate),
                for: .search,
                state: .normal
            )
            styleSearchField()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            installSearchController()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installSearchController()
        }

        /// Installs once. Re-assigning `navigationItem.searchController` while the search is active dismisses it.
        func installSearchController() {
            guard !isInstalled, isViewLoaded else { return }
            var ancestor = parent
            while let controller = ancestor {
                if let navigation = controller.navigationController,
                   navigation.viewControllers.contains(where: { $0 === controller })
                {
                    let item = controller.navigationItem
                    controller.definesPresentationContext = true
                    item.preferredSearchBarPlacement = .integratedButton
                    item.searchBarPlacementAllowsToolbarIntegration = false
                    item.hidesSearchBarWhenScrolling = false
                    item.searchController = search
                    item.searchBarPlacementBarButtonItem.image =
                        UIImage(named: "magnifyingglass")?.withRenderingMode(.alwaysTemplate)
                    item.searchBarPlacementBarButtonItem.accessibilityIdentifier = "searchButton"
                    installedItem = item
                    isInstalled = true
                    return
                }
                ancestor = controller.parent
            }
        }

        func updateSearchResults(for searchController: UISearchController) {
            let value = searchController.searchBar.text ?? ""
            if text.wrappedValue != value {
                text.wrappedValue = value
            }
        }

        func willPresentSearchController(_ searchController: UISearchController) {
            styleSearchField()
        }

        func didDismissSearchController(_ searchController: UISearchController) {
            if !(searchController.searchBar.text ?? "").isEmpty {
                searchController.searchBar.text = ""
            }
            if !text.wrappedValue.isEmpty {
                text.wrappedValue = ""
            }
        }

        func removeSearchController() {
            if installedItem?.searchController === search {
                installedItem?.searchController = nil
            }
            search.delegate = nil
            search.searchResultsUpdater = nil
        }

        private func styleSearchField() {
            let font = UIFont.preferredFont(forTextStyle: .body)
            let roundedFont = font.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: 0) } ?? font
            let field = search.searchBar.searchTextField
            field.font = roundedFont
            field.adjustsFontForContentSizeCategory = true
            field.attributedPlaceholder = NSAttributedString(
                string: String(localized: "Search across app"),
                attributes: [.font: roundedFont, .foregroundColor: UIColor.secondaryLabel]
            )
        }
    }

    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) {
        controller.removeSearchController()
    }
}
