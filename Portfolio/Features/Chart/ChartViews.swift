import Charts
import SwiftUI

/// Index of the point nearest `x`, or nil when it is more than `tolerance` away. Nil positions (gaps) never match.
func snapIndex(_ x: CGFloat, positions: [CGFloat?], tolerance: CGFloat = 24) -> Int? {
    let nearest = positions.indices
        .compactMap { i in positions[i].map { (index: i, distance: abs($0 - x)) } }
        .min { $0.distance < $1.distance }
    guard let nearest, nearest.distance <= tolerance else { return nil }
    return nearest.index
}

/// Leading x of a `width`-wide box centred on `center`, clamped inside `0…plotWidth`.
func tooltipLeading(center: CGFloat, width: CGFloat, plotWidth: CGFloat) -> CGFloat {
    min(max(center - width / 2, 0), plotWidth - width)
}

/// Black (white in dark mode) when the series rose or stayed flat, red when it fell.
func trendColor(_ series: [ChartPoint]) -> Color { periodChange(series).delta >= 0 ? .textPrimary : .textAlert }

/// "14 Mar 2026", field order follows the locale.
private func tooltipDate(_ date: Date) -> String { date.formatted(.dateTime.day(.twoDigits).month(.abbreviated).year()) }

/// Floating value box for the touched point. Positioned by `ScrubChart`.
struct ChartTouchTooltip: View {
    let dateLabel: String
    let primaryLabel: String
    let primaryColor: Color
    let secondaryLabel: String?
    let secondaryColor: Color?
    let showsBenchmarkRow: Bool

    var body: some View {
        VStack(spacing: 0) {
            row(primaryLabel, dot: showsBenchmarkRow ? primaryColor : nil)
            if showsBenchmarkRow {
                row(secondaryLabel ?? "--", dot: secondaryColor).padding(.top, 4)
            }
            Text(dateLabel).font(.captionM).foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color.surfaceGrey20.opacity(0.9), in: .rect(cornerRadius: 24))
        .fixedSize()
        .allowsHitTesting(false)
    }

    private func row(_ text: String, dot: Color?) -> some View {
        HStack(spacing: 4) {
            if let dot { Circle().fill(dot).frame(width: 6, height: 6) }
            Text(text).font(.bodyM).foregroundStyle(Color.textPrimary)
        }
    }
}

/// Marker on a real data point: 20pt grey halo around an 8pt dot in the line's colour.
private func markerDot(_ point: ChartPoint, _ color: Color) -> some ChartContent {
    PointMark(x: .value("Date", point.date), y: .value("Value", point.value))
        .symbol {
            Circle().fill(Color(hex: 0x5C616D, alpha: 0.25)).frame(width: 20, height: 20)
                .overlay { Circle().fill(color).frame(width: 8, height: 8) }
        }
}

/// Axis styling plus touch-to-inspect: a drag snaps `selection` to the nearest point, the tooltip follows the finger
/// with its top edge at `tooltipTop` (chart coordinates), and `onScrubChanged` reports finger down/up so the pager can lock.
private struct ScrubChart: ViewModifier {
    let dates: [Date]
    @Binding var selection: Int?
    let yLabel: (Double) -> String
    let onScrubChanged: (Bool) -> Void
    let tooltipTop: CGFloat
    let tooltip: (_ index: Int) -> ChartTouchTooltip

    /// Finger x in plot coordinates.
    @State private var fingerX: CGFloat = 0
    @State private var tooltipWidth: CGFloat = 0

    // Resets on end *and* cancel, so the selection and the pager lock can't get stuck.
    @GestureState private var isScrubbing = false

