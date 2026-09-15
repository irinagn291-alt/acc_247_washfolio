import XCTest
@testable import Washfolio

final class FolioTypeTests: XCTestCase {
    func test_newYorkAndAssignedHex() {
        XCTAssertEqual(FolioType.family, "New York")
        XCTAssertEqual(FolioType.Hex.background, "#F4EBE0")
        XCTAssertEqual(FolioType.Hex.surface, "#E8D9C4")
        XCTAssertEqual(FolioType.Hex.ink, "#1A1510")
        XCTAssertEqual(FolioType.Hex.accent, "#9B2C28")
        XCTAssertEqual(FolioType.Hex.muted, "#5E4F3D")
        XCTAssertEqual(FolioType.Step.allCases.count, 6)
        XCTAssertEqual(FolioChrome.contact.absoluteString, "https://washfolio.pro/contact-us")
    }

    func test_figuresUseFormatters() {
        let locale = Locale(identifier: "en_US_POSIX")
        XCTAssertEqual(FolioFigures.percent(0.35, locale: locale), "35%")
        XCTAssertEqual(FolioFigures.bleed(0.35, locale: locale), "35%")
        XCTAssertEqual(FolioFigures.quiet(1, locale: locale), "1 day in a row")
        XCTAssertEqual(FolioFigures.quiet(4, locale: locale), "4 days in a row")
        XCTAssertEqual(ToneWell.defaultPalette.map(\.spokenName).first, "Dead")
        XCTAssertFalse(ToneWell.defaultPalette.map(\.spokenName).contains("Gall"))
        XCTAssertEqual(FolioFigures.daysWord(1, locale: locale), "1 day")
        XCTAssertEqual(FolioFigures.daysWord(3, locale: locale), "3 days")
        XCTAssertEqual(FolioFigures.monthName(6, locale: locale, calendar: FolioTestDates.calendar), "Jun")
        XCTAssertEqual(FolioFigures.monthTitle(6, locale: locale, calendar: FolioTestDates.calendar), "June")
        XCTAssertEqual(FolioCalendar.clampMonth(0), 1)
        XCTAssertEqual(FolioCalendar.clampMonth(13), 12)
    }

    func test_legacyInkPaletteRewritesToStates() {
        var snapshot = FolioSnapshot.empty(year: 2026)
        snapshot.palette = ToneWell.legacyInkNames.enumerated().map { index, name in
            FolioSwatch(spokenName: name, ink: ToneWell.defaultPalette[index].ink)
        }
        let normalized = FolioCodec.normalized(snapshot)
        XCTAssertEqual(normalized.palette.map(\.spokenName), ToneWell.defaultPalette.map(\.spokenName))
    }
}

@MainActor
final class WashBleedViewTests: XCTestCase {
    func test_twistScreenEmptyPopulated() {
        let empty = WashBleedView(folio: FolioPreview.empty())
        let filled = WashBleedView(folio: FolioPreview.populated())
        XCTAssertTrue(empty.folio.strokes.isEmpty)
        XCTAssertFalse(filled.folio.strokes.isEmpty)
        XCTAssertEqual(filled.folio.palette.count, 12)
        XCTAssertFalse(filled.folio.washRuns.isEmpty)
        XCTAssertTrue(filled.folio === WashBleedView(folio: filled.folio).folio)
        _ = WashBleedView()
        _ = FolioSettings(folio: FolioPreview.empty())
    }
}
