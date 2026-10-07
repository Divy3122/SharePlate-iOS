import Foundation

protocol DonationRepository {
    /// Returns nil when collection has not been recorded for the rescue claim.
    func donationPickup(forRescueClaimID rescueClaimID: UUID) async throws -> DonationPickup?

    /// Creates or updates a completed pickup using its domain ID.
    func saveDonationPickup(_ pickup: DonationPickup) async throws

    /// Returns completed pickups linked through their rescue claims and listings to the business.
    func donationPickups(forFoodBusinessID foodBusinessID: UUID) async throws -> [DonationPickup]

    /// Returns completed pickups claimed by the specified community organisation.
    func donationPickups(
        forCommunityOrganisationID communityOrganisationID: UUID
    ) async throws -> [DonationPickup]
}
