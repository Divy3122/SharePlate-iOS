import Foundation

enum SharePlateProfileStore {
    private static let foodBusinessIDKey = "shareplate.profile.foodBusinessID"
    private static let communityOrganisationIDKey = "shareplate.profile.communityOrganisationID"

    static var foodBusinessID: UUID {
        stableIdentifier(forKey: foodBusinessIDKey)
    }

    static var communityOrganisationID: UUID {
        stableIdentifier(forKey: communityOrganisationIDKey)
    }

    private static func stableIdentifier(forKey key: String) -> UUID {
        let defaults = UserDefaults.standard
        if let storedValue = defaults.string(forKey: key),
           let identifier = UUID(uuidString: storedValue) {
            return identifier
        }

        let identifier = UUID()
        defaults.set(identifier.uuidString, forKey: key)
        return identifier
    }
}
