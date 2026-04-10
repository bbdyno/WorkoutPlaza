import Testing
@testable import WorkoutPlaza

struct PurchaseManagerSupportTierTests {

    @Test func supportProductIdentifiersStayStable() {
        #expect(
            PurchaseManager.SupportTier.allCases.map(\.productID) == [
                "com.workoutplaza.tip.small",
                "com.workoutplaza.tip.medium",
                "com.workoutplaza.tip.large"
            ]
        )
    }
}