    func body(content: Content) -> some View {
        content
            .chartXAxis(.hidden)
            // 10pt inset keeps a 20pt marker on the first/last/extreme point whole.
            .chartXScale(range: .plotDimension(padding: 10))
            .chartYScale(domain: .automatic(includesZero: false), range: .plotDimension(padding: 10))
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.borderPrimary)
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text(yLabel(v)) }
                    }
                    .font(.captionS).foregroundStyle(Color.textSecondary)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plot = proxy.plotFrame.map { geo[$0] } ?? .zero
                    Rectangle().fill(.clear).contentShape(.rect)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($isScrubbing) { _, scrubbing, _ in scrubbing = true }
                                .onChanged { drag in
                                    fingerX = drag.location.x - plot.minX
                                    selection = snapIndex(fingerX,
                                                          positions: dates.map { proxy.position(forX: $0) })
                                }
                        )
                        .overlay(alignment: .topLeading) {
                            if let i = selection, dates.indices.contains(i) {
                                tooltip(i)
                                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { tooltipWidth = $0 }
                                    // Centred on the finger, never past either plot edge.
                                    .offset(x: plot.minX + tooltipLeading(center: fingerX, width: tooltipWidth, plotWidth: plot.width),
                                            y: tooltipTop)
                            }
                        }
                }
            }
            .sensoryFeedback(.selection, trigger: selection) { _, new in new != nil }
            .animation(.easeInOut(duration: 0.15), value: dates)
            // A new series re-indexes the points.
            .onChange(of: dates) { selection = nil }
            .onChange(of: isScrubbing) { _, scrubbing in
                if !scrubbing { selection = nil }
                onScrubChanged(scrubbing)
            }
            .onDisappear { if isScrubbing { onScrubChanged(false) } }
    }
}

struct ValueLineChartView: View {
    let points: [ChartPoint]
    let lineColor: Color
    let isMasked: Bool
    /// Tooltip top edge, relative to the chart's top.
    var tooltipTop: CGFloat = 0
    var onScrubChanged: (Bool) -> Void = { _ in }

    @State private var selectedIndex: Int?

    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            if let i = selectedIndex, points.indices.contains(i) {
                RuleMark(x: .value("Date", points[i].date)).foregroundStyle(Color.borderPrimary).lineStyle(StrokeStyle(lineWidth: 1))
                markerDot(points[i], lineColor)
            }
        }
        .modifier(ScrubChart(
            dates: points.map(\.date), selection: $selectedIndex,
            yLabel: { isMasked ? "••••" : $0.formatted() },
            onScrubChanged: onScrubChanged, tooltipTop: tooltipTop
        ) { i in
            ChartTouchTooltip(
                // "$12 480.55": thin-space thousands.
                dateLabel: tooltipDate(points[i].date),
                primaryLabel: money(points[i].value, visible: !isMasked).replacingOccurrences(of: ",", with: "\u{2009}"),
                primaryColor: lineColor, secondaryLabel: nil, secondaryColor: nil, showsBenchmarkRow: false
            )
        })
    }
}

struct PerformanceChartView: View {
    /// Percent series.
    let portfolio: [ChartPoint]
    /// Percent series on the portfolio's timestamps; may miss some of them.
    let benchmark: [ChartPoint]?
    let benchmarkColor: Color
    /// Tooltip top edge, relative to the chart's top.
    var tooltipTop: CGFloat = 0
    var onScrubChanged: (Bool) -> Void = { _ in }

    @State private var selectedIndex: Int?

    private func benchmarkPoint(at date: Date) -> ChartPoint? { benchmark?.first { $0.date == date } }

    var body: some View {
        let lineColor = trendColor(portfolio)
        Chart {
            ForEach(Array(portfolio.enumerated()), id: \.offset) { _, point in
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value), series: .value("Series", "Portfolio"))
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(Array((benchmark ?? []).enumerated()), id: \.offset) { _, point in
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value), series: .value("Series", "Benchmark"))
                    .foregroundStyle(benchmarkColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            if let i = selectedIndex, portfolio.indices.contains(i) {
                RuleMark(x: .value("Date", portfolio[i].date)).foregroundStyle(Color.surfaceGrey60).lineStyle(StrokeStyle(lineWidth: 1))
                markerDot(portfolio[i], lineColor)
                if let b = benchmarkPoint(at: portfolio[i].date) { markerDot(b, benchmarkColor) }
            }
        }
        .modifier(ScrubChart(
            dates: portfolio.map(\.date), selection: $selectedIndex,
            yLabel: { ($0 / 100).formatted(.percent.precision(.fractionLength(0...1))) },
            onScrubChanged: onScrubChanged, tooltipTop: tooltipTop
        ) { i in
            ChartTouchTooltip(
                dateLabel: tooltipDate(portfolio[i].date),
                primaryLabel: portfolio[i].value.signedPercent, primaryColor: lineColor,
                secondaryLabel: benchmarkPoint(at: portfolio[i].date)?.value.signedPercent, secondaryColor: benchmarkColor,
                showsBenchmarkRow: benchmark != nil
            )
        })
    }
}
