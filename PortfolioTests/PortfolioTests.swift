import XCTest
@testable import Portfolio

final class PortfolioTests: XCTestCase {
    func testPageProgress() {
        XCTAssertEqual(pageProgress(offset: 0, width: 400), 0)
        XCTAssertEqual(pageProgress(offset: -200, width: 400), 0.5)
        XCTAssertEqual(pageProgress(offset: 400, width: 400), 1)
        XCTAssertEqual(pageProgress(offset: -900, width: 400), 1)
    }
}
