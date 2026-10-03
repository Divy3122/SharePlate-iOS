import Foundation

protocol FoodBusinessRepository {
    /// Creates or updates a business using its domain ID.
    func saveFoodBusiness(_ business: FoodBusiness) async throws

    /// Returns nil when no business has the given ID.
    func foodBusiness(id: UUID) async throws -> FoodBusiness?
}
