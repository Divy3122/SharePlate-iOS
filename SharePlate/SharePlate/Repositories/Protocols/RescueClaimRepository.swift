import Foundation

protocol RescueClaimRepository {
    /// Creates or updates a claim using its domain ID.
    func saveRescueClaim(_ claim: RescueClaim) async throws

    /// Returns nil when no claim has the given ID.
    func rescueClaim(id: UUID) async throws -> RescueClaim?

    /// Returns all claims for the listing, including cancelled claims.
    func rescueClaims(forSurplusListingID surplusListingID: UUID) async throws -> [RescueClaim]
}
