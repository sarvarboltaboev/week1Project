import SwiftUI

/// Figma 6367:67761.
struct ActivitySection: View {
    let activity: [Activity]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Recent Activity").font(.titleL)
                Spacer()
                Text("See All").font(.bodyL).foregroundStyle(Color.textAccent)
            }
            VStack(alignment: .leading, spacing: 16) {
                // ponytail: single static date group; group by day once activity has dates.
                Text("OCTOBER 3").font(.captionM).foregroundStyle(Color.textSecondary)
                ForEach(activity) { item in
                    if item.id != activity.first?.id {
                        Rectangle().fill(Color.borderPrimary).frame(height: 1)
                    }
                    row(item)
                }
            }
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .padding(.bottom, 32)
    }

    private func row(_ item: Activity) -> some View {
        HStack(spacing: 16) {
            if item.kind == .deposit {
                Image(systemName: "arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 40, height: 40)
                    .background(Color.surfaceGrey20, in: .circle)
            } else {
                // ponytail: one placeholder logo for every ticker, as in Figma; per-symbol logos come from the API later.
                Image("StockLogo").resizable().frame(width: 40, height: 40).clipShape(.circle)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(item.symbol).font(.bodyXXL)
                    if item.kind != .deposit {
                        Text(item.subtitle).font(.bodyS).foregroundStyle(Color.textSecondary)
                    }
                }
                HStack(spacing: 4) {
                    if item.kind != .deposit {
                        Text(item.kind == .sell ? "Sell" : "Buy")
                            .foregroundStyle(item.kind == .sell ? Color.textAlert : Color.textAccent)
                        Text(item.detail).foregroundStyle(Color.textSecondary)
                    } else {
                        Text(item.subtitle).foregroundStyle(Color.textSecondary)
                    }
                }
                .font(.captionM)
            }
            .lineLimit(1)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 0) {
                Text("$" + item.amount.spaced).font(.bodyXXL)
                HStack(spacing: 8) {
                    // ponytail: buys show as pending, matching the Figma sample; add a status field when real.
                    Image(systemName: item.kind == .buy ? "clock" : "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(item.kind == .buy ? Color.textWarning : Color.textAccent)
                        .frame(width: 16, height: 16)
                    Text(item.time).font(.captionM).foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

#Preview {
    ActivitySection(activity: MockData.activity)
}
