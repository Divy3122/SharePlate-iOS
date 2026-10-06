import Foundation

struct LoadDonationHistoryUseCase {
    private let donationRepository: any DonationRepository
    private let claimRepository: any RescueClaimRepository
    private let surplusRepository: any SurplusRepository

    init(
        donationRepository: any DonationRepository,
        claimRepository: any RescueClaimRepository,
        surplusRepository: any SurplusRepository
    ) {
        self.donationRepository = donationRepository
        self.claimRepository = claimRepository
        self.surplusRepository = surplusRepository
    }

    func loadDonationHistory(foodBusinessID: UUID) async throws -> [DonationHistoryEntry] {
        let pickups = try await donationRepository.donationPickups(
            forFoodBusinessID: foodBusinessID
        )

        var entries: [DonationHistoryEntry] = []
        for pickup in pickups {
            guard let claim = try await claimRepository.rescueClaim(id: pickup.rescueClaimID) else {
                throw LoadDonationHistoryError.rescueClaimMissing
            }
            guard let listing = try await surplusRepository.surplusListing(
                id: claim.surplusListingID
            ) else {
                throw LoadDonationHistoryError.surplusListingMissing
            }
            entries.append(
                DonationHistoryEntry(pickup: pickup, claim: claim, listing: listing)
            )
        }

        return entries.sorted { $0.pickup.collectedAt > $1.pickup.collectedAt }
    }
}

enum LoadDonationHistoryError: LocalizedError, Equatable {
    case rescueClaimMissing
    case surplusListingMissing

    var errorDescription: String? {
        switch self {
        case .rescueClaimMissing:
            return "A completed rescue is missing its claim details. Refresh your donation history and try again."
        case .surplusListingMissing:
            return "A completed rescue is missing its surplus details. Refresh your donation history and try again."
        }
    }
}
