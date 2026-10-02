import Foundation

/// A business's offer of food, collected together during a pickup window.
struct SurplusListing: Identifiable, Equatable, Codable {
    enum Status: String, Equatable, Codable {
        case estimated
        case available
        case claimed
        case collected
        case expired
        case cancelled
    }

    var id: UUID = UUID()
    var foodBusinessID: UUID
    var title: String
    var items: [SurplusItem]
    var pickupAddress: String
    var pickupInstructions: String?
    var pickupWindowStart: Date
    var pickupWindowEnd: Date
    var createdAt: Date
    var finalisedAt: Date?
    var status: Status = .estimated
}
