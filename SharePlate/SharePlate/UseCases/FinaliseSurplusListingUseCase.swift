import Foundation

struct FinaliseSurplusListingUseCase {

    private let surplusRepository: any SurplusRepository
    private let currentDate: () -> Date

    init(
        surplusRepository: any SurplusRepository,
        currentDate: @escaping () -> Date = { Date() }
    ) {
        self.surplusRepository = surplusRepository
        self.currentDate = currentDate
    }

    func finaliseSurplusListing(
        id: UUID,
        pickupAddress: String? = nil
    ) async throws -> SurplusListing {

        guard var listing = try await surplusRepository
            .surplusListing(id: id)
        else {
            throw FinaliseSurplusListingError.listingNotFound
        }

        guard listing.status == .estimated else {
            throw FinaliseSurplusListingError.listingIsNotEstimated
        }

        guard !listing.items.isEmpty else {
            throw FinaliseSurplusListingError.noSurplusItems
        }

        for item in listing.items {
            guard !item.quantity.isNaN,
                  item.quantity > 0
            else {
                throw FinaliseSurplusListingError
                    .nonPositiveQuantity(
                        foodName: item.foodName
                    )
            }
        }

        let cleanAddress =
            (pickupAddress ?? listing.pickupAddress)
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanAddress.isEmpty else {
            throw FinaliseSurplusListingError
                .pickupAddressRequired
        }

        guard listing.pickupWindowStart <
                listing.pickupWindowEnd
        else {
            throw FinaliseSurplusListingError
                .invalidPickupWindow
        }

        let now = currentDate()

        guard listing.pickupWindowEnd > now else {
            throw FinaliseSurplusListingError
                .pickupWindowEnded
        }

        listing.pickupAddress = cleanAddress
        listing.finalisedAt = now
        listing.status = .available

        try await surplusRepository
            .saveSurplusListing(listing)

        return listing
    }
}

enum FinaliseSurplusListingError:
    LocalizedError,
    Equatable {

    case listingNotFound
    case listingIsNotEstimated
    case noSurplusItems
    case nonPositiveQuantity(foodName: String)
    case pickupAddressRequired
    case invalidPickupWindow
    case pickupWindowEnded

    var errorDescription: String? {
        switch self {

        case .listingNotFound:
            return """
            This surplus listing could not be found. \
            Refresh your listings and try again.
            """

        case .listingIsNotEstimated:
            return """
            Only an estimated surplus listing can be finalised.
            """

        case .noSurplusItems:
            return """
            Add at least one food item before finalising this surplus.
            """

        case .nonPositiveQuantity(let foodName):
            return """
            Enter a quantity greater than zero for \(foodName).
            """

        case .pickupAddressRequired:
            return """
            Choose a pickup address before making this surplus available.
            """

        case .invalidPickupWindow:
            return """
            The pickup window must start before it ends.
            """

        case .pickupWindowEnded:
            return """
            The pickup window has ended. \
            Set a future end time before finalising.
            """
        }
    }
}
