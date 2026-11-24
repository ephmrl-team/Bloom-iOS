//
//  SettingsStorageView.swift
//  Bloom
//

import SwiftUI

struct SettingsStorageView: View {
    @State private var usage: StorageUsage?
    @State private var isClearDialogPresented = false
    @State private var isClearing = false

    var body: some View {
        List {
            Section {
                StorageBar(
                    documents: usage?.documents ?? 0,
                    temporary: usage?.temporary ?? 0
                )
            }

            Section {
                storageRow(title: "Documents", value: usage?.formattedDocuments ?? StorageUsage.format(0))
                storageRow(title: "Temporary files", value: usage?.formattedTemporary ?? StorageUsage.format(0))
                storageRow(title: "Total", value: usage?.formattedTotal ?? StorageUsage.format(0))
            }

            Section {
                Button(role: .destructive) {
                    isClearDialogPresented = true
                } label: {
                    Text("Clear temporary files")
                        .font(.system(size: SettingsLayout.rowFontSize, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.colors.red)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled((usage?.temporary ?? 0) == 0 || isClearing)
                .settingsRowStyle()
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(SettingsLayout.sectionSpacing)
        .scrollContentBackground(.hidden)
        .background(Theme.colors.background)
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.bottom, SettingsLayout.bottomContentMargin, for: .scrollContent)
        .toolbarTitle("Storage")
        .topVariableBlur()
        .task { await reload() }
        .confirmationDialog(
            "Clear temporary files?",
            isPresented: $isClearDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                Task { await clear() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Temporary files can be recreated by the app.")
        }
    }

    private func storageRow(title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: Theme.spacing.md) {
            Text(title)
                .font(.system(size: SettingsLayout.rowFontSize, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.colors.text)

            Spacer(minLength: Theme.spacing.sm)

            Text(value)
                .font(.system(size: SettingsLayout.valueFontSize, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.colors.secondaryText)
        }
        .settingsRowStyle()
    }

    private func reload() async {
        usage = await StorageUsageReader.read()
    }

    private func clear() async {
        isClearing = true
        await StorageUsageReader.clearTemporary()
        usage = await StorageUsageReader.read()
        isClearing = false
    }
}
