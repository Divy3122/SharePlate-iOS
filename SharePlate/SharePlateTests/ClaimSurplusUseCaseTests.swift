import Testing
@testable import SharePlate

@MainActor
struct ClaimSurplusUseCaseTests {
    @Test func claimSucceedsForVerifiedOrganisationAndAvailableSurplus() async throws {
        var fixture = FoodRescueFixture()
        fixture.listing.status = .available
        fixture.seed()
        let result = try await fixture.claimSurplus()
        #expect(result.status == .active)
        #expect(result.surplusListingID == fixture.listing.id)
        #expect(result.communityOrganisationID == fixture.organisation.id)
        #expect(result.claimedAt == fixture.now)
        #expect(result.plannedPickupAt == fixture.now.addingTimeInterval(600))
        #expect(result.collectorName == "Alex")
        #expect(result.collectorPhone == "0400000000")
        #expect(result.collectionNotes == "Use side door")
        #expect(fixture.claims.savedClaims == [result])
        var expected = fixture.listing
        expected.status = .claimed
        #expect(fixture.surplus.savedListings == [expected])
    }

    @Test func claimFailsWhenOrganisationIsNotVerified() async {
        var fixture = FoodRescueFixture()
        fixture.listing.status = .available
        fixture.organisation.isVerified = false
        fixture.seed()
        await #expect(throws: ClaimSurplusError.organisationNotVerified) {
            try await fixture.claimSurplus()
        }
        #expect(fixture.claims.savedClaims.isEmpty)
        #expect(fixture.surplus.savedListings.isEmpty)
        #expect(fixture.surplus.listings == [fixture.listing])
    }

    @Test func claimFailsWhenSurplusAlreadyHasActiveClaim() async {
        var fixture = FoodRescueFixture()
        fixture.listing.status = .available
        fixture.seed()
        fixture.claims.claims = [fixture.claim]
        await #expect(throws: ClaimSurplusError.surplusAlreadyClaimed) {
            try await fixture.claimSurplus()
        }
        #expect(fixture.claims.savedClaims.isEmpty)
        #expect(fixture.surplus.savedListings.isEmpty)
    }

    @Test func claimFailsWhenPickupWindowHasExpired() async {
        for endOffset in [0.0, -1.0] {
            var fixture = FoodRescueFixture()
            fixture.listing.status = .available
            fixture.listing.pickupWindowEnd = fixture.now.addingTimeInterval(endOffset)
            fixture.seed()
            await #expect(throws: ClaimSurplusError.pickupWindowExpired) {
                try await fixture.claimSurplus()
            }
            #expect(fixture.claims.savedClaims.isEmpty)
            #expect(fixture.surplus.savedListings.isEmpty)
        }
    }

    @Test func claimFailsWhenPlannedPickupTimeHasAlreadyPassed() async {
        var fixture = FoodRescueFixture()
        fixture.listing.status = .available
        fixture.seed()
        await #expect(throws: ClaimSurplusError.pickupTimeHasPassed) {
            try await fixture.claimSurplus(at: fixture.now.addingTimeInterval(-1))
        }
        #expect(fixture.claims.savedClaims.isEmpty)
        #expect(fixture.surplus.savedListings.isEmpty)
    }
}
