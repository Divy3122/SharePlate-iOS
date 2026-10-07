import Foundation
import Testing
@testable import SharePlate

@MainActor
struct CoreDataSharePlateRepositoryTests {
    @Test func surplusListingRoundTripsImportantFieldsAndItems() async throws {
        let fixture = try await makeFixture()
        let listing = fixture.listing(status: .estimated, endOffset: 3_600)

        try await fixture.repository.saveSurplusListing(listing)
        let loaded = try await fixture.repository.surplusListing(id: listing.id)

        #expect(loaded == listing)
    }

    @Test func availableSurplusPredicateExcludesUnavailableAndExpiredListings() async throws {
        let fixture = try await makeFixture()
        let available = fixture.listing(status: .available, endOffset: 3_600)
        let estimated = fixture.listing(status: .estimated, endOffset: 3_600)
        let expired = fixture.listing(status: .available, endOffset: -60)

        try await fixture.repository.saveSurplusListing(available)
        try await fixture.repository.saveSurplusListing(estimated)
        try await fixture.repository.saveSurplusListing(expired)

        let results = try await fixture.repository.availableSurplusListings(at: fixture.now)

        #expect(results.map(\.id) == [available.id])
    }

    @Test func rescueClaimRoundTripsThroughListingRelationship() async throws {
        let fixture = try await makeFixture()
        let listing = fixture.listing(status: .claimed, endOffset: 3_600)
        try await fixture.repository.saveSurplusListing(listing)
        let claim = fixture.claim(for: listing)

        try await fixture.repository.saveRescueClaim(claim)
        let claims = try await fixture.repository.rescueClaims(
            forSurplusListingID: listing.id
        )

        #expect(claims == [claim])
    }

    @Test func rescueClaimsCanBeFetchedByCommunityOrganisation() async throws {
        let fixture = try await makeFixture()
        let ownListing = fixture.listing(status: .claimed, endOffset: 3_600)
        let otherListing = fixture.listing(status: .claimed, endOffset: 7_200)
        try await fixture.repository.saveSurplusListing(ownListing)
        try await fixture.repository.saveSurplusListing(otherListing)
        let ownClaim = fixture.claim(for: ownListing)
        try await fixture.repository.saveRescueClaim(ownClaim)

        let otherOrganisation = CommunityOrganisation(
            organisationName: "Another Charity",
            suburb: "Glebe",
            isVerified: true,
            contactName: "Taylor",
            contactPhone: "0400 999 999",
            serviceArea: "Inner West"
        )
        try await fixture.repository.saveCommunityOrganisation(otherOrganisation)
        let otherClaim = RescueClaim(
            surplusListingID: otherListing.id,
            communityOrganisationID: otherOrganisation.id,
            claimedAt: fixture.now,
            plannedPickupAt: fixture.now.addingTimeInterval(1_800),
            collectorName: "Taylor",
            collectorPhone: "0400 999 999"
        )
        try await fixture.repository.saveRescueClaim(otherClaim)

        let claims = try await fixture.repository.rescueClaims(
            forCommunityOrganisationID: fixture.organisation.id
        )

        #expect(claims == [ownClaim])
    }

    @Test func donationPickupLoadsThroughBusinessRelationship() async throws {
        let fixture = try await makeFixture()
        let listing = fixture.listing(status: .collected, endOffset: 3_600)
        try await fixture.repository.saveSurplusListing(listing)
        let claim = fixture.claim(for: listing, status: .collected)
        try await fixture.repository.saveRescueClaim(claim)
        let pickup = DonationPickup(
            rescueClaimID: claim.id,
            collectedAt: fixture.now,
            handoverNotes: "Collected in reusable crates"
        )

        try await fixture.repository.saveDonationPickup(pickup)
        let pickups = try await fixture.repository.donationPickups(
            forFoodBusinessID: fixture.business.id
        )

        #expect(pickups == [pickup])
    }

