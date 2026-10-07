import Foundation
@testable import SharePlate

@MainActor
final class MockSurplusRepository: SurplusRepository {
    var listings: [SurplusListing] = []
    var savedListings: [SurplusListing] = []

    func saveSurplusListing(_ listing: SurplusListing) async throws {
        savedListings.append(listing)
        listings.removeAll { $0.id == listing.id }
        listings.append(listing)
    }

    func surplusListing(id: UUID) async throws -> SurplusListing? {
        listings.first { $0.id == id }
    }

    func surplusListings(forFoodBusinessID foodBusinessID: UUID) async throws -> [SurplusListing] {
        listings.filter { $0.foodBusinessID == foodBusinessID }
    }

    func availableSurplusListings(at date: Date) async throws -> [SurplusListing] {
        listings.filter { $0.status == .available && $0.pickupWindowEnd > date }
    }
}

@MainActor
final class MockCommunityOrganisationRepository: CommunityOrganisationRepository {
    var organisations: [CommunityOrganisation] = []
    var savedOrganisations: [CommunityOrganisation] = []

    func saveCommunityOrganisation(_ organisation: CommunityOrganisation) async throws {
        savedOrganisations.append(organisation)
        organisations.removeAll { $0.id == organisation.id }
        organisations.append(organisation)
    }

    func communityOrganisation(id: UUID) async throws -> CommunityOrganisation? {
        organisations.first { $0.id == id }
    }
}

@MainActor
final class MockRescueClaimRepository: RescueClaimRepository {
    var claims: [RescueClaim] = []
    var savedClaims: [RescueClaim] = []

    func saveRescueClaim(_ claim: RescueClaim) async throws {
        savedClaims.append(claim)
        claims.removeAll { $0.id == claim.id }
        claims.append(claim)
    }

    func rescueClaim(id: UUID) async throws -> RescueClaim? {
        claims.first { $0.id == id }
    }

    func rescueClaims(forSurplusListingID surplusListingID: UUID) async throws -> [RescueClaim] {
        claims.filter { $0.surplusListingID == surplusListingID }
    }

    func rescueClaims(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [RescueClaim] {
        claims.filter { $0.communityOrganisationID == communityOrganisationID }
    }
}

@MainActor
final class MockDonationRepository: DonationRepository {
    var pickups: [DonationPickup] = []
    var savedPickups: [DonationPickup] = []
    // History is configured explicitly because pickups do not contain a business ID.
    var pickupHistoryByBusinessID: [UUID: [DonationPickup]] = [:]

    func donationPickup(forRescueClaimID rescueClaimID: UUID) async throws -> DonationPickup? {
        pickups.first { $0.rescueClaimID == rescueClaimID }
    }

    func saveDonationPickup(_ pickup: DonationPickup) async throws {
        savedPickups.append(pickup)
        pickups.removeAll { $0.id == pickup.id }
        pickups.append(pickup)
    }

    func donationPickups(forFoodBusinessID foodBusinessID: UUID) async throws -> [DonationPickup] {
        pickupHistoryByBusinessID[foodBusinessID] ?? []
    }
}
