# Navigation and chrome

Read this before adding a screen, a route, a toolbar or a header/footer that floats over scrolling content.

## Routes

- Everything goes through `Router` (`Navigation/Router.swift`): `push(_:)`, `pop()`, `presentModal(_:)`,
  `dismissModal()`. It owns one `NavigationPath` and one `presentedSheet: ModalRoute?`.
- Add a screen by extending `Route` (push) or `ModalRoute` (sheet) in `Navigation/Route.swift`, then handle it
  in the single `switch` in `RootView`/`ContentView`. Never add a second navigation mechanism, never present a
  sheet directly from a child view, never keep a local `isPresented` flag for a screen-level sheet.
- Selecting a chat while a sheet is open uses `selectChat(id:)`: it stashes a `pendingRoute` and dismisses the
  sheet, then `pushPendingRouteIfNeeded()` runs after the dismissal. Do not `push` and `dismiss` in parallel —
  the push is dropped by the system.
- `Router` is `@Observable` and injected once; screens read it from the environment. Do not pass a `Binding`
  to a path.

## Tabs and stacks

- `MainTabView` uses the native `TabView`; every tab owns its own `NavigationStack` bound to the router's path.
  Keep the system tab bar — no custom bar, no custom transitions between tabs.
- Tab titles and icons come from the asset catalog and from `Localizable.xcstrings`; the tab bar is not styled
  per screen.

## Toolbars

- Keep the system toolbar (`.toolbar`, `.principal`, `.navigationTitle`) and its own configuration. Custom
  `.principal` titles have exactly one shape: 18 pt bold rounded text with a leading catalog icon at 23 pt and
  a 6 pt gap (`Theme.toolbarTitle`, reference `ChatListTitle`).
- Toolbar buttons carry an `accessibilityLabel`; icons are catalog images with `.renderingMode(.template)`.
- Do not add a background to the toolbar yourself. When content must scroll under it, use `topVariableBlur()`
  and, for glass content inside the bar, `.sharedBackgroundVisibility(.hidden)`.

## Floating chrome

- `topVariableBlur()` (`Features/ChatList/ChatListModifiers.swift`, BlurUIKit `VariableBlur`) is required on
  every screen whose header or footer floats over scrolling content: chat list, chat, new message, mnemonic
  screens, settings. Do not replace it with an opaque fill and do not add a native `scrollEdgeEffectStyle` on
  top of it.
- Bottom chrome (composer) belongs in `safeAreaInset(edge: .bottom)`; the scroll view keeps
  `.defaultScrollAnchor(.bottom)` and `.scrollDismissesKeyboard(.immediately)`.
