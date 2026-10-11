import SwiftUI

/// Recent activities list; "See all" once there is more than one row.
struct ActivitySectionView: View {
    let activities: [ActivityRow]
    let isBalanceVisible: Bool
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent activities").font(.titleL)
                Spacer()
                if activities.count > 1 {
                    Button("See all", action: onSeeAll).font(.bodyL).foregroundStyle(Color.textAccent)
                }
            }
            .padding(.bottom, 8)
            ForEach(Array(activities.enumerated()), id: \.offset) { index, item in
                if index > 0 { Rectangle().fill(Color.borderPrimary).frame(height: 1) }
                row(item)
            }
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private func row(_ item: ActivityRow) -> some View {
        HStack(spacing: 16) {
            Image(systemName: item.amount < 0 ? "arrow.up.right" : "arrow.down.left")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 40, height: 40)
                .background(Color.surfaceGrey20, in: .circle)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title).font(.bodyXXL)
                Text(item.subtitle).font(.captionM).foregroundStyle(Color.textSecondary)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text(isBalanceVisible && item.amount > 0 ? "+" + money(item.amount, visible: true)
                     : money(item.amount, visible: isBalanceVisible))
                    .font(.bodyXXL)
                    .foregroundStyle(isBalanceVisible && item.amount > 0 ? Color.textAccent : Color.textPrimary)
                Text(item.date, format: .dateTime.month(.abbreviated).day()).font(.captionM).foregroundStyle(Color.textSecondary)
            }
        }
    }
}
