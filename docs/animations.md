# Animations and Liquid Glass

Read this before touching motion, transitions, the composer or anything that reacts to the keyboard.

## Motion rules

- Animate compositor-only properties: `opacity`, `offset`, `scale`, `blur`, `rotation`. Never animate a
  layout size (`frame`, `padding`, text width) — it forces a layout pass every frame and shows as text
  jumping or re-wrapping.
- Use one explicit animation per state change (`withAnimation(.smooth(duration: 0.235))`), not several
  competing implicit ones on the same view.
- Respect Reduce Motion: read `@Environment(\.accessibilityReduceMotion)` and drop travel/blur, keep opacity.
  `ChatMessageAppearance` and `WelcomePageView` are the reference implementations.
- Keep the animated value small and local: put a per-frame value (keyboard progress, audio level) in a tiny
  `@Observable` model that only the animating view reads, so the rest of the screen is not invalidated.
- Do not start an animation inside `body`. Compute the target in the model, animate from the event handler.

## Liquid Glass

- Group glass elements in one `GlassEffectContainer(spacing:)` (`ChatFooterView`), and give each element an
  identity with `.glassEffectID("messageInput", in: namespace)` so morphing between states is a container
  transition rather than a cross-fade.
- Toolbar content that floats over content uses `.sharedBackgroundVisibility(.hidden)` (`ChatViewToolbar`)
  instead of stacking a second glass surface on top of the system one.
- Prefer the system glass button styles over a hand-rolled blur capsule. A custom blur is only acceptable
  with a measurement that shows the system control cannot meet the frame budget.

## Keyboard tracking

- `KeyboardTracker` (Features/Chat/ChatFooter) owns keyboard geometry. It publishes a single `progress` in
  `0...1` from `keyboardWillChangeFrameNotification`, and views map it with the static helpers
  `padding(for:)`, `bottomInset(for:)`, `dockedHeight(for:in:)` and `progress(safeArea:restingInset:keyboardHeight:)`.
- Never read `UIResponder.keyboardFrameEndUserInfoKey` in a view and never animate the keyboard yourself: the
  tracker already handles the safe area, the docking check and interruptions.
- While the keyboard moves, the composer changes only its paddings and the glass position. Text must keep its
  width — animating `textWidth`/`lineLimit`/`fixedSize` during the transition makes the message jump.
- `ChatComposerInset` exists so the per-frame keyboard value invalidates the inset only, not `ChatView`.
