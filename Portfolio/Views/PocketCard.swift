import Charts
import SwiftUI

/// Presentational pocket card (Figma 6367:67486 / cash 6367:67524). Takes values only, never the store,
/// so it can be dropped into a horizontal pager as-is.
struct PocketCard: View {
    let pocket: Pocket
    @State private var tab = 0
    @State private var range = "1W"

    private static let ranges = ["1W", "MTD", "1M", "3M", "YTD", "1Y", "All"]
    private var isCash: Bool { pocket.history.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                Text(pocket.title).font(.bodyXXL)
                Spacer()
                if isCash {
                    Image(systemName: "ellipsis").rotationEffect(.degrees(90)).frame(width: 24, height: 24)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    tabs
                    balance
                }
                if !isCash { today }
            }
            Group {
                if isCash { currencies } else { chart }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .foregroundStyle(Color.textPrimary)
        .padding(24)
        .frame(height: 405)
        .background(.white, in: .rect(cornerRadius: 40))
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
            Chart(Array(pocket.history.enumerated()), id: \.offset) { point in
                LineMark(x: .value("Day", point.offset), y: .value("Value", point.element))
                    .foregroundStyle(Color.textAccent)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
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
