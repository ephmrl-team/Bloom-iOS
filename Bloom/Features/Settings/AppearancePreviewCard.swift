//
//  AppearancePreviewCard.swift
//  Bloom
//

import SwiftUI

/// The chat preview and accent picker at the top of the Appearance screen.
struct AppearancePreviewCard: View {
    @AppStorage(ClearGlassSetting.storageKey) private var clearGlass = false
    @AppStorage(AppAccent.storageKey) private var accentRaw = AppAccent.blue.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweepFrom = AppAccent.blue
    @State private var sweepTo = AppAccent.blue
    @State private var sweep: CGFloat = 1
    @State private var sweeping = false

    private let mine = MessageItem(
        id: 0,
        content: String(localized: "Bloom looks super!"),
        date: "9:41",
        me: true
    )
    private let theirs = MessageItem(
        id: 1,
        content: String(localized: "Facts 😎"),
        date: "00:07",
        me: false
    )

    var body: some View {
        VStack(spacing: 0) {
            preview
            AppearanceAccentPicker()
        }
        .background(Theme.colors.background)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.colors.foreground, lineWidth: SettingsLayout.appearanceCardBorderWidth))
        .onChange(of: accentRaw) { oldRaw, newRaw in
            startSweep(from: oldRaw, to: newRaw)
        }
    }

    private var currentAccent: AppAccent {
        AppAccent(rawValue: accentRaw) ?? .blue
    }

    private var preview: some View {
        ZStack {
            Theme.colors.background

            // The icon pattern cross-fades with the same clock as the bubble sweep.
            PhraseBackdropView(
                icon: "chat.bubbles",
                tint: (sweeping ? sweepFrom : currentAccent).color,
                opacity: 0.25
            )
            .opacity(1 - sweep)

            PhraseBackdropView(
                icon: "chat.bubbles",
                tint: (sweeping ? sweepTo : currentAccent).color,
                opacity: 0.25
            )
            .opacity(sweep)

            VStack(spacing: Theme.spacing.xxl) {
                HStack {
                    Spacer(minLength: 0)
                    mineBubble
                }

                HStack(alignment: .bottom, spacing: Theme.spacing.sm) {
                    AvatarView(size: .xsLarge, id: "appearance-preview", name: "Bloom")
                    theirBubble
                    Spacer(minLength: 0)
                }
            }
            .padding(Theme.spacing.xxl)
        }
    }

    /// The bubble is drawn twice while the sweep runs: the old accent underneath and the new one
    /// revealed left to right by a soft gradient mask.
    @ViewBuilder
    private var mineBubble: some View {
        if sweeping {
            ZStack {
                ChatBubbleContent(item: mine, accentOverride: sweepFrom)
                ChatBubbleContent(item: mine, accentOverride: sweepTo)
                    .mask { sweepMask }
            }
        } else {
            ChatBubbleContent(item: mine)
        }
    }

    private var sweepMask: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let softness: CGFloat = 44
            let total = width + 2 * softness

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: (width + softness) / total),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: total)
                .offset(x: sweep * total - total)
        }
    }

    private func startSweep(from oldRaw: String, to newRaw: String) {
        let oldAccent = AppAccent(rawValue: oldRaw) ?? .blue
        let newAccent = AppAccent(rawValue: newRaw) ?? .blue
        guard !reduceMotion else {
            sweeping = false
            return
        }

        sweepFrom = oldAccent
        sweepTo = newAccent
        withAnimation(nil) {
            sweep = 0
        }
        sweeping = true
        Task { @MainActor in
            withAnimation(.smooth(duration: 0.5)) {
                sweep = 1
            }
        }
    }

    private var theirBubble: some View {
        Text("\(theirs.content)\(invisibleSpaceForTime)")
            .font(.system(.headline, design: .rounded, weight: .regular))
            .foregroundColor(Theme.colors.text)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .frame(minWidth: 60, minHeight: 40, alignment: .leading)
            .glassEffect(
                clearGlass ? Glass.clear : Glass.regular,
                in: RoundedRectangle(cornerRadius: 22)
            )
            .overlay(alignment: .bottomTrailing) {
                Text(theirs.date)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundColor(Theme.colors.text.opacity(0.5))
                    .padding(.trailing, 13)
                    .padding(.bottom, 9)
            }
    }

    private var invisibleSpaceForTime: Text {
        Text("\u{00A0}\u{00A0}" + theirs.date)
            .font(.system(.footnote, design: .rounded, weight: .regular))
            .foregroundColor(.clear)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.radius.xl, style: .continuous)
    }
}

#if DEBUG
    #Preview {
        AppearancePreviewCard()
            .padding()
            .background(Theme.colors.background)
    }
#endif
