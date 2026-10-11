import SwiftUI

/// One holdings group: grey heading, then managed rows and/or a Symbol / Current price / Market value table.
struct HoldingsSectionView: View {
    let section: HoldingsSection
    let isBalanceVisible: Bool
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(section.title.uppercased()).font(.captionM).foregroundStyle(Color.textSecondary)
                Spacer()
                if section.seeAll {
                    Button("See all", action: onSeeAll).font(.bodyL).foregroundStyle(Color.textAccent)
                }
            }
            ForEach(Array(section.managedRows.enumerated()), id: \.offset) { _, row in managedRow(row) }
            if !section.holdingRows.isEmpty {
                columns(Text("Symbol"), Text("Current price"), Text("Market value"))
                    .font(.captionS)
                    .foregroundStyle(Color.textSecondary)
                ForEach(Array(section.holdingRows.enumerated()), id: \.offset) { index, row in
                    if index > 0 { Rectangle().fill(Color.borderPrimary).frame(height: 1) }
                    holdingRow(row)
                }
            }
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func managedRow(_ row: ManagedRow) -> some View {
        HStack(spacing: 16) {
            Image(systemName: row.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: 0xC4EE8B))
                .frame(width: 40, height: 40)
                .background(Color(hex: 0x3D3D3D), in: .circle)
            VStack(alignment: .leading, spacing: 0) {
                Text(row.title).font(.bodyXXL)
                Text(row.subtitle).font(.captionM).foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(money(row.value, visible: isBalanceVisible)).font(.bodyXXL)
        }
    }

    private func holdingRow(_ row: HoldingRow) -> some View {
        columns(
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(row.ticker).font(.bodyXXL)
                    Text("x\(row.quantity.formatted())").font(.captionM).foregroundStyle(Color.textSecondary)
                }
                Text(row.name).font(.captionM).foregroundStyle(Color.textSecondary).lineLimit(1)
            },
            Text(money(row.price, visible: isBalanceVisible)).font(.bodyXXL),
            Text(money(row.value, visible: isBalanceVisible)).font(.bodyXXL)
        )
    }

    /// Symbol column flexes; the two numeric columns are at least 72pt wide with 24pt between.
    private func columns(_ symbol: some View, _ price: some View, _ value: some View) -> some View {
        HStack(alignment: .top, spacing: 24) {
            symbol.frame(maxWidth: .infinity, alignment: .leading)
            price.frame(minWidth: 72, alignment: .trailing)
            value.frame(minWidth: 72, alignment: .trailing)
        }
    }
}
