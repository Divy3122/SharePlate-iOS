import Testing
@testable import SharePlate

@MainActor
struct CompleteDonationPickupUseCaseTests {
    @Test func completePickupSucceedsForActiveClaimAndClaimedSurplus() async throws {
        var fixture = FoodRescueFixture()
        fixture.listing.status = .claimed
        fixture.seed()
        fixture.claims.claims = [fixture.claim]
        let result = try await fixture.completePickup()
        #expect(result.rescueClaimID == fixture.claim.id)
        #expect(result.collectedAt == fixture.now)
        #expect(result.handoverNotes == "Collected by Alex")
        #expect(fixture.donations.savedPickups == [result])
        var expectedClaim = fixture.claim
        expectedClaim.status = .collected
        var expectedListing = fixture.listing
        expectedListing.status = .collected
        #expect(fixture.claims.savedClaims == [expectedClaim])
        #expect(fixture.surplus.savedListings == [expectedListing])
    }

    @Test func completePickupFailsWhenCollectionAlreadyRecorded() async {
        var fixture = FoodRescueFixture()
        fixture.listing.status = .claimed
        fixture.seed()
        fixture.claims.claims = [fixture.claim]
        let existing = DonationPickup(rescueClaimID: fixture.claim.id, collectedAt: fixture.now)
        fixture.donations.pickups = [existing]
        await #expect(throws: CompleteDonationPickupError.pickupAlreadyCompleted) {
            try await fixture.completePickup()
        }
        #expect(fixture.donations.savedPickups.isEmpty)
        #expect(fixture.donations.pickups == [existing])
        #expect(fixture.claims.savedClaims.isEmpty)
        #expect(fixture.surplus.savedListings.isEmpty)
    }

    @Test func completePickupFailsWhenRescueClaimIsNotActive() async {
        for status in [RescueClaim.Status.cancelled, .collected] {
            var fixture = FoodRescueFixture()
            fixture.listing.status = .claimed
            fixture.claim.status = status
            fixture.seed()
            fixture.claims.claims = [fixture.claim]
            await #expect(throws: CompleteDonationPickupError.claimIsNotActive) {
                try await fixture.completePickup()
            }
            #expect(fixture.donations.savedPickups.isEmpty)
            #expect(fixture.claims.savedClaims.isEmpty)
            #expect(fixture.surplus.savedListings.isEmpty)
        }
    }

    @Test func completePickupFailsWhenSurplusIsNotClaimed() async {
        for status in [SurplusListing.Status.estimated, .available, .collected, .expired, .cancelled] {
            var fixture = FoodRescueFixture()
            fixture.listing.status = status
            fixture.seed()
            fixture.claims.claims = [fixture.claim]
            await #expect(throws: CompleteDonationPickupError.surplusIsNotClaimed) {
                try await fixture.completePickup()
            }
            #expect(fixture.donations.savedPickups.isEmpty)
            #expect(fixture.claims.savedClaims.isEmpty)
            #expect(fixture.surplus.savedListings.isEmpty)
        }
    }
}
