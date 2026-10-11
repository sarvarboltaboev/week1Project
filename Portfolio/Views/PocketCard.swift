import Charts
import SwiftUI

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

/// Card collapse 0 (floating card) … 1 (flat header) for `offset` points scrolled past `start`.
func collapseProgress(offset: CGFloat, start: CGFloat, distance: CGFloat) -> CGFloat {
    distance > 0 ? min(max((offset - start) / distance, 0), 1) : 0
}

/// Tabs, chart and range chips fade out faster than the card shrinks: gone at t ≈ 0.556.
func bodyOpacity(_ t: CGFloat) -> CGFloat { max(0, min(1, 1 - t * 1.8)) }

/// Presentational pocket card (Figma 6367:67486 / cash 6367:67524). Takes values only, never the store,
/// so it can be dropped into a horizontal pager as-is.
struct PocketCard: View {
    let pocket: Pocket
    var collapse: CGFloat = 0
    var onChartHeld: (Bool) -> Void = { _ in }
    @State private var tab = 0
    @GestureState private var scrub: Int?

    static let expandedHeight: CGFloat = 405
    // Collapsed: 12 top + 20 title + 4 gap + 29 balance + 12 bottom.
    static let collapsedHeight: CGFloat = 77
    @State private var range = "1W"

    private static let ranges = ["1W", "MTD", "1M", "3M", "YTD", "1Y", "All"]
    private var isCash: Bool { pocket.history.isEmpty }

    var body: some View {
        let t = collapse, fade = bodyOpacity(collapse)
        let radius = lerp(40, 0, t)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(pocket.title).font(.bodyXXL)
                Spacer()
                if isCash {
                    Image(systemName: "ellipsis").rotationEffect(.degrees(90)).frame(width: 24, height: 24)
                }
            }
            .frame(height: lerp(24, 20, t))
            tabs
                .frame(height: lerp(24, 0, t), alignment: .top)
                .opacity(fade)
                .padding(.top, lerp(32, 4, t))
                .padding(.bottom, lerp(16, 0, t))
            balance.frame(height: 29)
            Group {
                if !isCash { today }
                Group {
                    if isCash { currencies } else { chart }
                }
                .padding(.top, 32)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .opacity(fade)
            .allowsHitTesting(t == 0)
        }
        // Body keeps its expanded layout and is cut off by the shrinking frame below, so nothing reflows mid-scroll.
        .frame(height: Self.expandedHeight - 48, alignment: .top)
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 24)
        .padding(.top, lerp(24, 12, t))
        .frame(height: lerp(Self.expandedHeight, Self.collapsedHeight, t), alignment: .top)
        .background(.white, in: .rect(cornerRadius: radius))
        .clipShape(.rect(cornerRadius: radius))
    }

    private var tabs: some View {
        HStack(spacing: 16) {
            ForEach(Array((isCash ? ["Cash Balance", "Cards"] : ["Value", "Performance"]).enumerated()), id: \.offset) { index, title in
                Button { tab = index } label: {
                    Text(title)
                        .font(.bodyM)
                        .foregroundStyle(tab == index ? Color.textPrimary : Color.textSecondary)
                        .frame(height: 24)
                        .overlay(alignment: .bottom) {
                            Rectangle().frame(height: 1).opacity(tab == index ? 1 : 0)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var balance: some View {
        let parts = pocket.balance.spaced.split(separator: ".")
        return HStack(spacing: 4) {
            Text("$ \(parts[0])")
            Text(".\(parts[1])")
            Spacer()
            Image(systemName: "eye").font(.system(size: 18, weight: .medium))
        }
        .font(.titleXL)
    }

    private var today: some View {
        HStack(spacing: 16) {
            Text("Today").foregroundStyle(Color.textSecondary)
            HStack(spacing: 8) {
                Text(pocket.todayChange.spaced)
                Text(pocket.todayPercent.signedPercent)
            }
            .foregroundStyle(pocket.todayChange >= 0 ? Color.textAccent : Color.textAlert)
        }
        .font(.bodyM)
        .frame(height: 24)
    }

    private var chart: some View {
        VStack(spacing: 18) {
            Chart {
                ForEach(Array(pocket.history.enumerated()), id: \.offset) { point in
                    LineMark(x: .value("Day", point.offset), y: .value("Value", point.element))
                        .foregroundStyle(Color.textAccent)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                if let scrub {
                    RuleMark(x: .value("Day", scrub))
                        .foregroundStyle(Color.textSecondary)
                        .annotation(position: .top, overflowResolution: .init(x: .fit, y: .fit)) {
                            Text(pocket.history[scrub], format: .number.precision(.fractionLength(2)))
                                .font(.captionS)
                        }
                }
            }
            .chartXAxis(.hidden)
            // ponytail: fixed 0…3K scale and labels as in Figma; derive from history once real data lands.
            .chartYScale(domain: 0...3000)
            .chartYAxis {
                AxisMarks(values: [0, 1500, 3000]) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.borderPrimary)
                }
            }
            .frame(height: 139)
            // Scrubber: press-and-hold, then drag. A quick swipe fails the long press, so the outer vertical scroll
            // (and the pager) still move when a drag starts on the chart. GestureState resets on cancel too.
            .chartOverlay { proxy in
                Color.clear.contentShape(.rect).gesture(
                    LongPressGesture(minimumDuration: 0.2)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .updating($scrub) { value, scrub, _ in
                            guard case .second(true, let drag?) = value else { return }
                            scrub = proxy.value(atX: drag.location.x, as: Int.self)
                                .map { min(max($0, 0), pocket.history.count - 1) }
                        }
                )
            }
            .onChange(of: scrub != nil) { _, held in onChartHeld(held) }
            // Labels sit 3pt above each gridline, overlapping the plot as in Figma; Charts' .inset preset drops the top one.
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: 56) {
                    Text("3K")
                    Text("1,5K")
                    Text("0")
                }
                .font(.captionS)
                .foregroundStyle(Color.textSecondary)
                .frame(height: 148)
                .offset(y: -15)
            }

            HStack(spacing: 0) {
                ForEach(Self.ranges, id: \.self) { item in
                    Button { range = item } label: {
                        Text(item)
                            .font(.captionS)
                            .foregroundStyle(range == item ? Color.textPrimary : Color.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(range == item ? Color.surfaceGrey30 : .clear, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    if item != Self.ranges.last { Spacer(minLength: 0) }
                }
            }
        }
    }

    // ponytail: currency split isn't in the model yet; hardcoded from Figma until a cash API exists.
    private var currencies: some View {
        VStack(spacing: 12) {
            currencyRow("US Dollar", "$ 999 999.02")
            Rectangle().fill(Color.borderPrimary).frame(height: 1)
            currencyRow("EURO", "€ 89 789.65")
        }
        .font(.bodyS)
    }

    private func currencyRow(_ name: String, _ amount: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(amount)
        }
    }
}

#Preview {
    VStack {
        PocketCard(pocket: MockData.pockets[0])
        PocketCard(pocket: MockData.pockets[1])
    }
    .padding(12)
    .background(Color.surfaceGrey30)
}
