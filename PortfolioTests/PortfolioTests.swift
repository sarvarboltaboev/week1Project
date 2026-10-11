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

final class PocketsSpecTests: XCTestCase {
    func testCardMetrics() {
        XCTAssertEqual(CardMetrics.expandedHeight, 486)
        XCTAssertEqual(CardMetrics.collapsedHeight, 190)
        XCTAssertEqual(CardMetrics.collapseRange, 296)
        XCTAssertEqual(CardMetrics.expandedHeight(compare: true), 543)
        XCTAssertEqual(CardMetrics.collapseRange(compare: true), 353)
    }

    func testPeriodChange() {
        let now = Date()
        let series = [100.0, 90, 101.08].map { ChartPoint(date: now, value: $0) }
        let change = periodChange(series)
        XCTAssertEqual(change.delta, 1.08, accuracy: 1e-9)
        XCTAssertEqual(change.percent, 1.08, accuracy: 1e-9)
        XCTAssertEqual(periodChange([]).delta, 0)
        XCTAssertEqual(periodChange(Array(series.prefix(1))).percent, 0)
    }

    func testMoneyMasking() {
        XCTAssertEqual(money(12_480.55, visible: true), "$12,480.55")
        XCTAssertEqual(money(-3.1, "€", visible: true), "-€3.10")
        XCTAssertEqual(money(12_480.55, visible: false), "••••")
    }

    func testSelectResetsCardTab() {
        let model = PocketsHomeModel()
        model.setCardTab(1)
        model.select("tech")
        XCTAssertEqual(model.activeCardTab, 0)
        XCTAssertEqual(model.selectedTabID, "tech")
    }

    func testDummyDataShape() {
        let tabs = DummyData.tabs()
        XCTAssertEqual(tabs.map(\.id), ["all", "cash", "growth", "tech", "halal"])
        for period in DummyData.periods {
            let series = tabs[0].card.seriesByPeriod[period] ?? []
            XCTAssert((30...90).contains(series.count), period)
            XCTAssertEqual(series.last?.value ?? 0, 12_480.55, accuracy: 1e-6)
        }
        XCTAssertFalse(tabs[1].hasHoldings)
        XCTAssertFalse(tabs[4].hasHoldings)
    }
}
