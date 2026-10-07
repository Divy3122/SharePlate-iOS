import Foundation

/// Collector-relevant details for one completed community rescue.
struct CommunityRescueHistoryEntry: Identifiable, Equatable {
    let id: UUID
    let listingTitle: String
    let collectedAt: Date
    let items: [SurplusItem]
    let pickupAddress: String
}
