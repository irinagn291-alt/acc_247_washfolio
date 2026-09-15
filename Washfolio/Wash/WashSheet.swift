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
            FolioSheetChrome(title: "Washes", closeLabel: "Close wash") {
                dismiss()
            }
            if let warning = folio.warning, folio.washRuns.isEmpty {
                errorState(warning)
            } else if folio.washRuns.isEmpty {
                emptyState
            } else {
                ScrollView {
                    populated
                }
            }
        }
        .padding(FolioChrome.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        FolioEmptyState(
            image: "wfo_EmptyList",
            headline: "No washes yet.",
            line: "Mark consecutive days and they become one stretch.",
            actionTitle: "Mark today"
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
                Text("Days in a row")
                    .folioText(.body)
                    .lineLimit(1)
                Spacer(minLength: FolioChrome.space(1))
                Text(FolioFigures.integer(folio.quietStreak()))
                    .folioText(.figure)
                    .layoutPriority(1)
            }
            .frame(minHeight: FolioChrome.tap)
            censusBlock(title: "This month", counts: folio.stateCounts(inMonth: FolioCalendar.month(Date())))
            censusBlock(title: "This year", counts: folio.stateCounts())
            longestBlock
            Text("A wash is a stretch of marked days. A gap starts a new one. Missing a day is not a failure.")
                .folioText(.caption)
                .foregroundStyle(FolioChrome.Palette.muted)
            ForEach(folio.washRuns, id: \.startDayOfYear) { run in
                runRow(run)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func censusBlock(title: String, counts: [FolioStateCount]) -> some View {
        VStack(alignment: .leading, spacing: FolioChrome.space(1)) {
            Text(title)
                .folioText(.title)
            if counts.isEmpty {
                Text("No marks in this span.")
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
            } else {
                ForEach(counts) { count in
                    HStack(spacing: FolioChrome.space(1)) {
                        Circle()
                            .fill(Color(red: count.red, green: count.green, blue: count.blue))
                            .frame(width: 14, height: 14)
                        Text(count.spokenName)
                            .folioText(.body)
                            .lineLimit(1)
                        Spacer(minLength: FolioChrome.space(1))
                        Text(FolioFigures.integer(count.count))
                            .folioText(.figure)
                            .layoutPriority(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: FolioChrome.tap)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(count.spokenName), \(FolioFigures.daysWord(count.count))")
                }
            }
        }
    }

    private var longestBlock: some View {
        let longest = folio.longestWashes()
        return VStack(alignment: .leading, spacing: FolioChrome.space(1)) {
            Text("Longest stretches")
                .folioText(.title)
            if longest.isEmpty {
                Text("No stretches yet.")
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
            } else {
                ForEach(longest.prefix(6)) { count in
                    HStack {
                        Text(count.spokenName)
                            .folioText(.body)
                            .lineLimit(1)
                        Spacer(minLength: FolioChrome.space(1))
                        Text(FolioFigures.daysWord(count.count))
                            .folioText(.figure)
                            .layoutPriority(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: FolioChrome.tap)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func runRow(_ run: WashRun) -> some View {
        let inks = run.inks(from: folio.strokesByDay)
        let start = run.startDate(year: folio.year)
        let end = run.endDate(year: folio.year)
        return HStack(spacing: FolioChrome.space(2)) {
            washBar(inks)
            VStack(alignment: .leading, spacing: 2) {
                Text(runTitle(start: start, end: end, run: run))
                    .folioText(.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(FolioFigures.daysWord(run.length))
                    .folioText(.caption)
                    .foregroundStyle(FolioChrome.Palette.muted)
            }
            Spacer(minLength: FolioChrome.space(1))
            Text(FolioFigures.integer(run.length))
                .folioText(.figure)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, minHeight: FolioChrome.tap, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(runVoice(run, start: start, end: end))
    }

    private func washBar(_ inks: [FolioInk]) -> some View {
        HStack(spacing: 1) {
            if inks.isEmpty {
                Rectangle().fill(FolioChrome.Palette.surface)
            } else {
                ForEach(Array(inks.enumerated()), id: \.offset) { _, ink in
                    Rectangle().fill(ink.color)
                }
            }
        }
        .frame(width: FolioChrome.space(8), height: FolioChrome.space(2))
        .overlay {
            Rectangle().stroke(FolioChrome.Palette.ink.opacity(0.2), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private func runTitle(start: Date?, end: Date?, run: WashRun) -> String {
        let name = run.spokenName(palette: folio.palette, strokes: folio.strokesByDay)
        if let start, let end {
            return "\(name) · \(FolioFigures.range(from: start, to: end))"
        }
        return "\(name) · day \(FolioFigures.integer(run.startDayOfYear))"
    }

    private func runVoice(_ run: WashRun, start: Date?, end: Date?) -> String {
        "\(runTitle(start: start, end: end, run: run)), \(FolioFigures.daysWord(run.length))"
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
