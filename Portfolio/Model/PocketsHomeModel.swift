import Foundation
import Observation

/// Single source of truth for the home screen. Views read values and call methods; they own no business state.
@Observable
final class PocketsHomeModel {
    private static let hintKey = "hasSeenSwipeHint"

    var tabs = DummyData.tabs()
    var activities = DummyData.activities
    var selectedTabID = "all"
    /// 0 = Value / Cash balance, 1 = Performance / Cards.
    var activeCardTab = 0
    var periodIndex = 0
    var isBalanceVisible = true
    var benchmark: String?
    var hasSeenSwipeHint = UserDefaults.standard.bool(forKey: hintKey) {
        didSet { UserDefaults.standard.set(hasSeenSwipeHint, forKey: Self.hintKey) }
    }

    var selectedTab: PocketTab { tabs.first { $0.id == selectedTabID } ?? tabs[0] }
    var period: String { DummyData.periods[periodIndex] }
    /// Performance tab of a chart card: the card grows by the compare block.
    var showsCompare: Bool { selectedTab.card.kind == .valueChart && activeCardTab == 1 }

    func select(_ id: String) {
        guard id != selectedTabID else { return }
        selectedTabID = id
        activeCardTab = 0
    }

    func toggleBalance() { isBalanceVisible.toggle() }
    func setPeriod(_ index: Int) { periodIndex = index }
    func setCardTab(_ index: Int) { activeCardTab = index }
    func setBenchmark(_ name: String?) { benchmark = name }

    func refresh() async {
        try? await Task.sleep(for: .milliseconds(800))
        tabs = DummyData.tabs()
    }
}
