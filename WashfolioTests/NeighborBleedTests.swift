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
        let run = WashRun(startDayOfYear: 10, length: 3)
        XCTAssertEqual(run.endDayOfYear, 12)
        let start = run.startDate(year: year, calendar: calendar)
        let end = run.endDate(year: year, calendar: calendar)
        XCTAssertEqual(FolioCalendar.dayOfYear(start!, calendar: calendar), 10)
        XCTAssertEqual(FolioCalendar.dayOfYear(end!, calendar: calendar), 12)
        let named = WashRun(startDayOfYear: 10, length: 1)
        let stroke = DayStroke(dayOfYear: 10, year: year, toneIndex: 7, wash: palette[7].ink)
        XCTAssertEqual(named.spokenName(palette: palette, strokes: [10: stroke]), "Focused")
    }

    func test_leapYearDayCount() {
        XCTAssertEqual(FolioCalendar.daysInYear(2024, calendar: calendar), 366)
        XCTAssertEqual(FolioCalendar.daysInYear(2026, calendar: calendar), 365)
        XCTAssertEqual(FolioCalendar.daysInMonth(2, year: 2024, calendar: calendar), 29)
        XCTAssertEqual(FolioCalendar.daysInMonth(2, year: 2026, calendar: calendar), 28)
        let first = FolioTestDates.day(year, 1, 1)
        XCTAssertEqual(FolioCalendar.weekdayColumn(of: first, calendar: calendar), 4)
    }

    func test_rebleedUpdatesNeighborAfterYesterdayChanges() throws {
        let yesterday = FolioTestDates.day(year, 6, 9)
        let today = FolioTestDates.day(year, 6, 10)
        var existing: [Int: DayStroke] = [:]
        existing = try FolioCommit.applying(
            toneIndex: 0,
            on: yesterday,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: 0.5,
            calendar: calendar,
            now: today
        )
        existing = try FolioCommit.applying(
            toneIndex: 5,
            on: today,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: 0.5,
            calendar: calendar,
            now: today
        )
        let firstToday = try XCTUnwrap(existing[FolioCalendar.dayOfYear(today, calendar: calendar)!])
        existing = try FolioCommit.applying(
            toneIndex: 11,
            on: yesterday,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: 0.5,
            calendar: calendar,
            now: today
        )
        let rewritten = try XCTUnwrap(existing[firstToday.dayOfYear])
        XCTAssertEqual(rewritten.toneIndex, 5)
        XCTAssertNotEqual(rewritten.wash, firstToday.wash)
    }

    func test_clearIsolatesTheNextDay() throws {
        let first = FolioTestDates.day(year, 6, 8)
        let second = FolioTestDates.day(year, 6, 9)
        let now = FolioTestDates.day(year, 6, 10)
        var existing = try FolioCommit.applying(
            toneIndex: 0,
            on: first,
            year: year,
            existing: [:],
            palette: palette,
            bleedAmount: 0.8,
            calendar: calendar,
            now: now
        )
        existing = try FolioCommit.applying(
            toneIndex: 5,
            on: second,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: 0.8,
            calendar: calendar,
            now: now
        )
        let blended = try XCTUnwrap(existing[FolioCalendar.dayOfYear(second, calendar: calendar)!])
        XCTAssertNotEqual(blended.wash, palette[5].ink)
        let firstDay = try XCTUnwrap(FolioCalendar.dayOfYear(first, calendar: calendar))
        existing = FolioCommit.removing(
            dayOfYear: firstDay,
            from: existing,
            palette: palette,
            bleedAmount: 0.8
        )
        let isolated = try XCTUnwrap(existing[blended.dayOfYear])
        XCTAssertEqual(isolated.wash, palette[5].ink)
    }
}
