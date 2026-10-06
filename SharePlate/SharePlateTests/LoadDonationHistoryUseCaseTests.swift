import Foundation
import Testing
@testable import SharePlate

@MainActor
struct LoadDonationHistoryUseCaseTests {
    @Test func completedDonationHistoryLoadsWithRelatedRescueDetails() async throws {
        let fixture = DonationHistoryFixture()
        fixture.seed(pickups: [fixture.olderPickup], claims: [fixture.olderClaim], listings: [fixture.olderListing])

        let entries = try await fixture.useCase.loadDonationHistory(
            foodBusinessID: fixture.businessID
        )

        #expect(entries == [
            DonationHistoryEntry(
                pickup: fixture.olderPickup,
                claim: fixture.olderClaim,
                listing: fixture.olderListing
            )
        ])
    }

    @Test func completedDonationHistoryIsOrderedNewestFirst() async throws {
        let fixture = DonationHistoryFixture()
        fixture.seed(
            pickups: [fixture.olderPickup, fixture.newerPickup],
            claims: [fixture.olderClaim, fixture.newerClaim],
            listings: [fixture.olderListing, fixture.newerListing]
        )

        let entries = try await fixture.useCase.loadDonationHistory(
            foodBusinessID: fixture.businessID
        )

        #expect(entries.map(\.pickup) == [fixture.newerPickup, fixture.olderPickup])
    }

    @Test func donationHistoryFailsWhenRelatedRescueClaimIsMissing() async {
        let fixture = DonationHistoryFixture()
        fixture.seed(pickups: [fixture.olderPickup], claims: [], listings: [fixture.olderListing])

        await #expect(throws: LoadDonationHistoryError.rescueClaimMissing) {
            try await fixture.useCase.loadDonationHistory(foodBusinessID: fixture.businessID)
        }
    }

    @Test func donationHistoryFailsWhenRelatedSurplusListingIsMissing() async {
        let fixture = DonationHistoryFixture()
        fixture.seed(pickups: [fixture.olderPickup], claims: [fixture.olderClaim], listings: [])

        await #expect(throws: LoadDonationHistoryError.surplusListingMissing) {
            try await fixture.useCase.loadDonationHistory(foodBusinessID: fixture.businessID)
        }
    }
}

@MainActor
private final class DonationHistoryFixture {
    let businessID = UUID()
    let donationRepository = MockDonationRepository()
    let claimRepository = MockRescueClaimRepository()
    let surplusRepository = MockSurplusRepository()

    lazy var olderListing = listing(title: "Yesterday's bakery surplus")
    lazy var newerListing = listing(title: "Today's bakery surplus")
    lazy var olderClaim = claim(listingID: olderListing.id, collectorName: "Alex")
    lazy var newerClaim = claim(listingID: newerListing.id, collectorName: "Morgan")
    lazy var olderPickup = pickup(claimID: olderClaim.id, collectedAt: Date(timeIntervalSince1970: 100))
    lazy var newerPickup = pickup(claimID: newerClaim.id, collectedAt: Date(timeIntervalSince1970: 200))

    lazy var useCase = LoadDonationHistoryUseCase(
        donationRepository: donationRepository,
        claimRepository: claimRepository,
        surplusRepository: surplusRepository
    )

    func seed(
        pickups: [DonationPickup],
        claims: [RescueClaim],
        listings: [SurplusListing]
    ) {
        donationRepository.pickupHistoryByBusinessID[businessID] = pickups
        claimRepository.claims = claims
        surplusRepository.listings = listings
    }

    private func listing(title: String) -> SurplusListing {
        SurplusListing(
            foodBusinessID: businessID,
            title: title,
            items: [
                SurplusItem(
                    foodName: "Bread",
                    quantity: 4,
                    quantityUnit: .pieces,
                    storageRequirement: .ambient
                )
            ],
            pickupAddress: "1 Test Street",
            pickupWindowStart: Date(timeIntervalSince1970: 50),
            pickupWindowEnd: Date(timeIntervalSince1970: 250),
            createdAt: Date(timeIntervalSince1970: 1),
            status: .collected
        )
    }

    private func claim(listingID: UUID, collectorName: String) -> RescueClaim {
        RescueClaim(
            surplusListingID: listingID,
            communityOrganisationID: UUID(),
            claimedAt: Date(timeIntervalSince1970: 25),
            plannedPickupAt: Date(timeIntervalSince1970: 75),
            collectorName: collectorName,
            collectorPhone: "0400 000 000",
            status: .collected
        )
    }

    private func pickup(claimID: UUID, collectedAt: Date) -> DonationPickup {
        DonationPickup(rescueClaimID: claimID, collectedAt: collectedAt)
    }
}
