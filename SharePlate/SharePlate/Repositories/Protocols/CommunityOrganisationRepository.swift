import Foundation

protocol CommunityOrganisationRepository {
    /// Creates or updates an organisation using its domain ID.
    func saveCommunityOrganisation(_ organisation: CommunityOrganisation) async throws

    /// Returns nil when no organisation has the given ID.
    func communityOrganisation(id: UUID) async throws -> CommunityOrganisation?
}
