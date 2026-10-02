import Foundation

/// An organisation's reservation of all food in a surplus listing.
struct RescueClaim: Identifiable, Equatable, Codable {
    enum Status: String, Equatable, Codable {
        case active
        case collected
        case cancelled
    }

    var id: UUID = UUID()
    var surplusListingID: UUID
    var communityOrganisationID: UUID
    var claimedAt: Date
    var plannedPickupAt: Date
    var collectorName: String
    var collectorPhone: String
    var collectionNotes: String?
    var status: Status = .active
}
