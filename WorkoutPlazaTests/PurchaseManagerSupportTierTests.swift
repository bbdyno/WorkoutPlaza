import Testing
@testable import WorkoutPlaza

struct PurchaseManagerSupportTierTests {

    @Test func supportProductIdentifiersStayStable() {
        #expect(
            PurchaseManager.SupportTier.allCases.map(\.productID) == [
                "com.workoutplaza.tip.item.small",
                "com.workoutplaza.tip.item.medium",
                "com.workoutplaza.tip.item.large"
            ]
        )
    }
}
