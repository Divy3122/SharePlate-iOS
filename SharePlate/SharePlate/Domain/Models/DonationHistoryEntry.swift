import Foundation

/// A completed food rescue with the related claim and surplus details needed for history.
struct DonationHistoryEntry: Identifiable, Equatable, Codable {
    var id: UUID { pickup.id }
    let pickup: DonationPickup
    let claim: RescueClaim
    let listing: SurplusListing
}
