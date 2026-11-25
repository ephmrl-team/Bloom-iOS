//
//  SettingsLayout.swift
//  Bloom
//

import SwiftUI

/// Metrics used only by the Settings tab; everything shared lives in `Theme`.
enum SettingsLayout {
    static let sectionSpacing: CGFloat = 32

    static let rowVerticalInset: CGFloat = 12
    static let rowHorizontalInset: CGFloat = 16
    static let rowIconSpacing: CGFloat = 16
    static let rowFontSize: CGFloat = 17
    static let valueFontSize: CGFloat = 16
    static let chevronSize: CGFloat = 18
    static let separatorLeading: CGFloat = badgeSize + rowIconSpacing

    static let topContentMargin: CGFloat = 0

    static let badgeSize: CGFloat = 30
    static let badgeRadius: CGFloat = 10
    static let badgeIconSize: CGFloat = 24
    static let iconHighlightOpacity: Double = 0.55
    static let iconHighlightRadius: CGFloat = 0.5
    static let iconShadeOpacity: Double = 0.16
    static let iconShadeRadius: CGFloat = 1.5
    static let iconShadeOffset: CGFloat = -0.5

    static let profileAspectRatio: CGFloat = 16.0 / 9.0
    static let profileInset: CGFloat = 16
    static let profileAvatarSpacing: CGFloat = 16
    static let profileNameFontSize: CGFloat = 18
    static let profileUsernameFontSize: CGFloat = 15
    static let profileNameSpacing: CGFloat = 2
    static let profileChevronSize: CGFloat = 22
    /// The card chevron sits 4 pt further from the edge than the rest of the footer.
    static let profileTrailingInset: CGFloat = 20
    static let profileChevronOpacity: Double = 0.5
    static let profileInitialsFontSize: CGFloat = 96
    static let profileInitialsOpacity: Double = 0.9
    static let profileBlurRadius: CGFloat = 12
    /// The footer band: the avatar plus its 16 pt insets above and below; the blur covers exactly it.
    static let profileFooterHeight: CGFloat = AvatarSize.mdLarge.dimension + profileInset * 2
    static let profileBlurDimmingAlpha: Double = 0.5
    static let profileBorderWidth: CGFloat = 1
    static let profileBorderOpacity: Double = 0.1

    static let selectionMarkSize: CGFloat = 20
    static let selectionMarkInnerSize: CGFloat = 10
    static let selectionMarkLineWidth: CGFloat = 1.5

    static let appearanceSwatchSize: CGFloat = 30
    static let appearanceSwatchCellSize: CGFloat = 40
    static let appearanceSwatchSelectedScale: CGFloat = 1.2
    static let appearanceSwatchSpacing: CGFloat = 8
    static let appearanceAccentSpacing: CGFloat = 12
    static let appearanceSwatchShadowRadius: CGFloat = 16
    static let appearanceSwatchShadowOpacity: Double = 0.16
    static let appearanceSwatchShadowSpread: CGFloat = 4
    static let appearanceRowHeight: CGFloat = 52
    static let appearanceIconSize: CGFloat = 28
    static let appearanceSeparatorHeight: CGFloat = 1
    static let appearanceCardBorderWidth: CGFloat = 1

    static let mnemonicRowHeight: CGFloat = 48
    static let phraseWordFontSize: CGFloat = 20
    static let phraseFooterHeight: CGFloat = 54
    /// Captions under a settings block.
    static let captionFontSize: CGFloat = 15
    /// Side inset of the caption under the phrase block.
    static let captionInset: CGFloat = 14
    /// Gap between a block and the caption under it, and between a section label and its field.
    static let captionSpacing: CGFloat = 10
    /// Single full-width buttons such as the logout row and "Test yourself".
    static let actionButtonHeight: CGFloat = 52
    static let actionButtonFontSize: CGFloat = 18
    static let keyFontSize: CGFloat = 16
    static let keyRowHeight: CGFloat = 52
    static let keyRowInset: CGFloat = 18
    static let copyIconSize: CGFloat = 24
    static let fingerprintEmojiSpacing: CGFloat = 24
    static let fingerprintCaptionFontSize: CGFloat = 16
    static let aboutLogoSize: CGFloat = 64
    static let aboutTitleFontSize: CGFloat = 20
    static let storageBarHeight: CGFloat = 10
    static let storageLegendDotSize: CGFloat = 8
    static let storageTrackOpacity: Double = 0.15

    /// Clears the floating tab bar so the logout row can scroll fully above it.
    static let bottomContentMargin: CGFloat = 96
}
