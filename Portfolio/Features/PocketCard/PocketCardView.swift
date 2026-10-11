import Charts
import SwiftUI

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

/// Card collapse 0 (floating card) … 1 (flat header) for `offset` points scrolled past `start`.
func collapseProgress(offset: CGFloat, start: CGFloat, distance: CGFloat) -> CGFloat {
    distance > 0 ? min(max((offset - start) / distance, 0), 1) : 0
}

/// Chart, pills and compare block fade out faster than the card shrinks: gone at t ≈ 0.556.
func bodyOpacity(_ t: CGFloat) -> CGFloat { max(0, min(1, 1 - t * 1.8)) }

/// Card geometry. Every row has a fixed height, so expanded/collapsed heights are known without measuring.
enum CardMetrics {
    static let margin: CGFloat = 12
    static let radius: CGFloat = 40
    static let inset: CGFloat = 24
    static let topPadding: CGFloat = 16
    static let collapsedTopPadding: CGFloat = 8
    static let header: CGFloat = 40
    static let gap: CGFloat = 16
    static let tabs: CGFloat = 30
    static let value: CGFloat = 40
    static let change: CGFloat = 24
    static let chart: CGFloat = 220
    static let pills: CGFloat = 28
    static let bottomPadding: CGFloat = 24
    static let collapsedBottomPadding: CGFloat = 16
    /// 16 gap + 1 divider + 16 gap + 24 row, Performance tab only.
    static let compareBlock: CGFloat = gap + 1 + gap + 24
    static let cashRow: CGFloat = 44
    /// 24 gap + 40 pill row + 16, folds away after the card has collapsed.
    static let chipsBlock: CGFloat = 80

    static let expandedHeight = topPadding + header + gap + tabs + gap + value + change
        + gap + chart + gap + pills + bottomPadding
    static let collapsedHeight = collapsedTopPadding + header + gap + tabs + gap + value + change + collapsedBottomPadding
    static let collapseRange = expandedHeight - collapsedHeight

    static func expandedHeight(compare: Bool) -> CGFloat { expandedHeight + (compare ? compareBlock : 0) }
    static func collapseRange(compare: Bool) -> CGFloat { collapseRange + (compare ? compareBlock : 0) }
}

/// Presentational pocket card. Takes values and closures only, never the model, so it drops into the pager as-is.
struct PocketCardView: View {
    let card: PocketCard
    let collapse: CGFloat
    let height: CGFloat
    let showsMenu: Bool
    let activeTab: Int
    let periodIndex: Int
    let isBalanceVisible: Bool
    let benchmark: String?
    var onCardTab: (Int) -> Void = { _ in }
    var onPeriod: (Int) -> Void = { _ in }
    var onToggleBalance: () -> Void = {}
    var onBenchmark: (String?) -> Void = { _ in }
    var onDetails: () -> Void = {}
    var onChartHeld: (Bool) -> Void = { _ in }

    private var period: String { DummyData.periods[periodIndex] }
    private var series: [ChartPoint] { card.seriesByPeriod[period] ?? [] }
    private var showsCompare: Bool { card.kind == .valueChart && activeTab == 1 }

