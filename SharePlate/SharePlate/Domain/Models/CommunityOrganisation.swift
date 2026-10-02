import Foundation

/// A community organisation collecting food for redistribution.
struct CommunityOrganisation: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var organisationName: String
    var suburb: String
    var isVerified: Bool = false
    var contactName: String
    var contactPhone: String
    var contactEmail: String?
    var serviceArea: String
    var foodHandlingNotes: String?
}
