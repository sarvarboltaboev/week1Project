import XCTest
@testable import Portfolio

final class PortfolioTests: XCTestCase {
    func testPageProgress() {
        XCTAssertEqual(pageProgress(offset: 0, width: 400), 0)
        XCTAssertEqual(pageProgress(offset: -200, width: 400), 0.5)
        XCTAssertEqual(pageProgress(offset: 400, width: 400), 1)
        XCTAssertEqual(pageProgress(offset: -900, width: 400), 1)
    }

    func testLerp() {
        XCTAssertEqual(lerp(12, 0, 0), 12)
        XCTAssertEqual(lerp(12, 0, 1), 0)
        XCTAssertEqual(lerp(40, 0, 0.5), 20)
    }

    func testCollapseProgressClamps() {
        XCTAssertEqual(collapseProgress(offset: -50, start: 0, distance: 328), 0)
        XCTAssertEqual(collapseProgress(offset: 164, start: 0, distance: 328), 0.5)
        XCTAssertEqual(collapseProgress(offset: 900, start: 0, distance: 328), 1)
        XCTAssertEqual(collapseProgress(offset: 10, start: 0, distance: 0), 0)
    }

    func testBodyOpacity() {
        XCTAssertEqual(bodyOpacity(0), 1)
        XCTAssertEqual(bodyOpacity(0.25), 0.55, accuracy: 1e-9)
        XCTAssertEqual(bodyOpacity(1 / 1.8), 0, accuracy: 1e-9)
        XCTAssertEqual(bodyOpacity(1), 0)
    }

    func testHintOffset() {
        XCTAssertEqual(hintOffset(at: 0), 0)
        XCTAssertEqual(hintOffset(at: 0.35 * 1.6), 0)
        XCTAssertEqual(hintOffset(at: 1.6 - 1e-9), -79, accuracy: 1e-3)
        XCTAssertEqual(hintOffset(at: 0.675 * 1.6), -39.5, accuracy: 1e-3)
        XCTAssertEqual(hintOffset(at: 1.6 + 0.1), 0)
    }
}