    var body: some View {
        let t = collapse
        let radius = lerp(CardMetrics.radius, 0, t)
        VStack(alignment: .leading, spacing: 0) {
            header.frame(height: CardMetrics.header)
            if let promo = card.promo {
                promoBody(promo).padding(.top, CardMetrics.gap)
            } else {
                tabs.frame(height: CardMetrics.tabs).padding(.top, CardMetrics.gap)
                valueRow.frame(height: CardMetrics.value).padding(.top, CardMetrics.gap)
                changeRow.frame(height: CardMetrics.change)
                Group {
                    if card.kind == .cashBalance { cashRows } else { chartBody }
                }
                .padding(.top, CardMetrics.gap)
                .opacity(bodyOpacity(t))
                .allowsHitTesting(t == 0)
            }
        }
        // Rows keep their expanded layout and are cut off by the shrinking frame, so nothing reflows mid-scroll.
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, CardMetrics.inset)
        .padding(.top, lerp(CardMetrics.topPadding, CardMetrics.collapsedTopPadding, t))
        .frame(height: height, alignment: .top)
        .background {
            ZStack(alignment: .bottomTrailing) {
                Color.card
                if let promo = card.promo {
                    Image(promo.imageName).resizable().scaledToFit().frame(width: 260).opacity(0.35).offset(x: 40, y: 30)
                }
            }
        }
        .clipShape(.rect(cornerRadius: radius))
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let icon = card.iconName {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Color.surfaceGrey20, in: .circle)
            }
            Text(card.title).font(.bodyXXL).lineLimit(1)
            if let badge = card.badge {
                Text(badge.text)
                    .font(.captionM)
                    .foregroundStyle(badgeColor(badge.level))
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(badgeColor(badge.level).opacity(0.15), in: .capsule)
            }
            Spacer(minLength: 0)
            if showsMenu {
                Menu {
                    Button("Rename", systemImage: "pencil") {}
                    Button("Settings", systemImage: "gearshape") {}
                } label: {
                    Image(systemName: "ellipsis").rotationEffect(.degrees(90)).frame(width: 40, height: 40)
                }
            }
        }
    }

    private func badgeColor(_ level: BadgeLevel) -> Color {
        switch level {
        case .low: .textAccent
        case .medium: .textWarning
        case .high: .textAlert
        }
    }

    private var tabs: some View {
        HStack(spacing: 16) {
            ForEach(Array((card.kind == .cashBalance ? ["Cash balance", "Cards"] : ["Value", "Performance"]).enumerated()),
                    id: \.offset) { index, title in
                Button { onCardTab(index) } label: {
                    Text(title)
                        .font(.bodyM)
                        .foregroundStyle(activeTab == index ? Color.textPrimary : Color.textSecondary)
                        .frame(maxHeight: .infinity)
                        .overlay(alignment: .bottom) {
                            Rectangle().frame(height: 2).opacity(activeTab == index ? 1 : 0)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var valueRow: some View {
        HStack(alignment: .center) {
            Text(money(card.value, visible: isBalanceVisible))
                .font(.system(size: 32, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
            Button(action: onToggleBalance) {
                Image(systemName: isBalanceVisible ? "eye" : "eye.slash")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
    }

    /// Always takes its 24pt, even when empty, so heights stay deterministic.
    private var changeRow: some View {
        HStack(spacing: 8) {
            if card.kind == .valueChart, isBalanceVisible, series.count > 1 {
                let change = periodChange(series)
                Text(period).foregroundStyle(Color.textSecondary)
                Group {
                    Text(change.delta.signed)
                    Text(change.percent.signedPercent)
                }
                .foregroundStyle(change.delta >= 0 ? Color.textAccent : Color.textAlert)
            }
        }
        .font(.bodyM)
    }

    private var chartBody: some View {
        VStack(spacing: 0) {
            chart.frame(height: CardMetrics.chart)
            pills.frame(height: CardMetrics.pills).padding(.top, CardMetrics.gap)
            if showsCompare { compare }
        }
    }

    @ViewBuilder private var chart: some View {
        // Tooltip top sits just under the value row, over the change row.
        let tooltipTop = -(CardMetrics.change + CardMetrics.gap)
        // Separate view types, so switching Value/Performance drops any selection.
        if activeTab == 0 {
            ValueLineChartView(points: series, lineColor: trendColor(series), isMasked: !isBalanceVisible,
                               tooltipTop: tooltipTop, onScrubChanged: onChartHeld)
        } else {
            PerformanceChartView(portfolio: percentSeries(series),
                                 benchmark: benchmark.map { percentSeries(DummyData.benchmark($0, like: series)) },
                                 benchmarkColor: .benchmarkLine, tooltipTop: tooltipTop, onScrubChanged: onChartHeld)
        }
    }

    private var pills: some View {
        HStack(spacing: 0) {
            ForEach(Array(DummyData.periods.enumerated()), id: \.offset) { index, item in
                Button { onPeriod(index) } label: {
                    Text(item)
                        .font(.captionM)
                        .foregroundStyle(periodIndex == index ? Color.textPrimary : Color.textSecondary)
                        .padding(.horizontal, 10)
                        .frame(maxHeight: .infinity)
                        .background(periodIndex == index ? Color.surfaceGrey30 : .clear, in: .capsule)
                }
                .buttonStyle(.plain)
                if index != DummyData.periods.count - 1 { Spacer(minLength: 0) }
            }
        }
    }

    private var compare: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.borderPrimary).frame(height: 1).padding(.vertical, CardMetrics.gap)
            HStack {
                Text("Compare to").font(.bodyM).foregroundStyle(Color.textSecondary)
                Spacer()
                Menu {
                    Button("None") { onBenchmark(nil) }
                    ForEach(DummyData.benchmarks, id: \.self) { name in
                        Button(name) { onBenchmark(name) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if benchmark != nil { Circle().fill(Color.benchmarkLine).frame(width: 8, height: 8) }
                        Text(benchmark ?? "Select")
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                    }
                    .font(.bodyM)
                    .foregroundStyle(Color.textPrimary)
                }
            }
            .frame(height: 24)
        }
    }

    private var cashRows: some View {
        VStack(spacing: 0) {
            ForEach(Array(card.cashRows.enumerated()), id: \.offset) { index, row in
                if index > 0 { Rectangle().fill(Color.borderPrimary).frame(height: 1) }
                HStack {
                    Text(row.title)
                    Spacer()
                    Text(money(row.value, row.currencySymbol, visible: isBalanceVisible))
                }
                .font(.bodyS)
                .frame(height: CardMetrics.cashRow)
            }
        }
    }

    private func promoBody(_ promo: Promo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(promo.headline).font(.titleXL)
            Text(promo.description).font(.bodyS).foregroundStyle(Color.textSecondary).lineLimit(2)
            Button(action: onDetails) {
                HStack(spacing: 4) {
                    Text("Details")
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                }
                .font(.bodyL)
                .foregroundStyle(Color.textAccent)
            }
            .buttonStyle(.plain)
            .opacity(bodyOpacity(collapse))
        }
    }
}

#Preview {
    let tabs = DummyData.tabs()
    ScrollView {
        VStack {
            ForEach(tabs) { tab in
                PocketCardView(card: tab.card, collapse: 0, height: CardMetrics.expandedHeight, showsMenu: true,
                               activeTab: 0, periodIndex: 0, isBalanceVisible: true, benchmark: nil)
            }
        }
        .padding(12)
    }
    .background(Color.surfaceGrey30)
}
