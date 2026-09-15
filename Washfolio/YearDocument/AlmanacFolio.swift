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
    @Published private(set) var dailyReminder: Bool
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
        self.dailyReminder = false
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
        dailyReminder = await store.loadReminder()
        if dailyReminder {
            dailyReminder = await FolioReminder.enable()
            await store.saveReminder(dailyReminder)
        }
    }

    func commit(toneIndex: Int, on date: Date) throws {
        strokesByDay = try FolioCommit.applying(
            toneIndex: toneIndex,
            on: date,
            year: year,
            existing: strokesByDay,
            palette: palette,
            bleedAmount: bleedAmount,
            calendar: calendar,
            now: now()
        )
        persistSoon()
    }

    func clear(dayOfYear: Int) {
        guard strokesByDay[dayOfYear] != nil else { return }
        strokesByDay = FolioCommit.removing(
            dayOfYear: dayOfYear,
            from: strokesByDay,
            palette: palette,
            bleedAmount: bleedAmount
        )
        persistSoon()
    }

    func canMark(_ date: Date) -> Bool {
        FolioCalendar.year(of: date, calendar: calendar) == year
            && FolioCalendar.startOfDay(date, calendar: calendar) <= FolioCalendar.startOfDay(now(), calendar: calendar)
    }

    func insight(at date: Date? = nil, month: Int? = nil) -> FolioInsight {
        FolioCensus.insight(
            year: year,
            strokes: strokes,
            palette: palette,
            now: date ?? now(),
            month: month,
            calendar: calendar
        )
    }

    func yesterdayStroke(at date: Date? = nil) -> DayStroke? {
        let moment = date ?? now()
        guard let yesterday = FolioCalendar.yesterday(of: moment, calendar: calendar) else { return nil }
        return stroke(on: yesterday)
    }

    func repeatYesterday(on date: Date) throws {
        guard let prior = yesterdayStroke(at: date) else { throw FolioError.invalidTone }
        try commit(toneIndex: prior.toneIndex, on: date)
    }

    func stateCounts(inMonth month: Int? = nil) -> [FolioStateCount] {
        let filtered: [DayStroke]
        if let month {
            filtered = strokes.filter { stroke in
                guard let day = FolioCalendar.date(year: year, dayOfYear: stroke.dayOfYear, calendar: calendar) else {
                    return false
                }
                return FolioCalendar.month(day, calendar: calendar) == month
            }
        } else {
            filtered = strokes
        }
        return FolioCensus.counts(strokes: filtered, palette: palette)
    }

    func longestWashes() -> [FolioStateCount] {
        FolioCensus.longestByState(runs: washRuns, strokes: strokesByDay, palette: palette)
    }

    func rewritePalette(_ palette: [FolioSwatch]) throws {
        self.palette = try ToneWell.validated(palette)
        strokesByDay = FolioCommit.rebleedAll(strokesByDay, palette: self.palette, bleedAmount: bleedAmount)
        persistSoon()
    }

    func setBleedAmount(_ amount: Double) throws {
        bleedAmount = try ToneWell.settingBleed(amount)
        strokesByDay = FolioCommit.rebleedAll(strokesByDay, palette: palette, bleedAmount: bleedAmount)
        persistSoon()
    }

    func setDailyReminder(_ enabled: Bool) async {
        if enabled {
            dailyReminder = await FolioReminder.enable()
        } else {
            await FolioReminder.disable()
            dailyReminder = false
        }
        await store.saveReminder(dailyReminder)
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
        await FolioReminder.disable()
        dailyReminder = false
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
