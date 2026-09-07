import XCTest
@testable import Washfolio

final class WashfolioTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: WashfolioApp.self), "WashfolioApp")
    }
}
