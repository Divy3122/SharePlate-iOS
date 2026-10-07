import Foundation

/// An active community collection with the surplus details needed to coordinate pickup.
struct CommunityPickupActivity: Identifiable, Equatable {
    let listing: SurplusListing
    let claim: RescueClaim

    var id: UUID { claim.id }
}
