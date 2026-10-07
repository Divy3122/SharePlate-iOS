import Foundation
@testable import SharePlate

@MainActor
struct FoodRescueFixture {

    let now = Date(timeIntervalSince1970: 1_800_000_000)

    let surplus = MockSurplusRepository()
    let organisations = MockCommunityOrganisationRepository()
    let claims = MockRescueClaimRepository()
    let donations = MockDonationRepository()

    var listing: SurplusListing
    var organisation: CommunityOrganisation
    var claim: RescueClaim

    init() {
        organisation = CommunityOrganisation(
            organisationName: "Community Pantry",
            suburb: "Ultimo",
            isVerified: true,
            contactName: "Alex",
            contactPhone: "0400000000",
            serviceArea: "Sydney"
        )

        listing = SurplusListing(
            foodBusinessID: UUID(),
            title: "Bakery surplus",
            items: [
                SurplusItem(
                    foodName: "Bread",
                    quantity: 4,
                    quantityUnit: .pieces,
                    storageRequirement: .ambient
                )
            ],
            pickupAddress: "1 Test Street, Ultimo",
            pickupWindowStart: now.addingTimeInterval(-3600),
            pickupWindowEnd: now.addingTimeInterval(3600),
            createdAt: now.addingTimeInterval(-7200)
        )

        claim = RescueClaim(
            surplusListingID: listing.id,
            communityOrganisationID: organisation.id,
            claimedAt: now.addingTimeInterval(-300),
            plannedPickupAt: now.addingTimeInterval(600),
            collectorName: "Alex",
            collectorPhone: "0400000000"
        )
    }

    func seed() {
        surplus.listings = [listing]
        organisations.organisations = [organisation]
    }

    func finalise(
        pickupAddress: String? = nil
    ) async throws -> SurplusListing {

        try await FinaliseSurplusListingUseCase(
            surplusRepository: surplus,
            currentDate: { now }
        )
        .finaliseSurplusListing(
            id: listing.id,
            pickupAddress: pickupAddress
        )
    }

    func claimSurplus(
        at pickupTime: Date? = nil
    ) async throws -> RescueClaim {

        try await ClaimSurplusUseCase(
            surplusRepository: surplus,
            organisationRepository: organisations,
            claimRepository: claims,
            currentDate: { now }
        )
        .claimSurplus(
            surplusListingID: listing.id,
            communityOrganisationID: organisation.id,
            plannedPickupAt:
                pickupTime ?? now.addingTimeInterval(600),
            collectorName: "Alex",
            collectorPhone: "0400000000",
            collectionNotes: "Use side door"
        )
    }

    func completePickup() async throws -> DonationPickup {

        try await CompleteDonationPickupUseCase(
            claimRepository: claims,
            donationRepository: donations,
            surplusRepository: surplus,
            currentDate: { now }
        )
        .completeDonationPickup(
            rescueClaimID: claim.id,
            handoverNotes: "Collected by Alex"
        )
    }
}
