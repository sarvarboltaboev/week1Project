import SwiftUI

/// Figma 6367:67643.
struct HoldingsSection: View {
    let holdings: [Holding]

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Holdings").font(.titleL)

            VStack(alignment: .leading, spacing: 16) {
                Text("MANAGED BY HYSSA").font(.captionM).foregroundStyle(Color.textSecondary)
                managedRow
            }

            VStack(spacing: 24) {
                HStack {
                    Text("MANAGED BY YOU").font(.captionM).foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text("See All").font(.bodyL).foregroundStyle(Color.textAccent)
                }
                VStack(spacing: 16) {
                    columns(Text("Symbol"), Text("Current Price"), Text("Total P&L"))
                        .font(.captionS)
                        .foregroundStyle(Color.textSecondary)
                    ForEach(holdings) { holding in
                        if holding.id != holdings.first?.id {
                            Rectangle().fill(Color.borderPrimary).frame(height: 1)
                        }
                        row(holding)
                    }
                }
            }
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .padding(.bottom, 32)
    }

    // ponytail: managed portfolio isn't modeled yet; values are the Figma copy.
    private var managedRow: some View {
        HStack(spacing: 16) {
            // Three-bar logo is drawn from plain rects in Figma too.
            ZStack(alignment: .topLeading) {
                Color(hex: 0x3D3D3D)
                Color(hex: 0xE1FFB7).frame(width: 15, height: 29).offset(x: -2, y: 24)
                Color(hex: 0xC4EE8B).frame(width: 15, height: 29).offset(x: 13, y: 16)
                Color(hex: 0xACD870).frame(width: 15, height: 33).offset(x: 28, y: 6)
            }
            .frame(width: 40, height: 40)
            .clipShape(.circle)

            VStack(alignment: .leading, spacing: 0) {
                Text("Growth Investor").font(.bodyXXL)
                Text("Hyssa Halal Portfolios").font(.captionM).foregroundStyle(Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("$51,240.00").font(.bodyXXL)
                HStack(spacing: 8) {
                    Text("+1,240.00")
                    Text("+2.48%")
                }
                .font(.captionS)
                .foregroundStyle(Color.textAccent)
            }
        }
    }

    private func row(_ holding: Holding) -> some View {
        columns(
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(holding.symbol).font(.bodyXXL)
                    Text("x \(holding.quantity)").font(.captionM).foregroundStyle(Color.textSecondary)
                }
                Text(holding.name).font(.captionM).foregroundStyle(Color.textSecondary).lineLimit(1)
            },
            VStack(alignment: .trailing, spacing: 0) {
                Text("$" + holding.price.spaced).font(.bodyXXL)
                Text(holding.pricePercent.signedPercent).font(.captionS).foregroundStyle(color(holding.pricePercent))
            },
            VStack(alignment: .trailing, spacing: 0) {
                Text((holding.pnl < 0 ? "-$" : "+$") + abs(holding.pnl).spaced).font(.bodyXXL)
                Text(holding.pnlPercent.signedPercent).font(.captionS)
            }
            .foregroundStyle(color(holding.pnlPercent))
        )
    }

    /// Symbol column flexes; the two numeric columns are 72pt wide with 24pt between, as in Figma.
    private func columns(_ symbol: some View, _ price: some View, _ pnl: some View) -> some View {
        HStack(alignment: .top, spacing: 24) {
            symbol.frame(maxWidth: .infinity, alignment: .leading)
            price.frame(minWidth: 72, alignment: .trailing)
            pnl.frame(minWidth: 72, alignment: .trailing)
        }
    }

    private func color(_ percent: Double) -> Color { percent < 0 ? .textAlert : .textAccent }
}

#Preview {
    ScrollView { HoldingsSection(holdings: MockData.holdings) }
}
