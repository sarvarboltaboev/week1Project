import SwiftUI

/// Top up, Withdraw, then Orders (or Transfer on the Cash tab). Orders turns orange with a badge while count > 0.
struct ActionTilesView: View {
    let isCash: Bool
    let ordersCount: Int
    let onTap: (String) -> Void

    var body: some View {
        HStack(spacing: 4) {
            tile("Top up", icon: "arrow.down")
            tile("Withdraw", icon: "arrow.up")
            if isCash {
                tile("Transfer", icon: "arrow.left.arrow.right")
            } else {
                tile("Orders", icon: "doc.text", badge: ordersCount)
            }
        }
        .padding(.horizontal, CardMetrics.margin)
        .padding(.vertical, 16)
    }

    private func tile(_ title: String, icon: String, badge: Int = 0) -> some View {
        Button { onTap(title) } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24, height: 24)
                    .overlay(alignment: .topLeading) {
                        if badge > 0 {
                            Text("\(badge)")
                                .font(.bodyL)
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 8)
                                .frame(height: 24)
                                .background(.white, in: .capsule)
                                .fixedSize()
                                // Badge's leading edge sits on the icon's trailing edge, 4pt above it.
                                .offset(x: 24, y: -4)
                        }
                    }
                Text(title).font(.captionM)
            }
            .foregroundStyle(badge > 0 ? Color.black : Color.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(badge > 0 ? Color.surfaceOrange30 : Color.surfaceGrey20, in: .rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .frame(height: 96)
    }
}
