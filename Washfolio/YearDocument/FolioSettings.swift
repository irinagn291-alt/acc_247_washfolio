import SwiftUI

/// Role: Year document. Settings sheet. Observes AlmanacFolio. Contact, bleed, palette, reset.
struct FolioSettings: View {
    @ObservedObject var folio: AlmanacFolio
    var onRerunOnboarding: () -> Void
    var onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var resetBusy = false
    @State private var persistFailed = false

    init(
        folio: AlmanacFolio,
        onRerunOnboarding: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.folio = folio
        self.onRerunOnboarding = onRerunOnboarding
        self.onDismiss = onDismiss
    }

    init() {
        self.init(folio: FolioPreview.populated())
    }

    var body: some View {
        settingsBody
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(FolioChrome.Palette.background.ignoresSafeArea())
        .confirmationDialog("Erase every stroke?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                Task { await resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var settingsBody: some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
            FolioSheetChrome(title: "Folio", closeLabel: "Close settings") {
                onDismiss()
                dismiss()
            }
            if persistFailed {
                errorState
            } else {
                if folio.strokes.isEmpty {
                    emptyState
                }
                populatedState
            }
        }
        .padding(FolioChrome.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        FolioEmptyState(
            image: "wfo_EmptyList",
            headline: "The year is empty.",
            line: "The first stroke is yours.",
            actionTitle: "Back to the year"
        ) {
            onDismiss()
            dismiss()
        }
    }

    private var populatedState: some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
            Text("Bleed")
                .folioText(.title)
            Text(FolioFigures.bleed(folio.bleedAmount))
                .folioText(.figure)
                .layoutPriority(1)
            FolioBleedSlider(
                value: Binding(
                    get: { folio.bleedAmount },
                    set: { try? folio.setBleedAmount($0) }
                )
            )

            Text("Twelve tones")
                .folioText(.title)
            ForEach(Array(stride(from: 0, to: folio.palette.count, by: 2)), id: \.self) { index in
                HStack(spacing: FolioChrome.space(2)) {
                    toneRow(folio.palette[index])
                    if folio.palette.indices.contains(index + 1) {
                        toneRow(folio.palette[index + 1])
                    }
                }
            }
            Button {
                try? folio.rewritePalette(ToneWell.defaultPalette)
            } label: {
                Text("Restore twelve tones")
                    .folioText(.body)
                    .foregroundStyle(FolioChrome.Palette.accent)
                    .padding(.horizontal, FolioChrome.space(1))
                    .folioRowHit()
                    .background(FolioChrome.Palette.surface)
            }
            .buttonStyle(.plain)

            Link(destination: FolioChrome.contact) {
                Text("Contact Washfolio")
                    .folioText(.body)
                    .foregroundStyle(FolioChrome.Palette.accent)
                    .padding(.horizontal, FolioChrome.space(1))
                    .folioRowHit()
                    .background(FolioChrome.Palette.surface)
            }
            .buttonStyle(.plain)

            Button {
                onRerunOnboarding()
            } label: {
                Text("Re-run onboarding")
                    .folioText(.body)
                    .padding(.horizontal, FolioChrome.space(1))
                    .folioRowHit()
                    .background(FolioChrome.Palette.surface)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .folioText(.body)
                    .padding(.horizontal, FolioChrome.space(1))
                    .folioRowHit()
                    .background(FolioChrome.Palette.surface)
            }
            .buttonStyle(.plain)
            .disabled(resetBusy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toneRow(_ swatch: FolioSwatch) -> some View {
        HStack(spacing: FolioChrome.space(1)) {
            Circle()
                .fill(swatch.ink.color)
                .frame(width: 20, height: 20)
                .overlay { Circle().stroke(FolioChrome.Palette.ink.opacity(0.3), lineWidth: 1) }
            Text(swatch.spokenName)
                .folioText(.body)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var errorState: some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
            Text("Reset failed. Try again.")
                .folioText(.body)
            Button {
                confirmReset = true
            } label: {
                Text("Retry reset")
                    .folioText(.body)
                    .foregroundStyle(FolioChrome.Palette.accent)
                    .folioRowHit()
            }
            .buttonStyle(.plain)
            .disabled(resetBusy)
        }
    }

    private func resetAll() async {
        guard resetBusy == false else { return }
        resetBusy = true
        do {
            try await folio.resetAllData()
            persistFailed = false
        } catch {
            persistFailed = true
        }
        resetBusy = false
    }
}
