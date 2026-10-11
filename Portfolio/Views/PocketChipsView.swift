import SwiftUI

/// "All" pinned on the left; the other chips scroll behind it. Selection recentres only this row.
struct PocketChipsView: View {
    let tabs: [PocketTab]
    let selectedID: String
    let onSelect: (String) -> Void

    @State private var position: String?

    var body: some View {
        HStack(spacing: 0) {
            if let all = tabs.first {
                chip(all)
                    .padding(.leading, CardMetrics.margin)
                    .padding(.trailing, 8)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabs.dropFirst()) { chip($0) }
                }
                .padding(.trailing, CardMetrics.margin)
                .scrollTargetLayout()
            }
            // ponytail: chips clip at All's edge rather than sliding under an opaque All, which would need to repaint the ground gradient.
            .scrollPosition(id: $position, anchor: .center)
        }
        .frame(height: 40)
        .onChange(of: selectedID) { _, id in
            withAnimation(.easeOut(duration: 0.25)) { position = id == tabs.first?.id ? tabs.dropFirst().first?.id : id }
        }
    }

    private func chip(_ tab: PocketTab) -> some View {
        let selected = tab.id == selectedID
        return Button { onSelect(tab.id) } label: {
            Text(tab.title)
                .font(.bodyM)
                .foregroundStyle(selected ? Color.card : Color.textPrimary)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(selected ? Color.textPrimary : Color.surfaceGrey20, in: .capsule)
        }
        .buttonStyle(.plain)
        .id(tab.id)
    }
}
