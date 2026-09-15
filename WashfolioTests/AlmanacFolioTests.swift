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

    func test_pastDayMarksAndFutureIsRejected() async throws {
        let folio = makeFolio()
        await folio.load()
        let yesterday = FolioTestDates.day(year, 6, 9)
        try folio.commit(toneIndex: 7, on: yesterday)
        XCTAssertEqual(folio.stroke(on: yesterday)?.toneIndex, 7)
        XCTAssertTrue(folio.canMark(yesterday))
        XCTAssertFalse(folio.canMark(FolioTestDates.day(year, 6, 11)))
        XCTAssertThrowsError(try folio.commit(toneIndex: 3, on: FolioTestDates.day(year, 6, 11))) { error in
            XCTAssertEqual(error as? FolioError, .dayInFuture)
        }
    }

    func test_clearAndInsightAndCounts() async throws {
        let folio = makeFolio()
        await folio.load()
        try folio.commit(toneIndex: 7, on: FolioTestDates.day(year, 6, 8))
        try folio.commit(toneIndex: 7, on: FolioTestDates.day(year, 6, 9))
        try folio.commit(toneIndex: 8, on: now)
        let insight = folio.insight(at: now)
        XCTAssertEqual(insight.markedMonth, 3)
        XCTAssertEqual(insight.dominantName, "Focused")
        XCTAssertEqual(folio.stateCounts(inMonth: 6).first?.spokenName, "Focused")
        XCTAssertEqual(folio.longestWashes().first?.count, 3)
        folio.clear(dayOfYear: FolioCalendar.dayOfYear(now, calendar: calendar)!)
        XCTAssertNil(folio.stroke(on: now))
        XCTAssertEqual(folio.strokes.count, 2)
    }

    func test_repeatYesterdayCopiesPriorTone() async throws {
        let folio = makeFolio()
        await folio.load()
        let yesterday = FolioTestDates.day(year, 6, 9)
        try folio.commit(toneIndex: 4, on: yesterday)
        try folio.repeatYesterday(on: now)
        XCTAssertEqual(folio.stroke(on: now)?.toneIndex, 4)
        XCTAssertEqual(folio.yesterdayStroke(at: now)?.toneIndex, 4)
    }

    func test_repeatYesterdayNeedsAPriorMark() async throws {
        let folio = makeFolio()
        await folio.load()
        XCTAssertThrowsError(try folio.repeatYesterday(on: now)) { error in
            XCTAssertEqual(error as? FolioError, .invalidTone)
        }
    }

    func test_insightForOtherMonthsAndOpenDays() async throws {
        let folio = makeFolio()
        await folio.load()
        try folio.commit(toneIndex: 8, on: FolioTestDates.day(year, 6, 8))
        let july = folio.insight(at: now, month: 7)
        XCTAssertEqual(july.elapsedMonth, 0)
        XCTAssertEqual(july.markedMonth, 0)
        XCTAssertEqual(july.unmarkedMonth, 0)

        let may = folio.insight(at: now, month: 5)
        XCTAssertEqual(may.elapsedMonth, 31)
        XCTAssertEqual(may.unmarkedMonth, 31)

        let june = folio.insight(at: now, month: 6)
        XCTAssertEqual(june.markedMonth, 1)
        XCTAssertEqual(june.elapsedMonth, 10)
        XCTAssertEqual(june.unmarkedMonth, 9)

        let frame = FolioGrid.frame(from: folio, now: now, calendar: calendar)
        let open = FolioCensus.openDays(month: 6, frame: frame)
        XCTAssertFalse(open.contains { $0.dayOfMonth == 8 })
        XCTAssertFalse(open.contains { $0.isFuture })
        XCTAssertTrue(open.contains { $0.dayOfMonth == 10 })
        XCTAssertEqual(open.count, 9)
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
