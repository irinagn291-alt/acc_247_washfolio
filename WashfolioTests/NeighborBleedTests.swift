import XCTest
@testable import Washfolio

final class NeighborBleedTests: XCTestCase {
    private let calendar = FolioTestDates.calendar
    private let palette = ToneWell.defaultPalette
    private let year = 2026

    func test_isolatedDayStaysPure() throws {
        let today = FolioTestDates.day(year, 6, 10)
        let stroke = try FolioCommit.stroke(
            toneIndex: 5,
            on: today,
            year: year,
            existing: [:],
            palette: palette,
            bleedAmount: 0.8,
            calendar: calendar
        )
        XCTAssertEqual(stroke.wash, palette[5].ink)
    }

    func test_commitLerpsTowardYesterday() throws {
        let yesterday = FolioTestDates.day(year, 6, 9)
        let today = FolioTestDates.day(year, 6, 10)
        let prior = try FolioCommit.stroke(
            toneIndex: 0,
            on: yesterday,
            year: year,
            existing: [:],
            palette: palette,
            bleedAmount: 0,
            calendar: calendar
        )
        let existing = FolioCommit.placing(prior, into: [:])
        let amount = 0.4
        let committed = try FolioCommit.stroke(
            toneIndex: 5,
            on: today,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: amount,
            calendar: calendar
        )
        let expected = NeighborBleed.blend(picked: palette[5].ink, yesterday: prior.wash, amount: amount)
        XCTAssertEqual(committed.wash.red, expected.red, accuracy: 0.0001)
        XCTAssertEqual(committed.wash.green, expected.green, accuracy: 0.0001)
        XCTAssertEqual(committed.wash.blue, expected.blue, accuracy: 0.0001)
        XCTAssertNotEqual(committed.wash, palette[5].ink)
    }

    func test_bleedAmountZeroKeepsPicked_oneBecomesYesterday() {
        let picked = FolioInk(red: 1, green: 0, blue: 0)
        let yesterday = FolioInk(red: 0, green: 0, blue: 1)
        XCTAssertEqual(NeighborBleed.blend(picked: picked, yesterday: yesterday, amount: 0), picked)
        XCTAssertEqual(NeighborBleed.blend(picked: picked, yesterday: yesterday, amount: 1), yesterday)
        let mid = NeighborBleed.blend(picked: picked, yesterday: yesterday, amount: 0.5)
        XCTAssertEqual(mid.red, 0.5, accuracy: 0.0001)
        XCTAssertEqual(mid.blue, 0.5, accuracy: 0.0001)
    }

    func test_washRunsAreLengthsNotAJournal() {
        let runs = WashCensus.runs(in: [10, 11, 12, 20])
        XCTAssertEqual(runs, [
            WashRun(startDayOfYear: 10, length: 3),
            WashRun(startDayOfYear: 20, length: 1),
        ])
        XCTAssertEqual(WashCensus.runs(in: []), [])
    }

    func test_leapYearDayCount() {
        XCTAssertEqual(FolioCalendar.daysInYear(2024, calendar: calendar), 366)
        XCTAssertEqual(FolioCalendar.daysInYear(2026, calendar: calendar), 365)
    }
}
