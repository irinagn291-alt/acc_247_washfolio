import XCTest
@testable import Washfolio

@MainActor
final class AlmanacFolioTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private let calendar = FolioTestDates.calendar
    private let year = 2026
    private let now = FolioTestDates.day(2026, 6, 10)

    override func setUpWithError() throws {
        suiteName = "wfo.folio.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: FolioKey.demo)
    }

    override func tearDownWithError() throws {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
    }

    func test_documentIsSingleSourceOfTruth() async throws {
        let folio = makeFolio()
        await folio.load()
        XCTAssertTrue(folio.strokes.isEmpty)

        try folio.commit(toneIndex: 2, on: now)
        XCTAssertEqual(folio.strokes.count, 1)
        XCTAssertEqual(folio.stroke(on: now)?.toneIndex, 2)
        XCTAssertEqual(folio.stroke(on: FolioTestDates.day(year, 6, 10, hour: 23))?.toneIndex, 2)

        try folio.commit(toneIndex: 9, on: now)
        XCTAssertEqual(folio.strokes.count, 1)
        XCTAssertEqual(folio.strokesByDay.count, 1)
        XCTAssertEqual(folio.stroke(on: now)?.toneIndex, 9)
        XCTAssertEqual(folio.washRuns, [WashRun(startDayOfYear: folio.strokes[0].dayOfYear, length: 1)])
    }

    func test_documentRoundTripThroughStore() async throws {
        let folio = makeFolio()
        await folio.load()
        try folio.commit(toneIndex: 6, on: now)
        try folio.setBleedAmount(0.5)
        try await folio.persistNow()

        let relaunched = makeFolio()
        await relaunched.load()
        XCTAssertEqual(relaunched.strokes.count, 1)
        XCTAssertEqual(relaunched.stroke(on: now)?.toneIndex, 6)
        XCTAssertEqual(relaunched.bleedAmount, 0.5, accuracy: 0.0001)
        XCTAssertEqual(relaunched.year, year)
    }

    func test_resetAllDataEmptiesDocument() async throws {
        let folio = makeFolio()
        await folio.load()
        try folio.commit(toneIndex: 1, on: now)
        try await folio.resetAllData()
        XCTAssertTrue(folio.strokes.isEmpty)
        XCTAssertEqual(folio.bleedAmount, ToneWell.defaultBleed)
        XCTAssertEqual(folio.palette.count, 12)
        XCTAssertEqual(folio.quietStreak(at: now), 0)
    }

    private func makeFolio() -> AlmanacFolio {
        AlmanacFolio(
            store: FolioStore(suiteName: suiteName, writeDelayNanoseconds: 0),
            calendar: calendar,
            now: { self.now },
            year: year
        )
    }
}
