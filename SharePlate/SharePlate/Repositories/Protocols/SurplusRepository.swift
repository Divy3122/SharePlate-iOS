import Foundation

protocol SurplusRepository {
    /// Creates or updates a listing using its domain ID.
    func saveSurplusListing(_ listing: SurplusListing) async throws

    /// Returns nil when no listing has the given ID.
    func surplusListing(id: UUID) async throws -> SurplusListing?

    func surplusListings(forFoodBusinessID foodBusinessID: UUID) async throws -> [SurplusListing]

    /// Returns listings with status .available and pickupWindowEnd later than the supplied date.
    /// Includes upcoming pickup windows so organisations can arrange collection in advance.
    func availableSurplusListings(at date: Date) async throws -> [SurplusListing]
}