    @Test func donationPickupsAreRestrictedToCommunityOrganisationRelationship() async throws {
        let fixture = try await makeFixture()
        let ownListing = fixture.listing(status: .collected, endOffset: 3_600)
        let otherListing = fixture.listing(status: .collected, endOffset: 7_200)
        try await fixture.repository.saveSurplusListing(ownListing)
        try await fixture.repository.saveSurplusListing(otherListing)

        let ownClaim = fixture.claim(for: ownListing, status: .collected)
        try await fixture.repository.saveRescueClaim(ownClaim)

        let otherOrganisation = CommunityOrganisation(
            organisationName: "Other Food Relief",
            suburb: "Glebe",
            isVerified: true,
            contactName: "Taylor",
            contactPhone: "0400 999 999",
            serviceArea: "Inner West"
        )
        try await fixture.repository.saveCommunityOrganisation(otherOrganisation)
        let otherClaim = RescueClaim(
            surplusListingID: otherListing.id,
            communityOrganisationID: otherOrganisation.id,
            claimedAt: fixture.now,
            plannedPickupAt: fixture.now.addingTimeInterval(1_800),
            collectorName: "Taylor",
            collectorPhone: "0400 999 999",
            status: .collected
        )
        try await fixture.repository.saveRescueClaim(otherClaim)

        let ownPickup = DonationPickup(
            rescueClaimID: ownClaim.id,
            collectedAt: fixture.now
        )
        let otherPickup = DonationPickup(
            rescueClaimID: otherClaim.id,
            collectedAt: fixture.now.addingTimeInterval(60)
        )
        try await fixture.repository.saveDonationPickup(ownPickup)
        try await fixture.repository.saveDonationPickup(otherPickup)

        let pickups = try await fixture.repository.donationPickups(
            forCommunityOrganisationID: fixture.organisation.id
        )

        #expect(pickups == [ownPickup])
    }

    private func makeFixture() async throws -> CoreDataRepositoryFixture {
        let stack = CoreDataStack(inMemory: true)
        try await stack.load()
        let repository = CoreDataSharePlateRepository(stack: stack)
        let business = FoodBusiness(
            businessName: "Neighbourhood Bakery",
            suburb: "Ultimo",
            contactName: "Sam Lee",
            contactPhone: "0400 111 222",
            contactEmail: "sam@example.com",
            pickupAddress: "1 Local Street, Ultimo",
            pickupInstructions: "Use the side entrance"
        )
        let organisation = CommunityOrganisation(
            organisationName: "Inner Sydney Food Relief",
            suburb: "Ultimo",
            isVerified: true,
            contactName: "Alex Morgan",
            contactPhone: "0400 123 456",
            serviceArea: "Inner Sydney"
        )
        try await repository.saveFoodBusiness(business)
        try await repository.saveCommunityOrganisation(organisation)
        return CoreDataRepositoryFixture(
            stack: stack,
            repository: repository,
            business: business,
            organisation: organisation
        )
    }
}

@MainActor
private struct CoreDataRepositoryFixture {
    let stack: CoreDataStack
    let repository: CoreDataSharePlateRepository
    let business: FoodBusiness
    let organisation: CommunityOrganisation
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func listing(
        status: SurplusListing.Status,
        endOffset: TimeInterval
    ) -> SurplusListing {
        SurplusListing(
            foodBusinessID: business.id,
            title: "Bakery surplus",
            items: [
                SurplusItem(
                    foodName: "Sourdough loaves",
                    foodDescription: "Baked this morning",
                    quantity: 6,
                    quantityUnit: .pieces,
                    storageRequirement: .ambient,
                    allergenInformation: "Contains gluten",
                    useByDate: now.addingTimeInterval(86_400)
                )
            ],
            pickupAddress: business.pickupAddress,
            pickupInstructions: business.pickupInstructions,
            pickupWindowStart: now.addingTimeInterval(-600),
            pickupWindowEnd: now.addingTimeInterval(endOffset),
            createdAt: now.addingTimeInterval(-1_200),
            finalisedAt: status == .estimated ? nil : now.addingTimeInterval(-900),
            status: status
        )
    }

    func claim(
        for listing: SurplusListing,
        status: RescueClaim.Status = .active
    ) -> RescueClaim {
        RescueClaim(
            surplusListingID: listing.id,
            communityOrganisationID: organisation.id,
            claimedAt: now.addingTimeInterval(-300),
            plannedPickupAt: now.addingTimeInterval(600),
            collectorName: "Alex Morgan",
            collectorPhone: "0400 123 456",
            collectionNotes: "Bringing reusable crates",
            status: status
        )
    }
}
