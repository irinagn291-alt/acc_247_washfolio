import Foundation

/// Role: Year document. Preference keys. Demo seed is Simulator-only and versioned.
enum FolioKey {
    static let snapshot = "wfo.folio.snapshot"
    static let backup = "wfo.folio.snapshot.backup"
    static let demo = "wfo.demo.v1"
    static let reminder = "wfo.reminder.v1"
}

/// Role: Year document. Persistence seam. The UI never touches UserDefaults.
protocol FolioPersisting: Sendable {
    func load() async -> (snapshot: FolioSnapshot?, warning: FolioWarning?)
    func note(_ snapshot: FolioSnapshot) async
    func save(_ snapshot: FolioSnapshot) async throws
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(year: Int, now: Date, calendar: Calendar) async -> FolioSnapshot?
    func loadReminder() async -> Bool
    func saveReminder(_ enabled: Bool) async
}

/// Role: Year document. One Codable snapshot in UserDefaults under a single key.
actor FolioStore: FolioPersisting {
    private let suiteName: String?
    private let writeDelayNanoseconds: UInt64
    private var latest: FolioSnapshot?
    private var writeTask: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(suiteName: String? = nil, writeDelayNanoseconds: UInt64 = 300_000_000) {
        self.suiteName = suiteName
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    func load() async -> (snapshot: FolioSnapshot?, warning: FolioWarning?) {
        let defaults = preferenceDefaults()
        guard let data = defaults.data(forKey: FolioKey.snapshot) else {
            return (nil, nil)
        }
        if let snapshot = try? FolioCodec.decode(data) {
            latest = snapshot
            return (snapshot, nil)
        }
        if let backup = defaults.data(forKey: FolioKey.backup),
           let snapshot = try? FolioCodec.decode(backup)
        {
            latest = snapshot
            return (snapshot, .recoveredFromBackup)
        }
        latest = nil
        return (nil, .startedEmpty)
    }

    func note(_ snapshot: FolioSnapshot) async {
        latest = snapshot
        scheduleFlush()
    }

    func save(_ snapshot: FolioSnapshot) async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = snapshot
        try persist(snapshot)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if let latest {
            try persist(latest)
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: FolioKey.snapshot)
        defaults.removeObject(forKey: FolioKey.backup)
        defaults.removeObject(forKey: FolioKey.reminder)
        defaults.synchronize()
    }

    func loadReminder() async -> Bool {
        preferenceDefaults().bool(forKey: FolioKey.reminder)
    }

    func saveReminder(_ enabled: Bool) async {
        let defaults = preferenceDefaults()
        defaults.set(enabled, forKey: FolioKey.reminder)
        defaults.synchronize()
    }

    func seedDemoIfNeeded(year: Int, now: Date, calendar: Calendar) async -> FolioSnapshot? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: FolioKey.demo) == nil else { return nil }
        var snapshot = latest ?? FolioSnapshot.empty(year: year)
        snapshot.year = year
        snapshot.strokes = FolioDemo.washRun(
            endingOn: now,
            year: year,
            palette: snapshot.palette,
            bleedAmount: snapshot.bleedAmount,
            calendar: calendar
        )
        snapshot.onboardingComplete = true
        latest = snapshot
        do {
            try persist(snapshot)
        } catch {
            lastWriteError = String(describing: error)
        }
        defaults.set(true, forKey: FolioKey.demo)
        defaults.synchronize()
        return snapshot
        #else
        return nil
        #endif
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if let latest {
                try persist(latest)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persist(_ snapshot: FolioSnapshot) throws {
        let data = try FolioCodec.encode(snapshot)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: FolioKey.snapshot) {
            defaults.set(previous, forKey: FolioKey.backup)
        }
        defaults.set(data, forKey: FolioKey.snapshot)
        defaults.synchronize()
        lastWriteError = nil
    }

    private func preferenceDefaults() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }
}

/// Role: Year document. Simulator-only short wash-run. Device never seeds.
enum FolioDemo {
    static func washRun(
        endingOn date: Date,
        year: Int,
        palette: [FolioSwatch],
        bleedAmount: Double,
        calendar: Calendar
    ) -> [DayStroke] {
        var existing: [Int: DayStroke] = [:]
        let start = FolioCalendar.startOfDay(date, calendar: calendar)
        for offset in [3, 2, 1, 0] {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { continue }
            guard let stroke = try? FolioCommit.stroke(
                toneIndex: (4 + (3 - offset)) % ToneWell.toneCount,
                on: day,
                year: year,
                existing: existing,
                palette: palette,
                bleedAmount: bleedAmount,
                calendar: calendar
            ) else { continue }
            existing = FolioCommit.placing(stroke, into: existing)
        }
        return existing.values.sorted { $0.dayOfYear < $1.dayOfYear }
    }
}
