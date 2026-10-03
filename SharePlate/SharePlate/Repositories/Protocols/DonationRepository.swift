import Foundation

protocol DonationRepository {
    /// Creates or updates a completed pickup using its domain ID.
    func saveDonationPickup(_ pickup: DonationPickup) async throws

    /// Returns completed pickups linked through their rescue claims and listings to the business.
    func donationPickups(forFoodBusinessID foodBusinessID: UUID) async throws -> [DonationPickup]
}
