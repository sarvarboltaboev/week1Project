import Foundation

struct Pocket: Identifiable, Hashable {
    let id: String
    let title: String
    let balance: Decimal
    let todayChange: Decimal
    let todayPercent: Double
    /// Chart points, oldest first. Empty = no chart (cash pocket).
    let history: [Double]
}

struct Holding: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let name: String
    let quantity: Int
    let price: Decimal
    let pricePercent: Double
    let pnl: Decimal
    let pnlPercent: Double
}

struct Activity: Identifiable, Hashable {
    enum Kind: Hashable { case buy, sell, deposit }
    let id = UUID()
    let kind: Kind
    let symbol: String
    let subtitle: String
    let detail: String
    let amount: Decimal
    let time: String
}
