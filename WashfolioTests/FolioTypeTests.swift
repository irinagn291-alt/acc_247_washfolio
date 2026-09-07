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
