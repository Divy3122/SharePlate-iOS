import Foundation
import Testing
@testable import SharePlate

@MainActor
struct LoadCommunityPickupsUseCaseTests {
    @Test func activeClaimsLoadWithRelatedListings() async throws {
        let fixture = CommunityPickupsFixture()
        let listing = fixture.listing(title: "Bakery rescue")
        let claim = fixture.claim(listing: listing, organisationID: fixture.organisationID)
        fixture.surplus.listings = [listing]
        fixture.claims.claims = [claim]

        let activities = try await fixture.useCase.loadActivePickups(
            forCommunityOrganisationID: fixture.organisationID
        )

        #expect(activities == [CommunityPickupActivity(listing: listing, claim: claim)])
    }

    @Test func claimsForAnotherOrganisationAreNotReturned() async throws {
        let fixture = CommunityPickupsFixture()
        let ownListing = fixture.listing(title: "Own pickup")
        let otherListing = fixture.listing(title: "Another organisation pickup")
        let ownClaim = fixture.claim(
            listing: ownListing,
            organisationID: fixture.organisationID
        )
        let otherClaim = fixture.claim(
            listing: otherListing,
            organisationID: UUID()
        )
        fixture.surplus.listings = [ownListing, otherListing]
        fixture.claims.claims = [ownClaim, otherClaim]

        let activities = try await fixture.useCase.loadActivePickups(
            forCommunityOrganisationID: fixture.organisationID
        )

        #expect(activities.map(\.claim.id) == [ownClaim.id])
    }

    @Test func collectedAndCancelledClaimsAreExcluded() async throws {
        let fixture = CommunityPickupsFixture()
        let activeListing = fixture.listing(title: "Active")
        let collectedListing = fixture.listing(title: "Collected")
        let cancelledListing = fixture.listing(title: "Cancelled")
        let activeClaim = fixture.claim(
            listing: activeListing,
            organisationID: fixture.organisationID,
            status: .active
        )
        let collectedClaim = fixture.claim(
            listing: collectedListing,
            organisationID: fixture.organisationID,
            status: .collected
        )
        let cancelledClaim = fixture.claim(
            listing: cancelledListing,
            organisationID: fixture.organisationID,
            status: .cancelled
        )
        fixture.surplus.listings = [activeListing, collectedListing, cancelledListing]
        fixture.claims.claims = [activeClaim, collectedClaim, cancelledClaim]

        let activities = try await fixture.useCase.loadActivePickups(
            forCommunityOrganisationID: fixture.organisationID
        )

        #expect(activities.map(\.claim.id) == [activeClaim.id])
    }

    @Test func pickupsAreOrderedByEarliestPlannedPickup() async throws {
        let fixture = CommunityPickupsFixture()
        let laterListing = fixture.listing(title: "Later")
        let earlierListing = fixture.listing(title: "Earlier")
        let laterClaim = fixture.claim(
            listing: laterListing,
            organisationID: fixture.organisationID,
            plannedPickupOffset: 3_600
        )
        let earlierClaim = fixture.claim(
            listing: earlierListing,
            organisationID: fixture.organisationID,
            plannedPickupOffset: 1_800
        )
        fixture.surplus.listings = [laterListing, earlierListing]
        fixture.claims.claims = [laterClaim, earlierClaim]

        let activities = try await fixture.useCase.loadActivePickups(
            forCommunityOrganisationID: fixture.organisationID
        )

        #expect(activities.map(\.claim.id) == [earlierClaim.id, laterClaim.id])
    }
}

@MainActor
private final class CommunityPickupsFixture {
    let organisationID = UUID()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let surplus = MockSurplusRepository()
    let claims = MockRescueClaimRepository()

    var useCase: LoadCommunityPickupsUseCase {
        LoadCommunityPickupsUseCase(
            claimRepository: claims,
            surplusRepository: surplus
        )
    }

    func listing(title: String) -> SurplusListing {
        SurplusListing(
            foodBusinessID: UUID(),
            title: title,
            items: [
                SurplusItem(
                    foodName: "Bread",
                    quantity: 4,
                    quantityUnit: .pieces,
                    storageRequirement: .ambient
                )
            ],
            pickupAddress: "1 Test Street, Ultimo",
            pickupWindowStart: now,
            pickupWindowEnd: now.addingTimeInterval(7_200),
            createdAt: now.addingTimeInterval(-600),
            finalisedAt: now,
            status: .claimed
        )
    }

    func claim(
        listing: SurplusListing,
        organisationID: UUID,
        status: RescueClaim.Status = .active,
        plannedPickupOffset: TimeInterval = 1_800
    ) -> RescueClaim {
        RescueClaim(
            surplusListingID: listing.id,
            communityOrganisationID: organisationID,
            claimedAt: now,
            plannedPickupAt: now.addingTimeInterval(plannedPickupOffset),
            collectorName: "Alex",
            collectorPhone: "0400000000",
            status: status
        )
    }
}
