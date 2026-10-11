import SwiftUI

/// Home / portfolio screen (Figma 6367:67475).
struct HomeView: View {
    @State private var store = PortfolioStore()
    @State private var scrollY: CGFloat = 0
    @State private var toolbarHeight: CGFloat = 0
    @AppStorage("didSeeSwipeHint") private var didSeeSwipeHint = false

    /// How far the card has been pushed past the viewport top; it pins there by offsetting down by this much.
    private var pin: CGFloat { max(0, scrollY - toolbarHeight) }
    private var collapse: CGFloat {
        collapseProgress(offset: pin, start: 0, distance: PocketCard.expandedHeight - PocketCard.collapsedHeight)
    }
    /// Page grey rises to white with the same progress, meeting the white header.
    private var pageGrey: Color { .surfaceGrey30.mix(with: .white, by: collapse) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                toolbar.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { toolbarHeight = $0 }
                // Layout always reserves the expanded height; the pager draws over it. While pinned it shrinks exactly
                // as fast as we scroll, so its bottom tracks this spacer's bottom: no jump, no layout feedback loop.
                Color.clear.frame(height: PocketCard.expandedHeight)
                    .overlay(alignment: .top) {
                        PocketCarousel(
                            pockets: store.pockets, selectedID: store.selectedPocketID,
                            collapse: collapse, onSettle: store.select
                        )
                        .frame(height: lerp(PocketCard.expandedHeight, PocketCard.collapsedHeight, collapse))
                        // Covers content scrolling up into the status bar above the pinned header.
                        .background(alignment: .top) { pageGrey.frame(height: pin).offset(y: -pin) }
                        .offset(y: pin)
                    }
                    .zIndex(1)
                pocketChips.padding(.top, 22)
                actions.padding(.top, 31)
                HoldingsSection(holdings: store.holdings)
                realizedPnL
                ActivitySection(activity: store.activity)
            }
            .background(alignment: .top) {
                // Figma "gradient" 6367:67477: grey fading to white behind cards, chips and actions.
                LinearGradient(
                    stops: [.init(color: pageGrey, location: 0.575), .init(color: .white, location: 0.78)],
                    startPoint: .top, endPoint: .bottom
                )
                // Figma's 811pt layer starts at the screen top; ours starts below the status bar, hence 770 / shifted stops.
                .frame(height: 770)
            }
            .background { Color.white }
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { scrollY = $1 }
        // Grey above the content (status bar, pull-down), white below for bottom bounce.
        .background { VStack(spacing: 0) { pageGrey; Color.white }.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        // SwiftUI has no backdrop sigma; blurring the content itself matches Flutter's blur(4) far closer than
        // .ultraThinMaterial, which smears the screen beyond recognition.
        .blur(radius: didSeeSwipeHint ? 0 : 4)
        // After safeAreaInset so the hint also covers the tab bar.
        .overlay {
            if !didSeeSwipeHint {
                SwipeHintOverlay { withAnimation { didSeeSwipeHint = true } }.transition(.opacity)
            }
        }
    }

    private var toolbar: some View {
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
        .padding(.vertical, 16)
    }

    private var pocketChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.pockets) { pocket in
                    let selected = pocket.id == store.selectedPocketID
                    Button { store.select(pocket.id) } label: {
                        // ponytail: chip label = title minus " Pockets"; add a shortTitle to Pocket if copy diverges.
                        Text(pocket.title.replacingOccurrences(of: " Pockets", with: ""))
                            .font(.captionM)
                            .foregroundStyle(selected ? Color.white : Color.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(selected ? Color.textPrimary : .clear, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private var actions: some View {
        HStack(spacing: 4) {
            action("Deposit", icon: "arrow.down", background: .surfaceGrey20)
            action("Withdraw", icon: "arrow.up", background: .surfaceGrey20)
            action("Orders", icon: "doc.text", background: .surfaceOrange30, badge: 9)
        }
    }

    private func action(_ title: String, icon: String, background: Color, badge: Int? = nil) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
                .overlay(alignment: .topLeading) {
                    if let badge {
                        Text("\(badge)")
                            .font(.bodyL)
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
        .foregroundStyle(Color.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(background, in: .rect(cornerRadius: 24))
    }

    private var realizedPnL: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Realized PnL").font(.bodyXXL)
                Text("Returns & purification details from sold stocks")
                    .font(.bodyS)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(Color.textPrimary)
        .padding(24)
        .background(Color.surfaceGrey20, in: .rect(cornerRadius: 24))
    }

    // ponytail: static bar with Home selected; becomes a TabView once other tabs have screens.
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(
                [("Home", "house"), ("Watchlist", "star.square"), ("Invest", "chart.bar"),
                 ("Insights", "text.below.photo"), ("Activity", "clock.arrow.circlepath")],
                id: \.0
            ) { title, icon in
                VStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 18, weight: .medium)).frame(width: 24, height: 24)
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
    HomeView()
}
