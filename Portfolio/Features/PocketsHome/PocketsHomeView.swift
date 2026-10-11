import SwiftUI

/// Pockets home screen. Composes the sections; every data decision lives in `PocketsHomeModel`.
struct PocketsHomeView: View {
    @State private var model = PocketsHomeModel()
    @State private var scrollY: CGFloat = 0
    @State private var path: [String] = []

    private var tab: PocketTab { model.selectedTab }
    private var expanded: CGFloat { CardMetrics.expandedHeight(compare: model.showsCompare) }
    private var range: CGFloat { CardMetrics.collapseRange(compare: model.showsCompare) }
    /// Scrolling first eats the 16pt gap, then the card collapses, then the chips block folds.
    private var collapse: CGFloat { collapseProgress(offset: scrollY, start: CardMetrics.gap, distance: range) }
    private var chipsFold: CGFloat {
        collapseProgress(offset: scrollY, start: CardMetrics.gap + range, distance: CardMetrics.chipsBlock)
    }
    /// How far the header is held at the top while it shrinks; it scrolls away normally after that.
    private var pin: CGFloat { min(max(scrollY - CardMetrics.gap, 0), range + CardMetrics.chipsBlock) }
    /// Ground grey rises to the card colour with the same progress, so card, page and bar become one surface.
    private var ground: Color { .surfaceGrey30.mix(with: .card, by: collapse) }
    private var showsTiles: Bool { tab.kind != .managed || tab.card.kind == .promo }
    private var showsDetails: Bool { (tab.kind == .managed || tab.kind == .pocket) && tab.card.kind != .promo }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    header.padding(.top, CardMetrics.gap).zIndex(1)
                    if showsTiles {
                        ActionTilesView(isCash: tab.kind == .cash, ordersCount: DummyData.ordersCount) { path.append($0) }
                    }
                    if showsDetails { detailsRow }
                    if tab.hasHoldings {
                        Section {
                            ForEach(Array(tab.sections.enumerated()), id: \.offset) { _, section in
                                HoldingsSectionView(section: section, isBalanceVisible: model.isBalanceVisible) {
                                    path.append(section.title)
                                }
                            }
                        } header: {
                            Text("Holdings")
                                .font(.titleL)
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.card)
                        }
                    }
                    ActivitySectionView(activities: model.activities, isBalanceVisible: model.isBalanceVisible) {
                        path.append("Recent activities")
                    }
                    .padding(.bottom, 16)
                }
                .background(alignment: .top) { groundGradient }
                .background(Color.card)
            }
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { scrollY = $1 }
            .refreshable { await model.refresh() }
            // Ground above the content (pull-down), card colour below for the bottom bounce.
            .background { VStack(spacing: 0) { ground; Color.card }.ignoresSafeArea() }
            .safeAreaInset(edge: .top, spacing: 0) { navBar }
            .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { title in
                Text(title).font(.titleL).navigationTitle(title)
            }
        }
        // SwiftUI has no backdrop sigma; blurring the content itself matches a 4pt backdrop blur.
        .blur(radius: showsHint ? 4 : 0)
        // Outside the stack so the hint also covers the tab bar.
        .overlay {
            if showsHint {
                SwipeHintOverlay { withAnimation { model.hasSeenSwipeHint = true } }.transition(.opacity)
            }
        }
    }

    private var showsHint: Bool { !model.hasSeenSwipeHint && model.tabs.count > 1 }

    /// Card pager then chips block, held at the top while it shrinks (a non-pinned persistent header).
    /// Layout reserves the full height; the header is offset down by `pin` and shrinks by the same amount,
    /// so its bottom edge tracks the reserved slot: no jump, no layout feedback loop.
    private var header: some View {
        Color.clear
            .frame(height: expanded + CardMetrics.chipsBlock)
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    PocketPager(tabs: model.tabs, selectedID: model.selectedTabID, collapse: collapse, onSettle: model.select) { tab, onChartHeld in
                        card(tab, onChartHeld: onChartHeld)
                    }
                    .frame(height: lerp(expanded, CardMetrics.collapsedHeight, collapse), alignment: .top)

                    PocketChipsView(tabs: model.tabs, selectedID: model.selectedTabID, onSelect: model.select)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                        .frame(height: CardMetrics.chipsBlock * (1 - chipsFold), alignment: .top)
                        .clipped()
                        .opacity(1 - chipsFold)
                }
                .offset(y: pin)
            }
    }

    private func card(_ tab: PocketTab, onChartHeld: @escaping (Bool) -> Void) -> some View {
        let isSelected = tab.id == model.selectedTabID
        let activeTab = isSelected ? model.activeCardTab : 0
        let compare = tab.card.kind == .valueChart && activeTab == 1
        return PocketCardView(
            card: tab.card,
            collapse: collapse,
            height: lerp(CardMetrics.expandedHeight(compare: compare), CardMetrics.collapsedHeight, collapse),
            showsMenu: tab.kind == .cash || tab.kind == .pocket,
            activeTab: activeTab,
            periodIndex: model.periodIndex,
            isBalanceVisible: model.isBalanceVisible,
            benchmark: model.benchmark,
            onCardTab: { index in withAnimation(.easeOut(duration: 0.25)) { model.setCardTab(index) } },
            onPeriod: model.setPeriod,
            onToggleBalance: model.toggleBalance,
            onBenchmark: model.setBenchmark,
            onDetails: { path.append(tab.title) },
            onChartHeld: onChartHeld
        )
    }

    /// Grey holds until 50pt above the card's bottom edge and is fully the card colour 110pt below it.
    private var groundGradient: some View {
        let bottom = CardMetrics.gap + expanded
        let height = bottom + 110
        return LinearGradient(
            stops: [.init(color: ground, location: (bottom - 50) / height), .init(color: .card, location: 1)],
            startPoint: .top, endPoint: .bottom
        )
        .frame(height: height)
    }

    private var navBar: some View {
        HStack(spacing: 16) {
            Image("Avatar").resizable().scaledToFill().frame(width: 40, height: 40).clipShape(.circle)
            Spacer()
            HStack(spacing: 24) {
                Image("Diamond").resizable().frame(width: 40, height: 40)
                Image(systemName: "magnifyingglass")
                Image(systemName: "bell")
            }
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background { ground.ignoresSafeArea(edges: .top) }
    }

    private var detailsRow: some View {
        Button { path.append("\(tab.title) details") } label: {
            HStack {
                Text("Details").font(.bodyXXL)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.textPrimary)
            .padding(24)
            .background(Color.surfaceGrey20, in: .rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, CardMetrics.margin)
        .padding(.vertical, 8)
    }

    // ponytail: static bar with Home selected; becomes a TabView once other tabs have screens.
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(
                ["Home", "Watchlist", "Invest", "Insights", "Activity"], id: \.self
            ) { title in
                VStack(spacing: 4) {
                    // Figma tab icons (Component 14), template-rendered so they take the label colour.
                    Image("Tab" + title).resizable().frame(width: 24, height: 24)
                    Text(title).font(.captionS)
                }
                .foregroundStyle(title == "Home" ? Color.textPrimary : Color.textSecondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .background(Color.navbarBackground)
    }
}

#Preview {
    PocketsHomeView()
}
