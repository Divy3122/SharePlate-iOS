#if DEBUG
import Foundation

/// In-memory repository used only by previews that need writable sample state.
final class DevelopmentSurplusRepository:
    SurplusRepository,
    CommunityOrganisationRepository,
    RescueClaimRepository,
    DonationRepository {

    private var listings: [UUID: SurplusListing] = [:]
    private var organisations: [UUID: CommunityOrganisation] = [:]
    private var claims: [UUID: RescueClaim] = [:]
    private var pickups: [UUID: DonationPickup] = [:]

    init(
        listing: SurplusListing? = nil,
        claim: RescueClaim? = nil,
        pickup: DonationPickup? = nil,
        organisation: CommunityOrganisation? = nil
    ) {
        if let listing { listings[listing.id] = listing }
        if let claim { claims[claim.id] = claim }
        if let pickup { pickups[pickup.id] = pickup }
        if let organisation { organisations[organisation.id] = organisation }
    }

    func saveSurplusListing(_ listing: SurplusListing) async throws {
        listings[listing.id] = listing
    }

    func surplusListing(id: UUID) async throws -> SurplusListing? {
        listings[id]
    }

    func surplusListings(forFoodBusinessID foodBusinessID: UUID) async throws -> [SurplusListing] {
        listings.values.filter { $0.foodBusinessID == foodBusinessID }
    }

    func availableSurplusListings(at date: Date) async throws -> [SurplusListing] {
        listings.values.filter { $0.status == .available && $0.pickupWindowEnd > date }
    }

    func saveCommunityOrganisation(_ organisation: CommunityOrganisation) async throws {
        organisations[organisation.id] = organisation
    }

    func communityOrganisation(id: UUID) async throws -> CommunityOrganisation? {
        organisations[id]
    }

    func saveRescueClaim(_ claim: RescueClaim) async throws {
        claims[claim.id] = claim
    }

    func rescueClaim(id: UUID) async throws -> RescueClaim? {
        claims[id]
    }

    func rescueClaims(forSurplusListingID surplusListingID: UUID) async throws -> [RescueClaim] {
        claims.values.filter { $0.surplusListingID == surplusListingID }
    }

    func rescueClaims(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [RescueClaim] {
        claims.values.filter { $0.communityOrganisationID == communityOrganisationID }
    }

    func donationPickup(forRescueClaimID rescueClaimID: UUID) async throws -> DonationPickup? {
        pickups.values.first { $0.rescueClaimID == rescueClaimID }
    }

    func saveDonationPickup(_ pickup: DonationPickup) async throws {
        pickups[pickup.id] = pickup
    }

    func donationPickups(forFoodBusinessID foodBusinessID: UUID) async throws -> [DonationPickup] {
        let listingIDs = Set(
            listings.values.filter { $0.foodBusinessID == foodBusinessID }.map(\.id)
        )
        let claimIDs = Set(
            claims.values.filter { listingIDs.contains($0.surplusListingID) }.map(\.id)
        )
        return pickups.values.filter { claimIDs.contains($0.rescueClaimID) }
    }

    func donationPickups(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [DonationPickup] {
        let claimIDs = Set(
            claims.values
                .filter { $0.communityOrganisationID == communityOrganisationID }
                .map(\.id)
        )
        return pickups.values.filter { claimIDs.contains($0.rescueClaimID) }
    }
}
#endif
