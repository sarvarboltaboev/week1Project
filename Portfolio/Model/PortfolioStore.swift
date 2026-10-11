import Observation

/// Single source of truth for the home screen. Views read values and call methods; they own no business state.
@Observable
final class PortfolioStore {
    var pockets = MockData.pockets
    var holdings = MockData.holdings
    var activity = MockData.activity
    var selectedPocketID = MockData.pockets[0].id

    func select(_ id: Pocket.ID) {
        guard id != selectedPocketID else { return }
        selectedPocketID = id
    }
}
