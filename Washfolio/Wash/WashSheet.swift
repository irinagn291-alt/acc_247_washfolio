import SwiftUI

/// Role: Wash. Analytics sheet. Observes AlmanacFolio. Lists wash-run lengths, not a journal.
struct WashSheet: View {
    @ObservedObject var folio: AlmanacFolio
    var onPaint: () -> Void
    var onRetry: () async -> Void
    @Environment(\.dismiss) private var dismiss

    init(
        folio: AlmanacFolio,
        onPaint: @escaping () -> Void = {},
        onRetry: @escaping () async -> Void = {}
    ) {
        self.folio = folio
        self.onPaint = onPaint
        self.onRetry = onRetry
    }

    init() {
        self.init(folio: FolioPreview.populated())
    }

    var body: some View {
        sheetBody
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(FolioChrome.Palette.background.ignoresSafeArea())
    }

    private var sheetBody: some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
            FolioSheetChrome(title: "Wash", closeLabel: "Close wash") {
                dismiss()
            }
            if let warning = folio.warning, folio.washRuns.isEmpty {
                errorState(warning)
            } else if folio.washRuns.isEmpty {
                emptyState
            } else {
                populated
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
            actionTitle: "Paint today"
        ) {
            dismiss()
            onPaint()
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
            WashBleedView(folio: folio, onPaint: {
                dismiss()
                onPaint()
            }, fillsCanvas: false)
            HStack {
                Text("Quiet days")
                    .folioText(.body)
                    .lineLimit(1)
                Spacer(minLength: FolioChrome.space(1))
                Text(FolioFigures.integer(folio.quietStreak()))
                    .folioText(.figure)
                    .layoutPriority(1)
            }
            .frame(minHeight: FolioChrome.tap)
            Text("Neighbor-bleed wash. Consecutive days form a run. A gap ends it.")
                .folioText(.caption)
                .foregroundStyle(FolioChrome.Palette.muted)
            ForEach(folio.washRuns, id: \.startDayOfYear) { run in
                HStack {
                    Text("From day \(FolioFigures.integer(run.startDayOfYear))")
                        .folioText(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: FolioChrome.space(1))
                    Text(FolioFigures.integer(run.length))
                        .folioText(.figure)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: FolioChrome.tap)
                .contentShape(Rectangle())
                .accessibilityLabel(
                    "Wash run from day \(FolioFigures.integer(run.startDayOfYear)), length \(FolioFigures.integer(run.length))"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorState(_ warning: FolioWarning) -> some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(2)) {
            Text(warning == .recoveredFromBackup
                 ? "The folio was recovered from a spare leaf."
                 : "The wash sheet could not be read.")
                .folioText(.body)
                .multilineTextAlignment(.leading)
            Button {
                Task { await onRetry() }
            } label: {
                Text("Retry")
                    .folioText(.body)
                    .foregroundStyle(FolioChrome.Palette.accent)
                    .frame(maxWidth: .infinity, minHeight: FolioChrome.tap)
                    .background(FolioChrome.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

/// Role: Wash. Snapshot alias for the analytics sheet. Same document, no forked year.
struct WashView: View {
    var body: some View {
        WashSheet()
    }
}
