import Foundation

/// A completed collection of the food reserved by a rescue claim.
struct DonationPickup: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var rescueClaimID: UUID
    var collectedAt: Date
    var handoverNotes: String?
}
