import Foundation

enum PocketTabKind { case all, cash, managed, pocket }
enum PocketCardKind { case valueChart, cashBalance, promo }
enum BadgeLevel { case low, medium, high }

struct ChartPoint { let date: Date; let value: Double }

struct CashRow { let title: String; let value: Double; let currencySymbol: String }

struct Promo { let headline: String; let description: String; let imageName: String }

struct ManagedRow { let title: String; let subtitle: String; let iconName: String; let value: Double }

struct HoldingRow { let ticker: String; let name: String; let quantity: Double; let price: Double; let value: Double }

struct HoldingsSection {
    let title: String
    let seeAll: Bool
    let managedRows: [ManagedRow]
    let holdingRows: [HoldingRow]
}

struct PocketCard {
    let kind: PocketCardKind
    let title: String
    let iconName: String?
    let badge: (text: String, level: BadgeLevel)?
    let value: Double
    var cashRows: [CashRow] = []
    var promo: Promo? = nil
    var seriesByPeriod: [String: [ChartPoint]] = [:]
}

struct PocketTab: Identifiable {
    let id: String
    let title: String
    let kind: PocketTabKind
    let card: PocketCard
    var sections: [HoldingsSection] = []

    var hasHoldings: Bool { sections.contains { !$0.managedRows.isEmpty || !$0.holdingRows.isEmpty } }
}

struct ActivityRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: Double
    let date: Date
}

/// `last - first` and its percentage of `first`; zero for fewer than two points.
func periodChange(_ series: [ChartPoint]) -> (delta: Double, percent: Double) {
    guard let first = series.first?.value, let last = series.last?.value, series.count > 1, first != 0 else { return (0, 0) }
    return (last - first, (last - first) / first * 100)
}

/// "$12,480.55", or "••••" while the balance is hidden.
func money(_ value: Double, _ symbol: String = "$", visible: Bool) -> String {
    guard visible else { return "••••" }
    let number = abs(value).formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "en_US")))
    return (value < 0 ? "-" : "") + symbol + number
}

extension Double {
    /// "+120.40" / "-3.10".
    var signed: String { String(format: "%+.2f", self) }
    /// "+1.08%" / "-2.85%".
    var signedPercent: String { String(format: "%+.2f%%", self) }
}
