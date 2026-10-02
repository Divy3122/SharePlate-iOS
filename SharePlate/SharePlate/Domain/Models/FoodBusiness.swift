import Foundation

/// A local business donating edible surplus food.
struct FoodBusiness: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var businessName: String
    var suburb: String
    var contactName: String
    var contactPhone: String
    var contactEmail: String?
    var pickupAddress: String
    var pickupInstructions: String?
}
