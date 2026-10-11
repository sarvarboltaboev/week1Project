import Foundation

enum MockData {
    static let pockets: [Pocket] = [
        Pocket(id: "all", title: "All Pockets", balance: 2877.65, todayChange: 100.24, todayPercent: 10.85, history: curve(seed: 1)),
        Pocket(id: "cash", title: "Cash Pockets", balance: 1_089_788.67, todayChange: 0, todayPercent: 0, history: []),
        Pocket(id: "growth", title: "Growth Investor", balance: 2877.65, todayChange: 100.24, todayPercent: 10.85, history: curve(seed: 2)),
        Pocket(id: "best", title: "World best pocket", balance: 2877.65, todayChange: 100.24, todayPercent: 10.85, history: curve(seed: 3)),
    ]

    static let holdings: [Holding] = [
        Holding(symbol: "TSLA", name: "Tesla", quantity: 100, price: 420.41, pricePercent: -2.85, pnl: 500.41, pnlPercent: 5.85),
        Holding(symbol: "ADBE", name: "Adobe Inc.", quantity: 100, price: 10.25, pricePercent: 1.85, pnl: -20.41, pnlPercent: -5.85),
        Holding(symbol: "HREE", name: "High Research Electronics", quantity: 100, price: 128.11, pricePercent: 2.02, pnl: 500.41, pnlPercent: 5.85),
        Holding(symbol: "TSLA", name: "Tesla", quantity: 100, price: 420.41, pricePercent: -2.85, pnl: 500.41, pnlPercent: 5.85),
        Holding(symbol: "ADBE", name: "Adobe Inc.", quantity: 100, price: 10.25, pricePercent: 1.85, pnl: -20.41, pnlPercent: -5.85),
        Holding(symbol: "HREE", name: "High Research Electronics", quantity: 100, price: 128.11, pricePercent: 2.02, pnl: 500.41, pnlPercent: 5.85),
    ]

    static let activity: [Activity] = [
        Activity(kind: .sell, symbol: "CMG", subtitle: "Chipotle Mexico", detail: "23 x $54.16", amount: 1245.68, time: "16:34"),
        Activity(kind: .buy, symbol: "TSLA", subtitle: "Tesla", detail: "2 x $243.54", amount: 304.82, time: "16:55"),
        Activity(kind: .deposit, symbol: "Deposit", subtitle: "Bank transfer", detail: "", amount: 1000, time: "16:34"),
    ]

    // ponytail: deterministic random walk instead of real history; swap for API data later.
    private static func curve(seed: Int) -> [Double] {
        var value = 800.0
        return (0..<60).map { i in
            value += sin(Double(i * seed) * 0.7) * 60 + 25
            return value
        }
    }
}
