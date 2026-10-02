import Foundation

/// A quantity of one kind of food offered as part of a listing.
struct SurplusItem: Identifiable, Equatable, Codable {
    enum QuantityUnit: String, Equatable, Codable {
        case pieces
        case portions
        case packs
        case trays
        case kilograms
        case litres
    }

    enum StorageRequirement: String, Equatable, Codable {
        case ambient
        case refrigerated
        case frozen
    }

    var id: UUID = UUID()
    var foodName: String
    var foodDescription: String?
    var quantity: Decimal
    var quantityUnit: QuantityUnit
    var storageRequirement: StorageRequirement
    /// Nil means allergen information has not been supplied.
    var allergenInformation: String?
    var useByDate: Date?
}
