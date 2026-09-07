import Combine
import Foundation

/// Role: Year document. The single ObservableObject every view observes and never copies.
@MainActor
final class AlmanacFolio: ObservableObject {
    @Published private(set) var year: Int
    @Published private(set) var strokesByDay: [Int: DayStroke]
    @Published private(set) var palette: [FolioSwatch]
    @Published private(set) var bleedAmount: Double
    @Published private(set) var onboardingComplete: Bool
    @Published private(set) var warning: FolioWarning?

    private let store: any FolioPersisting
    private let calendar: Calendar
    private let now: () -> Date
    private var noteTask: Task<Void, Never>?

    init(
        store: any FolioPersisting,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        year: Int? = nil
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        let resolvedYear = year ?? FolioCalendar.year(of: now(), calendar: calendar)
        self.year = resolvedYear
        self.strokesByDay = [:]
        self.palette = ToneWell.defaultPalette
        self.bleedAmount = ToneWell.defaultBleed
        self.onboardingComplete = false
        self.warning = nil
    }

    var strokes: [DayStroke] {
        strokesByDay.values.sorted { $0.dayOfYear < $1.dayOfYear }
    }

    var washRuns: [WashRun] {
        WashCensus.runs(in: Set(strokesByDay.keys))
    }

    var daysInYear: Int {
        FolioCalendar.daysInYear(year, calendar: calendar)
    }

    func stroke(on date: Date) -> DayStroke? {
        guard let ordinal = FolioCalendar.dayOfYear(date, calendar: calendar) else { return nil }
        return strokesByDay[ordinal]
    }

    func quietStreak(at date: Date? = nil) -> Int {
        let moment = date ?? now()
        let painted = Set(strokes.compactMap { FolioCalendar.date(year: year, dayOfYear: $0.dayOfYear, calendar: calendar) })
        return QuietStreak.length(painted: painted, now: moment, calendar: calendar)
    }

    func load() async {
        let loaded = await store.load()
        if let snapshot = loaded.snapshot {
            apply(snapshot, warning: loaded.warning)
        } else {
            apply(FolioSnapshot.empty(year: year), warning: loaded.warning)
        }
        if let seeded = await store.seedDemoIfNeeded(year: year, now: now(), calendar: calendar) {
            apply(seeded, warning: warning)
        }
    }

    func commit(toneIndex: Int, on date: Date) throws {
        let stroke = try FolioCommit.stroke(
            toneIndex: toneIndex,
            on: date,
            year: year,
            existing: strokesByDay,
            palette: palette,
            bleedAmount: bleedAmount,
            calendar: calendar
        )
        strokesByDay = FolioCommit.placing(stroke, into: strokesByDay)
        persistSoon()
    }

    func rewritePalette(_ palette: [FolioSwatch]) throws {
        self.palette = try ToneWell.validated(palette)
        persistSoon()
    }

    func setBleedAmount(_ amount: Double) throws {
        bleedAmount = try ToneWell.settingBleed(amount)
        persistSoon()
    }

    func markOnboardingComplete() {
        onboardingComplete = true
        persistSoon()
    }

    func persistNow() async throws {
        noteTask?.cancel()
        noteTask = nil
        try await store.save(makeSnapshot())
    }

    func resetAllData() async throws {
        noteTask?.cancel()
        noteTask = nil
        try await store.resetAllData()
        apply(FolioSnapshot.empty(year: year), warning: nil)
        try await store.save(makeSnapshot())
    }

    private func persistSoon() {
        noteTask?.cancel()
        noteTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.store.note(self.makeSnapshot())
        }
    }

    private func apply(_ snapshot: FolioSnapshot, warning: FolioWarning?) {
        year = snapshot.year
        var byDay: [Int: DayStroke] = [:]
        for stroke in snapshot.strokes {
            byDay[stroke.dayOfYear] = stroke
        }
        strokesByDay = byDay
        palette = snapshot.palette
        bleedAmount = snapshot.bleedAmount
        onboardingComplete = snapshot.onboardingComplete
        self.warning = warning
    }

    private func makeSnapshot() -> FolioSnapshot {
        FolioSnapshot(
            schemaVersion: FolioCodec.currentSchema,
            year: year,
            strokes: strokes,
            palette: palette,
            bleedAmount: bleedAmount,
            onboardingComplete: onboardingComplete
        )
    }
}
