import SwiftUI

/// How far a page sits from the viewport's leading edge, 0 (settled) … 1 (a full page away or more).
func pageProgress(offset: CGFloat, width: CGFloat) -> CGFloat {
    width > 0 ? min(abs(offset) / width, 1) : 0
}

/// Horizontal pager over pocket cards. Presentational: reports the settled page, never writes selection mid-scroll.
struct PocketCarousel: View {
    let pockets: [Pocket]
    let selectedID: Pocket.ID
    var collapse: CGFloat = 0
    let onSettle: (Pocket.ID) -> Void

    // Local, so programmatic scrolls passing intermediate pages never reach the store.
    @State private var position: Pocket.ID?
    @State private var chartHeld = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // ponytail: cards share PocketCard's height (fixed per collapse), so the pager is just as tall; top alignment
            // keeps it correct if a card ever gets shorter. Measure max card height if heights become dynamic.
            LazyHStack(alignment: .top, spacing: 0) {
                ForEach(pockets) { pocket in
                    PocketCard(pocket: pocket, collapse: collapse, onChartHeld: { chartHeld = $0 })
                        .padding(.horizontal, lerp(12, 0, collapse))
                        .containerRelativeFrame(.horizontal)
                        // Runs per frame off the scroll offset: no body re-evaluation, no animation.
                        // SwiftUI opacity fades the composited layer, so overlapping subviews don't show through.
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
