import XCTest
@testable import Washfolio

final class FolioStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private let calendar = FolioTestDates.calendar
    private let year = 2026

    override func setUpWithError() throws {
        suiteName = "wfo.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesStroke() async throws {
        let store = makeStore()
        let today = FolioTestDates.day(year, 6, 10)
        let stroke = try FolioCommit.stroke(
            toneIndex: 3,
            on: today,
            year: year,
            existing: [:],
            palette: ToneWell.defaultPalette,
            bleedAmount: ToneWell.defaultBleed,
            calendar: calendar
        )
        var snapshot = FolioSnapshot.empty(year: year)
        snapshot.strokes = [stroke]
        snapshot.bleedAmount = 0.25
        try await store.save(snapshot)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        let restored = try XCTUnwrap(loaded.snapshot)
        XCTAssertEqual(restored.year, year)
        XCTAssertEqual(restored.strokes.count, 1)
        XCTAssertEqual(restored.strokes.first?.toneIndex, 3)
        XCTAssertEqual(restored.strokes.first?.dayOfYear, stroke.dayOfYear)
        XCTAssertEqual(restored.bleedAmount, 0.25, accuracy: 0.0001)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        var snapshot = FolioSnapshot.empty(year: year)
        snapshot.onboardingComplete = true
        try await store.save(snapshot)
        if let good = defaults.data(forKey: FolioKey.snapshot) {
            defaults.set(good, forKey: FolioKey.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: FolioKey.snapshot)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.snapshot?.onboardingComplete, true)
        XCTAssertEqual(loaded.snapshot?.year, year)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        defaults.set(Data("nope".utf8), forKey: FolioKey.snapshot)
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertNil(loaded.snapshot)
    }

    func test_resetAllData_clearsSnapshot() async throws {
        let store = makeStore()
        try await store.save(FolioSnapshot.empty(year: year))
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertNil(loaded.snapshot)
        XCTAssertNil(defaults.data(forKey: FolioKey.snapshot))
        XCTAssertNil(defaults.data(forKey: FolioKey.backup))
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try FolioCodec.encode(FolioSnapshot.empty(year: year))
        let decoded = try FolioCodec.decode(data)
        XCTAssertEqual(decoded.year, year)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.palette.count, 12)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try FolioCodec.decode(future)) { error in
            XCTAssertEqual(error as? FolioCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try FolioCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? FolioCodec.Failure, .corrupt)
        }
    }

    func test_codecCollapsesDuplicateDays() throws {
        let day = try FolioCommit.stroke(
            toneIndex: 1,
            on: FolioTestDates.day(year, 6, 10),
            year: year,
            existing: [:],
            palette: ToneWell.defaultPalette,
            bleedAmount: 0,
            calendar: calendar
        )
        var twin = day
        twin.toneIndex = 8
        var snapshot = FolioSnapshot.empty(year: year)
        snapshot.strokes = [day, twin]
        let normalized = FolioCodec.normalized(snapshot)
        XCTAssertEqual(normalized.strokes.count, 1)
        XCTAssertEqual(normalized.strokes.first?.toneIndex, 8)
    }

    func test_formatterUsesNumberFormatter() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(FolioFigures.integer(12, locale: locale), "12")
        XCTAssertFalse(FolioFigures.bleed(0.35, locale: locale).isEmpty)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedPaintsWashRunOnce() async {
        let store = makeStore()
        let now = FolioTestDates.day(year, 6, 10)
        let first = await store.seedDemoIfNeeded(year: year, now: now, calendar: calendar)
        let second = await store.seedDemoIfNeeded(year: year, now: now, calendar: calendar)
        XCTAssertNil(second)
        let seeded = first
        XCTAssertEqual(seeded?.strokes.count, 4)
        XCTAssertEqual(seeded?.onboardingComplete, true)
        XCTAssertTrue(defaults.bool(forKey: FolioKey.demo))
        let runs = WashCensus.runs(in: Set(seeded?.strokes.map(\.dayOfYear) ?? []))
        XCTAssertEqual(runs.count, 1)
        XCTAssertEqual(runs.first?.length, 4)
    }
    #endif

    private func makeStore() -> FolioStore {
        FolioStore(suiteName: suiteName, writeDelayNanoseconds: 0)
    }
}
