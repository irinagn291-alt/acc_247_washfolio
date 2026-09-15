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
            FolioSheetChrome(title: "Settings", closeLabel: "Close settings") {
                onDismiss()
                dismiss()
            }
            if persistFailed {
                errorState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
                        if folio.strokes.isEmpty {
                            emptyState
                        }
                        populatedState
                    }
                }
            }
        }
        .padding(FolioChrome.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        FolioEmptyState(
            image: "wfo_EmptyList",
            headline: "No marks yet.",
            line: "States and bleed are ready before the first day.",
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
            Text("How much today leans toward yesterday, so a stretch reads as one wash.")
                .folioText(.caption)
                .foregroundStyle(FolioChrome.Palette.muted)
            Text(FolioFigures.bleed(folio.bleedAmount))
                .folioText(.figure)
                .layoutPriority(1)
            FolioBleedSlider(
                value: Binding(
                    get: { folio.bleedAmount },
                    set: { try? folio.setBleedAmount($0) }
                )
            )
            bleedPreview

            Text("Reminder")
                .folioText(.title)
            Text("A local ping at 21:00 to mark today. Nothing leaves the phone.")
                .folioText(.caption)
                .foregroundStyle(FolioChrome.Palette.muted)
            Button {
                Task { await folio.setDailyReminder(!folio.dailyReminder) }
            } label: {
                HStack {
                    Text("Evening reminder")
                        .folioText(.body)
                        .lineLimit(1)
                    Spacer(minLength: FolioChrome.space(1))
                    Text(folio.dailyReminder ? "On" : "Off")
                        .folioText(.figure)
                        .foregroundStyle(folio.dailyReminder ? FolioChrome.Palette.accent : FolioChrome.Palette.ink)
                        .layoutPriority(1)
                }
                .padding(.horizontal, FolioChrome.space(1))
                .folioRowHit()
                .background(FolioChrome.Palette.surface)
            }
            .buttonStyle(.plain)
            .accessibilityValue(folio.dailyReminder ? "On" : "Off")

            Text("Twelve states")
                .folioText(.title)
            ForEach(Array(stride(from: 0, to: folio.palette.count, by: 2)), id: \.self) { index in
                HStack(spacing: FolioChrome.space(2)) {
                    toneRow(folio.palette[index])
                    if folio.palette.indices.contains(index + 1) {
                        toneRow(folio.palette[index + 1])
                    }
                }
            }
            settingsButton("Restore twelve states", accent: true) {
                try? folio.rewritePalette(ToneWell.defaultPalette)
            }

            Link(destination: FolioChrome.contact) {
                Text("Contact Washfolio")
                    .folioText(.body)
                    .foregroundStyle(FolioChrome.Palette.accent)
                    .padding(.horizontal, FolioChrome.space(1))
                    .folioRowHit()
                    .background(FolioChrome.Palette.surface)
            }
            .buttonStyle(.plain)

            settingsButton("Re-run onboarding", accent: false, action: onRerunOnboarding)
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

    private var bleedPreview: some View {
        let yesterday = folio.palette[0].ink
        let picked = folio.palette[5].ink
        let mixed = NeighborBleed.blend(picked: picked, yesterday: yesterday, amount: folio.bleedAmount)
        return VStack(alignment: .leading, spacing: FolioChrome.space(1)) {
            Text("Preview")
                .folioText(.caption)
                .foregroundStyle(FolioChrome.Palette.muted)
            HStack(spacing: FolioChrome.space(2)) {
                previewSwatch(yesterday, title: "Yesterday", name: folio.palette[0].spokenName)
                previewSwatch(mixed, title: "Today", name: "Bleed")
                previewSwatch(picked, title: "Picked", name: folio.palette[5].spokenName)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bleed preview, yesterday \(folio.palette[0].spokenName), mixed, picked \(folio.palette[5].spokenName)")
    }

    private func previewSwatch(_ ink: FolioInk, title: String, name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Rectangle()
                .fill(ink.color)
                .frame(maxWidth: .infinity, minHeight: FolioChrome.space(5))
                .overlay {
                    Rectangle().stroke(FolioChrome.Palette.ink.opacity(0.2), lineWidth: 1)
                }
            Text(title)
                .folioText(.footnote)
                .lineLimit(1)
            Text(name)
                .folioText(.caption)
                .foregroundStyle(FolioChrome.Palette.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsButton(_ title: String, accent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .folioText(.body)
                .foregroundStyle(accent ? FolioChrome.Palette.accent : FolioChrome.Palette.ink)
                .padding(.horizontal, FolioChrome.space(1))
                .folioRowHit()
                .background(FolioChrome.Palette.surface)
        }
        .buttonStyle(.plain)
    }

    private func toneRow(_ swatch: FolioSwatch) -> some View {
        HStack(spacing: FolioChrome.space(1)) {
            Circle()
                .fill(swatch.ink.color)
                .frame(width: 28, height: 28)
                .overlay { Circle().stroke(FolioChrome.Palette.ink.opacity(0.3), lineWidth: 1) }
            Text(swatch.spokenName)
                .folioText(.body)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: FolioChrome.tap, alignment: .leading)
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
