import XCTest
@testable import Washfolio

/// Family year_mood_canvas: one MoodEntry per startOfDay, quiet streak, 12 tones.
final class FamilyInvariantTests: XCTestCase {
    private let calendar = FolioTestDates.calendar
    private let palette = ToneWell.defaultPalette
    private let year = 2026

    func test_oneMoodEntryPerStartOfDay() throws {
        let morning = FolioTestDates.day(year, 6, 10, hour: 8)
        let evening = FolioTestDates.day(year, 6, 10, hour: 21)
        XCTAssertEqual(calendar.startOfDay(for: morning), calendar.startOfDay(for: evening))

        var existing: [Int: DayStroke] = [:]
        let first = try FolioCommit.stroke(
            toneIndex: 2,
            on: morning,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: ToneWell.defaultBleed,
            calendar: calendar
        )
        existing = FolioCommit.placing(first, into: existing)
        XCTAssertEqual(existing.count, 1)

        let second = try FolioCommit.stroke(
            toneIndex: 7,
            on: evening,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: ToneWell.defaultBleed,
            calendar: calendar
        )
        existing = FolioCommit.placing(second, into: existing)
        XCTAssertEqual(existing.count, 1)
        XCTAssertEqual(existing[first.dayOfYear]?.toneIndex, 7)
        XCTAssertEqual(FolioCalendar.dayOfYear(morning, calendar: calendar), first.dayOfYear)
        XCTAssertEqual(first.dayOfYear, second.dayOfYear)
    }

    func test_quietStreakEndsTodayOrYesterday_gapRestarts() {
        let today = FolioTestDates.day(year, 6, 10)
        let painted: (Int...) -> Set<Date> = { offsets in
            Set(offsets.compactMap { self.calendar.date(byAdding: .day, value: -$0, to: today) })
        }

        XCTAssertEqual(QuietStreak.length(painted: painted(0, 1, 2), now: today, calendar: calendar), 3)
        XCTAssertEqual(QuietStreak.length(painted: painted(1, 2, 3), now: today, calendar: calendar), 3)
        XCTAssertEqual(QuietStreak.length(painted: painted(0, 2, 3), now: today, calendar: calendar), 1)
        XCTAssertEqual(QuietStreak.length(painted: painted(2, 3, 4), now: today, calendar: calendar), 0)
        XCTAssertEqual(QuietStreak.length(painted: [], now: today, calendar: calendar), 0)

        let ordinals: Set<Int> = [8, 9, 10]
        XCTAssertEqual(QuietStreak.length(dayOfYears: ordinals, today: 10, yesterday: 9), 3)
        XCTAssertEqual(QuietStreak.length(dayOfYears: [8, 9], today: 10, yesterday: 9), 2)
        XCTAssertEqual(QuietStreak.length(dayOfYears: [6, 7], today: 10, yesterday: 9), 0)
    }

    func test_twelveTones_noScores() {
        XCTAssertEqual(ToneWell.toneCount, 12)
        XCTAssertEqual(ToneWell.defaultPalette.count, 12)
        XCTAssertEqual(Set(ToneWell.defaultPalette.map(\.spokenName)).count, 12)
        XCTAssertThrowsError(try ToneWell.validated(Array(ToneWell.defaultPalette.dropLast()))) { error in
            XCTAssertEqual(error as? FolioError, .invalidPalette)
        }
        XCTAssertThrowsError(
            try FolioCommit.stroke(
                toneIndex: 12,
                on: FolioTestDates.day(year, 6, 10),
                year: year,
                existing: [:],
                palette: palette,
                bleedAmount: ToneWell.defaultBleed,
                calendar: calendar
            )
        ) { error in
            XCTAssertEqual(error as? FolioError, .invalidTone)
        }
        XCTAssertThrowsError(
            try FolioCommit.stroke(
                toneIndex: -1,
                on: FolioTestDates.day(year, 6, 10),
                year: year,
                existing: [:],
                palette: palette,
                bleedAmount: ToneWell.defaultBleed,
                calendar: calendar
            )
        ) { error in
            XCTAssertEqual(error as? FolioError, .invalidTone)
        }
    }

    func test_commitEmptyPopulatedInvalid() throws {
        let today = FolioTestDates.day(year, 6, 10)
        var existing: [Int: DayStroke] = [:]
        XCTAssertTrue(existing.isEmpty)

        let painted = try FolioCommit.stroke(
            toneIndex: 4,
            on: today,
            year: year,
            existing: existing,
            palette: palette,
            bleedAmount: ToneWell.defaultBleed,
            calendar: calendar
        )
        existing = FolioCommit.placing(painted, into: existing)
        XCTAssertEqual(existing.count, 1)
        XCTAssertEqual(existing[painted.dayOfYear]?.toneIndex, 4)

        XCTAssertThrowsError(
            try FolioCommit.stroke(
                toneIndex: 4,
                on: FolioTestDates.day(2025, 6, 10),
                year: year,
                existing: existing,
                palette: palette,
                bleedAmount: ToneWell.defaultBleed,
                calendar: calendar
            )
        ) { error in
            XCTAssertEqual(error as? FolioError, .dayOutsideYear)
        }
        XCTAssertThrowsError(
            try FolioCommit.stroke(
                toneIndex: 4,
                on: today,
                year: year,
                existing: existing,
                palette: palette,
                bleedAmount: 1.5,
                calendar: calendar
            )
        ) { error in
            XCTAssertEqual(error as? FolioError, .invalidBleed)
        }
    }
}
