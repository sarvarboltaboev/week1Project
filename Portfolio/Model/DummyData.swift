import Foundation

enum DummyData {
    static let periods = ["1W", "MTD", "1M", "3M", "YTD", "1Y", "ALL"]
    static let benchmarks = ["S&P 500", "Nasdaq", "Gold"]
    static let ordersCount = 2

    /// Fresh tabs with newly generated series; called again on pull-to-refresh.
    static func tabs() -> [PocketTab] {
        [
            PocketTab(
                id: "all", title: "All", kind: .all,
                card: PocketCard(kind: .valueChart, title: "All Pockets", iconName: nil, badge: nil,
                                 value: 12_480.55, seriesByPeriod: series(endingAt: 12_480.55)),
                sections: [
                    HoldingsSection(title: "Managed by Hyssa", seeAll: false, managedRows: [growthRow], holdingRows: []),
                    HoldingsSection(title: "Managed by you", seeAll: true, managedRows: [], holdingRows: [
                        HoldingRow(ticker: "AAPL", name: "Apple Inc.", quantity: 10, price: 227.52, value: 2275.20),
                        HoldingRow(ticker: "MSFT", name: "Microsoft", quantity: 5, price: 415.10, value: 2075.50),
                        HoldingRow(ticker: "NVDA", name: "NVIDIA", quantity: 12, price: 121.40, value: 1456.80),
                    ]),
                ]
            ),
            PocketTab(
                id: "cash", title: "Cash", kind: .cash,
                card: PocketCard(kind: .cashBalance, title: "Cash Pockets", iconName: nil, badge: nil, value: 1514.10,
                                 cashRows: [
                                     CashRow(title: "US Dollar", value: 1204.10, currencySymbol: "$"),
                                     CashRow(title: "Euro", value: 310.00, currencySymbol: "€"),
                                 ])
            ),
            PocketTab(
                id: "growth", title: "Growth Investor", kind: .managed,
                card: PocketCard(kind: .valueChart, title: "Growth Investor", iconName: "chart.line.uptrend.xyaxis",
                                 badge: ("Medium risk", .medium), value: 5120.00, seriesByPeriod: series(endingAt: 5120)),
                sections: [HoldingsSection(title: "Managed by Hyssa", seeAll: false, managedRows: [growthRow], holdingRows: [])]
            ),
            PocketTab(
                id: "tech", title: "My Tech", kind: .pocket,
                card: PocketCard(kind: .valueChart, title: "My Tech", iconName: "cpu", badge: nil,
                                 value: 3842.35, seriesByPeriod: series(endingAt: 3842.35)),
                sections: [HoldingsSection(title: "Managed by you", seeAll: true, managedRows: [], holdingRows: [
                    HoldingRow(ticker: "AAPL", name: "Apple Inc.", quantity: 4, price: 227.52, value: 910.08),
                    HoldingRow(ticker: "MSFT", name: "Microsoft", quantity: 2, price: 415.10, value: 830.20),
                    HoldingRow(ticker: "NVDA", name: "NVIDIA", quantity: 9, price: 121.40, value: 1092.60),
                    HoldingRow(ticker: "AMD", name: "Advanced Micro Devices", quantity: 6, price: 168.25, value: 1009.50),
                ])]
            ),
            PocketTab(
                id: "halal", title: "Halal Income", kind: .managed,
                card: PocketCard(kind: .promo, title: "Halal Income", iconName: "moon.stars", badge: ("Low risk", .low), value: 0,
                                 promo: Promo(headline: "Grow with halal income",
                                              description: "Sharia-compliant sukuk and dividend stocks.\nManaged by Hyssa, rebalanced monthly.",
                                              imageName: "Diamond"))
            ),
        ]
    }

    static let activities: [ActivityRow] = [
        ActivityRow(title: "Bought AAPL", subtitle: "2 x $227.52", amount: -455.04, date: daysAgo(1)),
        ActivityRow(title: "Top up", subtitle: "Bank transfer", amount: 1000, date: daysAgo(3)),
        ActivityRow(title: "Sold MSFT", subtitle: "1 x $415.10", amount: 415.10, date: daysAgo(6)),
        ActivityRow(title: "Dividend", subtitle: "NVDA", amount: 3.12, date: daysAgo(9)),
    ]

    /// Benchmark line over the same dates as `series`, starting at its first value so the two compare.
    /// ponytail: deterministic sine wave per name, swap for real index data later.
    static func benchmark(_ name: String, like series: [ChartPoint]) -> [ChartPoint] {
        guard let first = series.first?.value else { return [] }
        let k = Double(benchmarks.firstIndex(of: name) ?? 0) + 1
        return series.enumerated().map { i, point in
            let x = Double(i) / Double(max(series.count - 1, 1))
            return ChartPoint(date: point.date, value: first * (1 + 0.04 * x * k / 2 + 0.015 * sin(x * 9 * k)))
        }
    }

    private static let growthRow = ManagedRow(title: "Growth Investor", subtitle: "Hyssa Halal Portfolios",
                                              iconName: "chart.line.uptrend.xyaxis", value: 5120.00)

    private static func daysAgo(_ days: Int) -> Date { Date().addingTimeInterval(-Double(days) * 86_400) }

    private static func series(endingAt value: Double) -> [String: [ChartPoint]] {
        let spans = ["1W": 7.0, "MTD": 10, "1M": 30, "3M": 90, "YTD": 280, "1Y": 365, "ALL": 1095]
        return spans.mapValues { walk(endingAt: value, days: $0) }
    }

    /// Gentle random walk of 30–90 points spread over `days`, scaled so the last point equals `value`.
    private static func walk(endingAt value: Double, days: Double) -> [ChartPoint] {
        let count = Int.random(in: 30...90)
        var v = 1.0
        let raw = (0..<count).map { _ in
            v *= 1 + Double.random(in: -0.012...0.014)
            return v
        }
        let scale = value / raw[raw.count - 1]
        let now = Date()
        return raw.enumerated().map { i, r in
            ChartPoint(date: now.addingTimeInterval(-days * 86_400 * Double(count - 1 - i) / Double(count - 1)), value: r * scale)
        }
    }
}
