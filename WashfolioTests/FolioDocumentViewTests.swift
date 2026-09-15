import XCTest
@testable import Washfolio

@MainActor
final class FolioDocumentViewTests: XCTestCase {
    func test_viewsObserveOneDocument() throws {
        let folio = FolioPreview.empty()
        let canvas = FolioCanvas(folio: folio, handlesLaunch: false)
        let wash = WashSheet(folio: folio)
        let settings = FolioSettings(folio: folio)
        XCTAssertTrue(canvas.folio === folio)
        XCTAssertTrue(wash.folio === folio)
        XCTAssertTrue(settings.folio === folio)
        XCTAssertTrue(canvas.folio === wash.folio)

        try folio.commit(toneIndex: 2, on: Date())
        XCTAssertEqual(canvas.folio.strokes.count, 1)
        XCTAssertEqual(wash.folio.washRuns.count, 1)
        XCTAssertEqual(settings.folio.strokesByDay.count, 1)
        XCTAssertEqual(folio.strokesByDay.count, 1)
    }

    func test_gridFrameReadsDocumentWithoutOwningStrokes() throws {
        let folio = FolioPreview.empty()
        let now = Date()
        let empty = FolioGrid.frame(from: folio, now: now)
        XCTAssertEqual(empty.cells.filter(\.painted).count, 0)
        XCTAssertEqual(empty.days, folio.daysInYear)

        try folio.commit(toneIndex: 5, on: now)
        let painted = FolioGrid.frame(from: folio, now: now)
        XCTAssertEqual(painted.cells.filter(\.painted).count, 1)
        XCTAssertEqual(folio.strokes.count, 1)
        XCTAssertEqual(painted.year, folio.year)
        XCTAssertEqual(painted.cells.count, folio.daysInYear)
        XCTAssertTrue(painted.cells.contains(where: { $0.isToday }))
        XCTAssertEqual(Set(painted.cells.map(\.month)).count, 12)
    }

    func test_yearLayoutReadsAsTwelveMonthAlmanac() {
        let phone = FolioYearLayout.metrics(in: CGSize(width: 358, height: 600))
        XCTAssertEqual(phone.columns, 3)
        XCTAssertEqual(phone.rows, 4)
        XCTAssertGreaterThan(phone.cellWidth, 8)
        XCTAssertGreaterThan(phone.cellHeight, 8)

        let pad = FolioYearLayout.metrics(in: CGSize(width: 980, height: 1100))
        XCTAssertEqual(pad.columns, 4)
        XCTAssertEqual(pad.rows, 3)

        let january = FolioYearLayout.monthOrigin(month: 1, metrics: phone)
        XCTAssertEqual(january, .zero)
        let april = FolioYearLayout.monthOrigin(month: 4, metrics: phone)
        XCTAssertEqual(april.x, 0)
        XCTAssertGreaterThan(april.y, 0)

        let januaryHeader = FolioYearLayout.monthHeaderRect(month: 1, metrics: phone)
        XCTAssertGreaterThanOrEqual(januaryHeader.height, FolioChrome.tap)
        XCTAssertEqual(FolioYearLayout.month(at: CGPoint(x: 8, y: 8), metrics: phone), 1)
        XCTAssertEqual(FolioYearLayout.month(at: april, metrics: phone), 4)
    }

    func test_todayCellExpandsHitTo44() {
        let today = FolioDayCell(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        today.apply(
            FolioGridCell(
                dayOfYear: 1,
                month: 1,
                dayOfMonth: 1,
                weekdayColumn: 0,
                weekRow: 0,
                painted: false,
                red: 0,
                green: 0,
                blue: 0,
                spokenName: "Blank",
                toneIndex: nil,
                isToday: true,
                isFuture: false
            )
        )
        XCTAssertTrue(today.point(inside: CGPoint(x: 22, y: 9), with: nil))
        let blank = FolioDayCell(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        blank.apply(
            FolioGridCell(
                dayOfYear: 2,
                month: 1,
                dayOfMonth: 2,
                weekdayColumn: 1,
                weekRow: 0,
                painted: false,
                red: 0,
                green: 0,
                blue: 0,
                spokenName: "Blank",
                toneIndex: nil,
                isToday: false,
                isFuture: false
            )
        )
        XCTAssertFalse(blank.point(inside: CGPoint(x: 22, y: 9), with: nil))
    }

    func test_oneStrokePerStartOfDayOnSharedDocument() throws {
        let folio = FolioPreview.empty()
        let morning = Date()
        try folio.commit(toneIndex: 1, on: morning)
        try folio.commit(toneIndex: 8, on: morning.addingTimeInterval(60 * 60 * 8))
        XCTAssertEqual(folio.strokes.count, 1)
        XCTAssertEqual(folio.strokes.first?.toneIndex, 8)
        XCTAssertEqual(ToneWell.toneCount, 12)
    }
}

@MainActor
final class FolioReviewTests: XCTestCase {
    func test_reviewLaunch_onceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            FolioReview.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = FolioReview.consume(
            arguments: ["-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)

        let second = FolioReview.consume(
            arguments: ["-ReviewScreen", "goals"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertNil(second)

        var wash = false
        var settings = false
        FolioLaunch.bind(.log, wash: &wash, settings: &settings)
        XCTAssertTrue(wash)
        XCTAssertFalse(settings)
        FolioLaunch.bind(.goals, wash: &wash, settings: &settings)
        XCTAssertTrue(settings)
        XCTAssertFalse(wash)
        FolioLaunch.bind(.today, wash: &wash, settings: &settings)
        XCTAssertFalse(wash)
        XCTAssertFalse(settings)
    }
}

@MainActor
final class ScreenFactoryTests: XCTestCase {
    func test_mainScreensConstructWithNoArguments() {
        _ = FolioCanvas()
        _ = FolioMonthBoard(
            frame: FolioGridFrame(year: 2026, days: 0, today: 1, cells: []),
            month: 6,
            selectedDay: nil,
            focusTone: nil,
            onSelect: { _ in }
        )
        _ = WashSheet()
        _ = WashView()
        _ = FolioSettings()
        _ = FolioOnboarding()
        _ = WashBleedView()
        _ = ContentView()
    }
}
