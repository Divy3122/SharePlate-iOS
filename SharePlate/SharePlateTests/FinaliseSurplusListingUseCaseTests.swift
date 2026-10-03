import Foundation
import Testing
@testable import SharePlate

@MainActor
struct FinaliseSurplusListingUseCaseTests {
    @Test func finaliseSucceedsWhenEstimatedSurplusIsValid() async throws {
        let fixture = FoodRescueFixture()
        fixture.seed()
        let result = try await fixture.finalise()
        var expected = fixture.listing
        expected.status = .available
        expected.finalisedAt = fixture.now
        #expect(result == expected)
        #expect(fixture.surplus.savedListings == [expected])
    }

    @Test func finaliseFailsWhenNoSurplusItemsExist() async {
        var fixture = FoodRescueFixture()
        fixture.listing.items = []
        fixture.seed()
        await #expect(throws: FinaliseSurplusListingError.noSurplusItems) {
            try await fixture.finalise()
        }
        #expect(fixture.surplus.savedListings.isEmpty)
    }

    @Test func finaliseFailsWhenSurplusQuantityIsNotPositive() async {
        for quantity: Decimal in [0, -1] {
            var fixture = FoodRescueFixture()
            fixture.listing.items[0].quantity = quantity
            fixture.seed()
            await #expect(throws: FinaliseSurplusListingError.nonPositiveQuantity(foodName: "Bread")) {
                try await fixture.finalise()
            }
            #expect(fixture.surplus.savedListings.isEmpty)
        }
    }

    @Test func finaliseFailsWhenPickupWindowHasEnded() async {
        for endOffset: TimeInterval in [0, -1] {
            var fixture = FoodRescueFixture()
            fixture.listing.pickupWindowEnd = fixture.now.addingTimeInterval(endOffset)
            fixture.seed()
            await #expect(throws: FinaliseSurplusListingError.pickupWindowEnded) {
                try await fixture.finalise()
            }
            #expect(fixture.surplus.savedListings.isEmpty)
        }
    }
}
