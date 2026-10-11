import SwiftUI

/// How far a page sits from the viewport's leading edge, 0 (settled) … 1 (a full page away or more).
func pageProgress(offset: CGFloat, width: CGFloat) -> CGFloat {
    width > 0 ? min(abs(offset) / width, 1) : 0
}

/// Horizontal pager, one card per tab. Presentational: reports the settled page, never writes selection mid-scroll.
struct PocketPager<Card: View>: View {
    let tabs: [PocketTab]
    let selectedID: String
    let collapse: CGFloat
    let onSettle: (String) -> Void
    /// Builds a tab's card; the closure reports whether a finger is down on its chart.
    @ViewBuilder let card: (PocketTab, @escaping (Bool) -> Void) -> Card

    // Local, so programmatic scrolls passing intermediate pages never reach the model.
    @State private var position: String?
    @State private var chartHeld = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // Top-aligned: a neighbour without the compare block is shorter than the selected card.
            LazyHStack(alignment: .top, spacing: 0) {
                ForEach(tabs) { tab in
                    card(tab) { chartHeld = $0 }
                        .padding(.horizontal, lerp(CardMetrics.margin, 0, collapse))
                        // One layer, so the fade doesn't let overlapping subviews show through.
                        .compositingGroup()
                        .containerRelativeFrame(.horizontal)
                        // Runs per frame off the scroll offset: no body re-evaluation, no animation.
                        .visualEffect { content, proxy in
                            let t = pageProgress(offset: proxy.frame(in: .scrollView).minX, width: proxy.size.width)
                            return content.scaleEffect(1 - 0.08 * t).opacity(1 - 0.4 * t)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $position)
        .scrollDisabled(chartHeld || collapse > 0)
        .onAppear { position = selectedID }
        .onChange(of: selectedID) { _, id in
            guard id != position else { return }
            withAnimation(.timingCurve(0.215, 0.61, 0.355, 1, duration: 0.3)) { position = id }
        }
        .onScrollPhaseChange { _, phase in
            if phase == .idle, let position { onSettle(position) }
        }
    }
}
